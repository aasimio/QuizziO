import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../injection.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/repositories/quiz_repository.dart';
import '../../domain/entities/answer_status.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_repository.dart';
import '../utils/score_utils.dart';

/// Arguments for ScanResultDetailPage navigation.
///
/// Can be initialized with either a full ScanResult (from scanning flow)
/// or just IDs (from graded papers list) for lazy loading.
class ScanResultDetailArgs {
  final ScanResult? scanResult;
  final String? scanResultId;
  final String? quizId;
  final Quiz? quiz;

  const ScanResultDetailArgs({
    this.scanResult,
    this.scanResultId,
    this.quizId,
    this.quiz,
  }) : assert(
          scanResult != null || (scanResultId != null && quizId != null),
          'Either scanResult or both scanResultId and quizId must be provided',
        );

  String get id => scanResult?.id ?? scanResultId!;

  Map<String, String> get answerKey => quiz?.answerKey ?? const {};
}

/// Screen: Scan Result Detail Page
///
/// Displays detailed view of a single scan result including
/// name region, score breakdown, and question-by-question results.
/// Allows manual correction of detected answers.
class ScanResultDetailPage extends StatefulWidget {
  final ScanResultDetailArgs? args;

  const ScanResultDetailPage({super.key, this.args});

  @override
  State<ScanResultDetailPage> createState() => _ScanResultDetailPageState();
}

class _ScanResultDetailPageState extends State<ScanResultDetailPage> {
  // Nullable fields - no late initialization hazards
  ScanResult? _currentResult;
  Map<String, String?> _corrections = {};
  Map<String, String> _answerKey = {};

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Repositories resolved in initState (allowed per CLAUDE.md)
  late final ScanRepository _scanRepository;
  late final QuizRepository _quizRepository;

  @override
  void initState() {
    super.initState();
    _scanRepository = getIt<ScanRepository>();
    _quizRepository = getIt<QuizRepository>();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final args = widget.args;
    if (args == null) return;

    // Optimization: if full ScanResult provided, use it directly (no fetch)
    final scanResult = args.scanResult;
    if (scanResult != null) {
      _currentResult = scanResult;
      _corrections = Map<String, String?>.from(scanResult.correctedAnswers);
      _answerKey = args.answerKey;
      if (_answerKey.isEmpty) {
        await _loadQuizForResult(scanResult.quizId);
      }
      // No setState needed - build will use these values
      return;
    }

    // Lazy loading path: fetch from repositories
    final scanResultId = args.scanResultId;
    final quizId = args.quizId;
    if (scanResultId == null || quizId == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Missing scan result identifiers';
      });
      return;
    }
    await _loadFromRepositories(scanResultId, quizId);
  }

  Future<void> _loadQuizForResult(String quizId) async {
    try {
      final quiz = await _quizRepository.getById(quizId);
      if (!mounted) return;
      setState(() {
        _answerKey = quiz?.answerKey ?? {};
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to load quiz for result: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _answerKey = {};
      });
    }
  }

  Future<void> _loadFromRepositories(String scanResultId, String quizId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch scan result and quiz in parallel
      final (scanResult, quiz) = await (
        _scanRepository.getById(scanResultId),
        _quizRepository.getById(quizId),
      ).wait;

      if (!mounted) return;

      if (scanResult == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Scan result not found';
        });
        return;
      }

      setState(() {
        _currentResult = scanResult;
        _corrections = Map<String, String?>.from(scanResult.correctedAnswers);
        _answerKey = quiz?.answerKey ?? {};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load scan result: ${e.toString()}';
      });
    }
  }

  void _retry() {
    final args = widget.args;
    if (args?.scanResultId != null && args?.quizId != null) {
      _loadFromRepositories(args!.scanResultId!, args.quizId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Error: no args provided
    if (widget.args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Missing scan result arguments')),
      );
    }

    // Loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Scan Details',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error state with retry
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Scan Details',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Data not yet loaded (shouldn't happen but guard against it)
    final scanResult = _currentResult;
    if (scanResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Scan Details',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Main content - data is loaded
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldSave = await _showUnsavedChangesDialog();
        if (!mounted) return;
        if (shouldSave == true) {
          _saveAndPop();
        } else if (shouldSave == false) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Scan Details',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_hasUnsavedChanges)
              TextButton.icon(
                onPressed: _saveAndPop,
                icon: const Icon(Icons.save_outlined, size: 20),
                label: Text(
                  'Save',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share result',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Share feature coming soon!',
                      style: GoogleFonts.dmSans(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: _ScanResultContent(
          scanResult: scanResult,
          answerKey: _answerKey,
          corrections: _corrections,
          onAnswerEdited: _handleAnswerEdit,
        ),
      ),
    );
  }

  void _handleAnswerEdit(String questionId, String? newAnswer) {
    final current = _currentResult;
    if (current == null) return;

    setState(() {
      _corrections[questionId] = newAnswer;
      _hasUnsavedChanges = true;

      // Update the current result for display
      _currentResult = current.copyWith(
        correctedAnswers: Map<String, String?>.from(_corrections),
      );
    });
  }

  void _saveAndPop() {
    final current = _currentResult;
    if (current == null) return;

    // Return updated result to parent for persistence
    final updatedResult = current.copyWith(
      correctedAnswers: _corrections,
      wasEdited: current.wasEdited || _corrections.isNotEmpty,
    );
    Navigator.of(context).pop(updatedResult);
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You have unsaved answer corrections. Would you like to save them?',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Discard',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Save',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResultContent extends StatelessWidget {
  final ScanResult scanResult;
  final Map<String, String> answerKey;
  final Map<String, String?> corrections;
  final void Function(String questionId, String? newAnswer) onAnswerEdited;

  const _ScanResultContent({
    required this.scanResult,
    required this.answerKey,
    required this.corrections,
    required this.onAnswerEdited,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get sorted question IDs
    final questionIds = (answerKey.isNotEmpty
            ? answerKey.keys
            : <String>{
                ...scanResult.detectedAnswers.keys,
                ...corrections.keys,
              })
        .toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return aNum.compareTo(bNum);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Name region image card
        if (scanResult.nameRegionImage.isNotEmpty) ...[
          _NameRegionCard(imageData: scanResult.nameRegionImage),
          const SizedBox(height: 16),
        ],

        // Score summary card
        _ScoreSummaryCard(scanResult: scanResult),
        const SizedBox(height: 24),

        // Answer breakdown header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'Answer Breakdown',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${questionIds.length} questions',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Column headers
        _ColumnHeaders(),
        const SizedBox(height: 8),

        // Question rows with staggered animation
        ...questionIds.asMap().entries.map((entry) {
          final index = entry.key;
          final questionId = entry.value;
          final questionNumber = index + 1;

          return TweenAnimationBuilder<double>(
            key: ValueKey(questionId),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 30).clamp(0, 300)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AnswerRow(
                questionNumber: questionNumber,
                questionId: questionId,
                detectedStatus: scanResult.getAnswerStatus(questionId),
                correctAnswer: answerKey[questionId],
                correction: corrections[questionId],
                onEdit: () => _showEditDialog(
                  context,
                  questionNumber,
                  questionId,
                  scanResult.getAnswerStatus(questionId),
                  corrections[questionId],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    int questionNumber,
    String questionId,
    AnswerStatus? currentStatus,
    String? currentCorrection,
  ) {
    // Determine current effective answer
    String? currentValue;
    bool isBlank = false;
    bool isMultipleMark = false;

    if (currentCorrection != null) {
      if (currentCorrection == 'MULTIPLE_MARK') {
        isMultipleMark = true;
      } else {
        currentValue = currentCorrection;
      }
    } else if (currentStatus != null) {
      if (currentStatus.isBlank) {
        isBlank = true;
      } else if (currentStatus.isMultipleMark) {
        isMultipleMark = true;
      } else {
        currentValue = currentStatus.value;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditAnswerSheet(
        questionNumber: questionNumber,
        currentValue: currentValue,
        isBlank: isBlank,
        isMultipleMark: isMultipleMark,
        onSave: (newAnswer) {
          onAnswerEdited(questionId, newAnswer);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

class _NameRegionCard extends StatelessWidget {
  final Uint8List imageData;

  const _NameRegionCard({required this.imageData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Student Name / ID',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 60,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageData.isNotEmpty
                    ? Image.memory(
                        imageData,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _ImagePlaceholder();
                        },
                      )
                    : _ImagePlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'No image available',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreSummaryCard extends StatelessWidget {
  final ScanResult scanResult;

  const _ScoreSummaryCard({required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${scanResult.score}/${scanResult.total}',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: getScoreColor(scanResult.percentage),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(scanResult.percentage * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  label: '${scanResult.blankCount} blank',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '${scanResult.multipleMarkCount} multiple',
                  color: AppColors.errorAlt,
                ),
              ],
            ),
            if (scanResult.wasEdited) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Manually edited',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerStyle = GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('#', style: headerStyle),
          ),
          Expanded(
            child: Text('Detected', style: headerStyle),
          ),
          Expanded(
            child: Text('Correct', style: headerStyle),
          ),
          SizedBox(
            width: 48,
            child: Center(child: Text('Status', style: headerStyle)),
          ),
          const SizedBox(width: 40), // Edit button space
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final int questionNumber;
  final String questionId;
  final AnswerStatus? detectedStatus;
  final String? correctAnswer;
  final String? correction;
  final VoidCallback onEdit;

  const _AnswerRow({
    required this.questionNumber,
    required this.questionId,
    required this.detectedStatus,
    required this.correctAnswer,
    required this.correction,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine effective answer (correction takes precedence)
    String displayAnswer;
    bool isBlank = false;
    bool isMultipleMark = false;
    bool hasCorrection = correction != null;

    if (correction != null) {
      if (correction == 'MULTIPLE_MARK') {
        displayAnswer = 'Multi';
        isMultipleMark = true;
      } else {
        displayAnswer = correction!;
      }
    } else if (detectedStatus != null) {
      if (detectedStatus!.isBlank) {
        displayAnswer = '—';
        isBlank = true;
      } else if (detectedStatus!.isMultipleMark) {
        displayAnswer = 'Multi';
        isMultipleMark = true;
      } else {
        displayAnswer = detectedStatus!.value ?? '?';
      }
    } else {
      displayAnswer = '?';
    }

    // Determine if answer is correct
    final effectiveAnswer = correction ?? detectedStatus?.value;
    final hasAnswerKey = correctAnswer != null;
    final isCorrect = hasAnswerKey &&
        effectiveAnswer != null &&
        effectiveAnswer == correctAnswer;
    final isIncorrect = hasAnswerKey &&
        !isBlank &&
        !isMultipleMark &&
        effectiveAnswer != null &&
        effectiveAnswer != correctAnswer;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Question number
              SizedBox(
                width: 36,
                child: Text(
                  '$questionNumber.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              // Detected answer
              Expanded(
                child: Row(
                  children: [
                    _AnswerChip(
                      answer: displayAnswer,
                      isBlank: isBlank,
                      isMultipleMark: isMultipleMark,
                      hasCorrection: hasCorrection,
                    ),
                    if (hasCorrection) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: Colors.blue.shade600,
                      ),
                    ],
                  ],
                ),
              ),

              // Correct answer
              Expanded(
                child: Text(
                  correctAnswer ?? '—',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              // Status icon
              SizedBox(
                width: 48,
                child: Center(
                  child: _StatusIcon(
                    isCorrect: isCorrect,
                    isIncorrect: isIncorrect,
                    isBlank: isBlank && correction == null,
                    isMultipleMark: isMultipleMark && correction == null,
                  ),
                ),
              ),

              // Edit button
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Edit answer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final String answer;
  final bool isBlank;
  final bool isMultipleMark;
  final bool hasCorrection;

  const _AnswerChip({
    required this.answer,
    required this.isBlank,
    required this.isMultipleMark,
    required this.hasCorrection,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;

    if (isBlank) {
      bgColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    } else if (isMultipleMark) {
      bgColor = AppColors.warning.withValues(alpha: 0.15);
      textColor = AppColors.warning;
    } else if (hasCorrection) {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue.shade700;
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        answer,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool isCorrect;
  final bool isIncorrect;
  final bool isBlank;
  final bool isMultipleMark;

  const _StatusIcon({
    required this.isCorrect,
    required this.isIncorrect,
    required this.isBlank,
    required this.isMultipleMark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isCorrect) {
      return Icon(
        Icons.check_circle,
        size: 22,
        color: AppColors.success,
      );
    } else if (isIncorrect) {
      return Icon(
        Icons.cancel,
        size: 22,
        color: AppColors.errorAlt,
      );
    } else if (isBlank) {
      return Icon(
        Icons.radio_button_unchecked,
        size: 22,
        color: colorScheme.onSurfaceVariant,
      );
    } else if (isMultipleMark) {
      return Icon(
        Icons.warning_amber,
        size: 22,
        color: AppColors.warning,
      );
    } else {
      return Icon(
        Icons.help_outline,
        size: 22,
        color: colorScheme.onSurfaceVariant,
      );
    }
  }
}

class _EditAnswerSheet extends StatefulWidget {
  final int questionNumber;
  final String? currentValue;
  final bool isBlank;
  final bool isMultipleMark;
  final void Function(String? answer) onSave;
  final VoidCallback onCancel;

  const _EditAnswerSheet({
    required this.questionNumber,
    required this.currentValue,
    required this.isBlank,
    required this.isMultipleMark,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EditAnswerSheet> createState() => _EditAnswerSheetState();
}

class _EditAnswerSheetState extends State<_EditAnswerSheet> {
  late String? _selectedValue;
  late bool _isBlank;
  late bool _isMultipleMark;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
    _isBlank = widget.isBlank;
    _isMultipleMark = widget.isMultipleMark;
  }

  void _selectAnswer(String answer) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedValue = answer;
      _isBlank = false;
      _isMultipleMark = false;
    });
  }

  void _selectBlank() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedValue = null;
      _isBlank = true;
      _isMultipleMark = false;
    });
  }

  void _selectMultipleMark() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedValue = null;
      _isBlank = false;
      _isMultipleMark = true;
    });
  }

  void _save() {
    String? result;
    if (_isBlank) {
      result = null;
    } else if (_isMultipleMark) {
      result = 'MULTIPLE_MARK';
    } else {
      result = _selectedValue;
    }
    widget.onSave(result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final answers = ['A', 'B', 'C', 'D', 'E'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Edit Answer for Question ${widget.questionNumber}',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the correct answer or mark as blank/multiple',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Answer options
            Text(
              'Answer',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: answers.map((answer) {
                final isSelected =
                    _selectedValue == answer && !_isBlank && !_isMultipleMark;
                return _OptionChip(
                  label: answer,
                  isSelected: isSelected,
                  onTap: () => _selectAnswer(answer),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Special options
            Text(
              'Special Status',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SpecialOptionChip(
                    label: 'Blank',
                    icon: Icons.radio_button_unchecked,
                    isSelected: _isBlank,
                    color: colorScheme.onSurfaceVariant,
                    onTap: _selectBlank,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SpecialOptionChip(
                    label: 'Multiple',
                    icon: Icons.warning_amber,
                    isSelected: _isMultipleMark,
                    color: AppColors.warning,
                    onTap: _selectMultipleMark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 56,
            minHeight: 56,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SpecialOptionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

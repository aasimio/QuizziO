import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection.dart';
import '../../domain/entities/quiz.dart';
import '../cubit/answer_key_cubit.dart';
import '../cubit/answer_key_state.dart';
import '../widgets/answer_key_row.dart';

class EditAnswerKeyArgs {
  final Quiz quiz;

  const EditAnswerKeyArgs({required this.quiz});
}

class EditAnswerKeyPage extends StatefulWidget {
  final EditAnswerKeyArgs? args;

  const EditAnswerKeyPage({super.key, this.args});

  @override
  State<EditAnswerKeyPage> createState() => _EditAnswerKeyPageState();
}

class _EditAnswerKeyPageState extends State<EditAnswerKeyPage> {
  AnswerKeyCubit? _cubit;

  @override
  void initState() {
    super.initState();
    if (widget.args != null) {
      _cubit = getIt<AnswerKeyCubit>()..load(widget.args!.quiz.id);
    }
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.args == null || _cubit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Missing quiz arguments'),
        ),
      );
    }

    return BlocProvider<AnswerKeyCubit>.value(
      value: _cubit!,
      child: _EditAnswerKeyContent(quiz: widget.args!.quiz),
    );
  }
}

class _EditAnswerKeyContent extends StatefulWidget {
  final Quiz quiz;

  const _EditAnswerKeyContent({required this.quiz});

  @override
  State<_EditAnswerKeyContent> createState() => _EditAnswerKeyContentState();
}

class _EditAnswerKeyContentState extends State<_EditAnswerKeyContent> {
  bool _showSavedSnackBar = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AnswerKeyCubit, AnswerKeyState>(
      listenWhen: (previous, current) {
        return previous.isSaving && !current.isSaving && current.error == null;
      },
      listener: (context, state) {
        if (!_showSavedSnackBar) {
          _showSavedSnackBar = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Answer key saved',
                style: GoogleFonts.dmSans(),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showSavedSnackBar = false;
              });
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Answer Key',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (state.isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, state, colorScheme),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnswerKeyState state,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.quiz == null) {
      return Center(
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
                state.error!,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  context.read<AnswerKeyCubit>().load(widget.quiz.id);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.questionCount == 0) {
      return Center(
        child: Text(
          'No questions found for this template',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            widget.quiz.name,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            '${state.questionCount} questions',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: state.questionLabels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final questionId = state.questionLabels[index];
              final questionNumber = index + 1;
              final selectedOption = state.answers[questionId];

              return AnswerKeyRow(
                questionNumber: questionNumber,
                questionId: questionId,
                selectedOption: selectedOption,
                options: state.options,
                onOptionSelected: (option) {
                  context
                      .read<AnswerKeyCubit>()
                      .selectAnswer(questionId, option);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

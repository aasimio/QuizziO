import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/quiz.dart';

/// A dialog for creating or editing a quiz.
///
/// Pass [quiz] as null for create mode, or provide an existing quiz for edit mode.
class QuizDialog extends StatefulWidget {
  const QuizDialog({
    super.key,
    this.quiz,
  });

  /// The quiz to edit. If null, the dialog operates in create mode.
  final Quiz? quiz;

  /// Shows the dialog and returns the result.
  ///
  /// Returns a tuple of (name, templateId) for create mode,
  /// or the updated [Quiz] for edit mode, or null if cancelled.
  static Future<Object?> show(BuildContext context, {Quiz? quiz}) {
    return showDialog<Object>(
      context: context,
      builder: (_) => QuizDialog(quiz: quiz),
    );
  }

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedTemplateId;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.quiz != null;

  static const _templates = [
    ('std_10q', '10 Questions'),
    ('std_20q', '20 Questions'),
    ('std_50q', '50 Questions'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.quiz?.name ?? '');
    _selectedTemplateId = widget.quiz?.templateId ?? _templates.first.$1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();

    if (_isEditMode) {
      // Return updated quiz
      final updatedQuiz = widget.quiz!.copyWith(
        name: name,
        templateId: _selectedTemplateId,
      );
      Navigator.of(context).pop(updatedQuiz);
    } else {
      // Return tuple for create
      Navigator.of(context).pop((name, _selectedTemplateId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        _isEditMode ? 'Edit Quiz' : 'Create Quiz',
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditMode,
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Quiz Name',
                  hintText: 'e.g., Math Chapter 5',
                  labelStyle: GoogleFonts.dmSans(),
                  hintStyle: GoogleFonts.dmSans(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.edit_note),
                  counterText: '',
                ),
                style: GoogleFonts.dmSans(fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a quiz name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Template dropdown
              DropdownButtonFormField<String>(
                value: _selectedTemplateId,
                decoration: InputDecoration(
                  labelText: 'Template',
                  labelStyle: GoogleFonts.dmSans(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.article_outlined),
                ),
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
                items: _templates.map((template) {
                  return DropdownMenuItem<String>(
                    value: template.$1,
                    child: Text(template.$2),
                  );
                }).toList(),
                onChanged: _isEditMode
                    ? null // Disable template change in edit mode
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedTemplateId = value);
                        }
                      },
                hint: Text(
                  'Select template',
                  style: GoogleFonts.dmSans(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Template cannot be changed after creation',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _isEditMode ? 'Save' : 'Create',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

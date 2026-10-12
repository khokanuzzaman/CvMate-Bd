import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/placeholder_text.dart';
import 'package:flutter/material.dart';

/// The letter as a sheet of paper: read-only text with an Edit pill, or — while
/// editing — the subject (if any) and body as plain text fields.
class CoverLetterPaper extends StatelessWidget {
  const CoverLetterPaper({
    super.key,
    required this.content,
    required this.subject,
    required this.showSubject,
    required this.isGenerating,
    required this.editing,
    required this.onToggleEdit,
    required this.contentController,
    required this.subjectController,
  });

  final String content;
  final String subject;
  final bool showSubject;
  final bool isGenerating;
  final bool editing;
  final VoidCallback onToggleEdit;
  final TextEditingController contentController;
  final TextEditingController subjectController;

  static TextStyle get _letterStyle => AppTextStyles.body.copyWith(
    fontSize: 15,
    height: 1.55,
    color: AppColors.inkSoft,
  );

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return const AppCard(
        shadow: true,
        padding: EdgeInsets.all(AppSpacing.s22),
        child: SizedBox(
          height: 240,
          child: CustomLoadingView(message: AppStrings.coverLetterGenerating),
        ),
      );
    }

    return AppCard(
      shadow: true,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: editing ? _buildEditing() : _buildReading(),
    );
  }

  Widget _buildReading() {
    // The first line (usually the greeting) sits beside the Edit pill, as in
    // the design; the rest flows below.
    final newline = content.indexOf('\n');
    final first = newline < 0 ? content : content.substring(0, newline);
    final rest = newline < 0 ? '' : content.substring(newline + 1).trimLeft();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSubject && subject.trim().isNotEmpty) ...[
          Text(
            '${AppStrings.coverLetterSubject}: ${subject.trim()}',
            style: _letterStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s10),
                child: PlaceholderText(first, style: _letterStyle),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            _EditPill(editing: false, onTap: onToggleEdit),
          ],
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s14),
          PlaceholderText(rest, style: _letterStyle),
        ],
      ],
    );
  }

  Widget _buildEditing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _EditPill(editing: true, onTap: onToggleEdit),
        ),
        if (showSubject) ...[
          const SizedBox(height: AppSpacing.s8),
          AppTextField(
            controller: subjectController,
            label: AppStrings.coverLetterSubjectLabel,
            hintText: AppStrings.coverLetterSubjectHint,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        AppTextArea(controller: contentController, minLines: 12, maxLines: 40),
      ],
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.editing, required this.onTap});

  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = editing
        ? AppStrings.coverLetterDoneEditing
        : AppStrings.coverLetterEdit;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s14,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadii.pillRadius,
                border: Border.all(color: AppColors.lineStrong),
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      editing ? Icons.check_rounded : Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.s6),
                    Text(
                      label,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

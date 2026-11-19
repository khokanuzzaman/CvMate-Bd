import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/shared/services/ai/ai_result_text.dart';
import 'package:careermatebd/shared/services/ai/pending_ai_result_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lays the "Your last result is ready" card over [child] when an AI answer
/// was recovered after the app had been closed mid-request.
class PendingAiResultOverlay extends ConsumerWidget {
  const PendingAiResultOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(pendingAiResultProvider).asData?.value;
    final content = ready?.response?['content'];
    if (ready == null || content == null) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ColoredBox(color: AppColors.ink.withValues(alpha: 0.35)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: PendingAiResultCard(
                actionLabel: AiResultText.actionLabel(ready.action),
                text: AiResultText.fromContent(content),
                onClose: () =>
                    ref.read(pendingAiResultProvider.notifier).dismiss(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PendingAiResultCard extends StatefulWidget {
  const PendingAiResultCard({
    super.key,
    required this.actionLabel,
    required this.text,
    required this.onClose,
  });

  final String actionLabel;
  final String text;
  final VoidCallback onClose;

  @override
  State<PendingAiResultCard> createState() => _PendingAiResultCardState();
}

class _PendingAiResultCardState extends State<PendingAiResultCard> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (mounted) {
      setState(() => _copied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.cardRadius,
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.pendingAiReadyTitle, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.s4),
              Text(
                '${widget.actionLabel} · ${AppStrings.pendingAiReadyBody}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.s12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(widget.text, style: AppTextStyles.body),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: _copied
                          ? AppStrings.pendingAiCopied
                          : AppStrings.pendingAiCopy,
                      leadingIcon: Icons.copy_rounded,
                      onPressed: _copy,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: PrimaryButton(
                      label: AppStrings.pendingAiClose,
                      onPressed: widget.onClose,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/features/feedback/data/feedback_repository.dart';
import 'package:careermatebd/features/feedback/presentation/controllers/feedback_controller.dart';
import 'package:careermatebd/shared/services/analytics/analytics_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings > Report a problem / Send feedback.
class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  static String categoryLabel(FeedbackCategory category) => switch (category) {
    FeedbackCategory.bug => AppStrings.feedbackCategoryBug,
    FeedbackCategory.aiResult => AppStrings.feedbackCategoryAi,
    FeedbackCategory.payment => AppStrings.feedbackCategoryPayment,
    FeedbackCategory.other => AppStrings.feedbackCategoryOther,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackControllerProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.feedbackTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: state.phase == FeedbackPhase.sent
                  ? const _Thanks()
                  : _Form(state: state),
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({required this.state});

  final FeedbackState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(feedbackControllerProvider.notifier);
    final canReply = ref.watch(feedbackCanReplyProvider);
    final textTheme = Theme.of(context).textTheme;
    final sending = state.phase == FeedbackPhase.sending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.feedbackIntro, style: textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text(AppStrings.feedbackCategoryLabel, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in FeedbackCategory.values)
              ChoiceChip(
                label: Text(FeedbackScreen.categoryLabel(category)),
                selected: state.category == category,
                onSelected: sending
                    ? null
                    : (_) => controller.selectCategory(category),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          enabled: !sending,
          minLines: 5,
          maxLines: 10,
          maxLength: feedbackMaxLength,
          textCapitalization: TextCapitalization.sentences,
          onChanged: controller.updateMessage,
          decoration: const InputDecoration(
            labelText: AppStrings.feedbackMessageLabel,
            hintText: AppStrings.feedbackMessageHint,
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: state.attachDiagnostics,
          onChanged: sending
              ? null
              : (value) => controller.setAttachDiagnostics(value ?? false),
          title: const Text(AppStrings.feedbackAttachDiagnostics),
          subtitle: const Text(AppStrings.feedbackAttachDiagnosticsNote),
        ),
        if (canReply)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: state.allowReply,
            onChanged: sending
                ? null
                : (value) => controller.setAllowReply(value ?? false),
            title: const Text(AppStrings.feedbackAllowReply),
          ),
        if (state.errorMessage case final error?) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: sending ? AppStrings.feedbackSending : AppStrings.feedbackSend,
          onPressed: state.canSend ? controller.send : null,
        ),
      ],
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.favorite_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.feedbackThanksTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.feedbackThanksBody,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: AppStrings.feedbackDone,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.settingsPath),
        ),
      ],
    );
  }
}

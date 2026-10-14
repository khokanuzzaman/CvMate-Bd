import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/builder_pages.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_flow.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_refresh.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_state.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_footer.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_progress_header.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/builder_section_chips.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/custom_section_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/education_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/experience_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/languages_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/personal_info_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/projects_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/skills_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/summary_objective_step.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/training_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hosts the CV builder pages. The controller still owns the current step,
/// validation and saving; this screen maps its steps onto the design's pages
/// (see [CvBuilderFlow]) and navigates with `goToStep` / `validateStep`.
class CvBuilderScreen extends ConsumerStatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  ConsumerState<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends ConsumerState<CvBuilderScreen>
    with WidgetsBindingObserver {
  bool _allowPop = false;
  bool _showValidationErrors = false;

  // Kept so the draft can still be flushed from dispose().
  late final CvBuilderController _builder;

  @override
  void initState() {
    super.initState();
    _builder = ref.read(cvBuilderControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_builder.ensureDraftReady);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the builder by any route (not only the back button) must not lose
    // edits that are still waiting on the autosave timer. Deferred: Riverpod
    // forbids changing provider state while the widget tree is being torn down.
    final builder = _builder;
    scheduleMicrotask(builder.flushAutosave);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app may be killed while in the background: save now.
    if (state != AppLifecycleState.resumed) {
      unawaited(_builder.flushAutosave());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvBuilderControllerProvider);
    final refreshEpoch = ref.watch(cvBuilderRefreshProvider);
    final pages = CvBuilderPages.forProfile(state.draft);
    final page = CvBuilderPages.current(state);

    // Surface autosave failures (the status card that used to show them is
    // gone from the design).
    ref.listen<String?>(
      cvBuilderControllerProvider.select((value) => value.errorMessage),
      (previous, next) {
        if (next != null && next != previous) {
          _showMessage(next);
        }
      },
    );

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop) {
          return;
        }

        await ref.read(cvBuilderControllerProvider.notifier).flushAutosave();
        if (!context.mounted) {
          return;
        }

        final nextState = ref.read(cvBuilderControllerProvider);
        if (nextState.errorMessage != null) {
          _showMessage(nextState.errorMessage!);
          return;
        }

        setState(() => _allowPop = true);
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        body: SafeArea(
          // The footer lives in `bottomNavigationBar`, so validation snackbars
          // are laid out above Back / Continue instead of covering them.
          bottom: false,
          child: _buildBody(state, pages, page, refreshEpoch),
        ),
        bottomNavigationBar: state.hasActiveDraft
            ? SafeArea(
                // A min-size Column: the slot's loose constraints would
                // otherwise stretch the buttons to the full screen height.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BuilderFooter(
                      primaryLabel: CvBuilderPages.isLast(pages, page)
                          ? AppStrings.builderPreviewCv
                          : AppStrings.builderContinue,
                      onBack: () => _back(pages, page),
                      onPrimary: () => _continue(pages, page),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(
    CvBuilderState state,
    List<BuilderPageRef> pages,
    BuilderPageRef page,
    int refreshEpoch,
  ) {
    if (state.isLoading && !state.hasActiveDraft) {
      return const CustomLoadingView(message: AppStrings.builderPreparing);
    }

    if (!state.hasActiveDraft) {
      return CustomErrorView(
        title: AppStrings.builderNoDraftTitle,
        message: state.errorMessage ?? AppStrings.builderNoDraftBody,
        onRetry: ref
            .read(cvBuilderControllerProvider.notifier)
            .ensureDraftReady,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.s12,
            AppSpacing.screen,
            AppSpacing.s4,
          ),
          child: AppTopBar(
            title: state.draft.displayTitle,
            onBack: () => Navigator.of(context).maybePop(),
            extraActions: [
              AppTopBarAction(
                icon: Icons.public_rounded,
                tooltip: AppStrings.styleTooltip,
                onTap: () => context.push(RouteNames.cvStylePath),
              ),
              AppTopBarAction(
                icon: Icons.view_list_outlined,
                tooltip: AppStrings.sectionsTooltip,
                onTap: _openSections,
              ),
            ],
            trailingIcon: Icons.visibility_outlined,
            onTrailingTap: state.isLoading ? null : _openPreview,
          ),
        ),
        BuilderSectionChips(
          profile: state.draft,
          pages: pages,
          current: page,
          onSelected: _goToPage,
        ),
        const SizedBox(height: AppSpacing.s4),
        BuilderProgressHeader(profile: state.draft, pages: pages, page: page),
        const SizedBox(height: AppSpacing.s12),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey(
              '${state.draft.id}_${page.page?.name ?? page.customId}_$refreshEpoch',
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s4,
              AppSpacing.screen,
              AppSpacing.s16,
            ),
            child: _pageWidget(page),
          ),
        ),
      ],
    );
  }

  Widget _pageWidget(BuilderPageRef ref) {
    final customId = ref.customId;
    if (customId != null) {
      return CustomSectionStep(sectionId: customId);
    }
    return switch (ref.page!) {
      CvBuilderPage.personal => PersonalInfoStep(
        showValidationErrors: _showValidationErrors,
      ),
      CvBuilderPage.education => const EducationStep(),
      CvBuilderPage.experience => const ExperienceStep(),
      CvBuilderPage.skills => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkillsStep(),
          SizedBox(height: AppSpacing.s22),
          LanguagesStep(),
        ],
      ),
      CvBuilderPage.projects => const ProjectsStep(),
      CvBuilderPage.training => const TrainingStep(),
      CvBuilderPage.summary => SummaryObjectiveStep(
        showValidationErrors: _showValidationErrors,
      ),
    };
  }

  void _goToPage(BuilderPageRef page) {
    // Save whatever was edited on the page being left (no-op if nothing is
    // pending) instead of waiting for the autosave timer.
    unawaited(_builder.flushAutosave());
    setState(() => _showValidationErrors = false);
    final customId = page.customId;
    if (customId != null) {
      _builder.goToCustomSection(customId);
    } else {
      _builder.goToStep(page.page!.entryStep.index);
    }
  }

  void _back(List<BuilderPageRef> pages, BuilderPageRef page) {
    final previous = CvBuilderPages.previous(pages, page);
    if (previous == null) {
      Navigator.of(context).maybePop();
      return;
    }
    _goToPage(previous);
  }

  Future<void> _continue(
    List<BuilderPageRef> pages,
    BuilderPageRef page,
  ) async {
    final notifier = ref.read(cvBuilderControllerProvider.notifier);
    final customId = page.customId;
    final error = customId != null
        ? notifier.validateCustomSection(customId)
        : CvBuilderFlow.firstError(page.page!, notifier.validateStep);

    if (error != null) {
      setState(() => _showValidationErrors = true);
      _showMessage(error);
      return;
    }

    final next = CvBuilderPages.next(pages, page);
    if (next == null) {
      await _openPreview();
      return;
    }
    _goToPage(next);
  }

  Future<void> _openSections() async {
    await _builder.flushAutosave();
    if (!mounted) {
      return;
    }
    context.push('${RouteNames.cvSectionsPath}?from=builder');
  }

  Future<void> _openPreview() async {
    await ref.read(cvBuilderControllerProvider.notifier).saveNow();
    if (!mounted) {
      return;
    }

    final error = ref.read(cvBuilderControllerProvider).errorMessage;
    if (error != null) {
      _showMessage(error);
      return;
    }

    context.push(RouteNames.cvPreviewPath);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

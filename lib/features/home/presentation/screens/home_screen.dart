import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:careermatebd/core/widgets/cv_list_tile.dart';
import 'package:careermatebd/core/widgets/quick_action_tile.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_library_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home — the app's landing screen. Built from `lib/core` widgets + theme tokens
/// to match `docs/design/Home@2x.png`. Tailoring is the core loop, so the indigo
/// hero card and the raised amber "Tailor" nav action both lead to it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// The six quick actions, in the grid order shown in the design.
  static const List<_QuickAction> _quickActions = [
    _QuickAction(
      label: AppStrings.actionCreateCv,
      icon: Icons.note_add_outlined,
      routePath: RouteNames.cvListPath,
    ),
    _QuickAction(
      label: AppStrings.actionAtsCheck,
      icon: Icons.verified_user_outlined,
      routePath: RouteNames.atsCheckerPath,
    ),
    _QuickAction(
      label: AppStrings.actionCoverLetter,
      icon: Icons.mail_outline_rounded,
      routePath: RouteNames.coverLetterPath,
    ),
    _QuickAction(
      label: AppStrings.actionImproveCv,
      icon: Icons.auto_awesome_outlined,
      routePath: RouteNames.aiImprovePath,
    ),
    _QuickAction(
      label: AppStrings.actionInterview,
      icon: Icons.chat_bubble_outline_rounded,
      routePath: RouteNames.interviewPrepPath,
    ),
    _QuickAction(
      label: AppStrings.actionTrackJob,
      icon: Icons.work_outline_rounded,
      routePath: RouteNames.jobTrackerPath,
    ),
  ];

  /// How many saved CVs to surface on Home before deferring to the CVs tab.
  static const int _maxHomeCvs = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvLibrary = ref.watch(cvLibraryControllerProvider);
    final user = ref.watch(currentAuthUserProvider);
    final avatarInitial = _initialFor(user?.email);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.s16,
            AppSpacing.screen,
            AppSpacing.s22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(
                initial: avatarInitial,
                onProfileTap: () => context.push(RouteNames.profilePath),
              ),
              const SizedBox(height: AppSpacing.s20),
              _HeroTailorCard(
                onStart: () => context.push(RouteNames.tailoringPath),
              ),
              const SizedBox(height: AppSpacing.s22),
              const SectionLabel(AppStrings.homeQuickActions),
              const SizedBox(height: AppSpacing.s12),
              const _QuickActionsGrid(actions: _quickActions),
              const SizedBox(height: AppSpacing.s22),
              Row(
                children: [
                  const SectionLabel(AppStrings.homeYourCvs),
                  const Spacer(),
                  _NewCvButton(onTap: () => _createCv(context, ref)),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              _YourCvsSection(
                cvLibrary: cvLibrary,
                maxItems: _maxHomeCvs,
                onReload: () =>
                    ref.read(cvLibraryControllerProvider.notifier).reload(),
                onCreate: () => _createCv(context, ref),
                onOpen: (cv) => _openCv(context, ref, cv.id),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  static String? _initialFor(String? email) {
    final value = email?.trim() ?? '';
    return value.isEmpty ? null : value.substring(0, 1).toUpperCase();
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        break; // Already on Home.
      case 1:
        context.push(RouteNames.cvListPath);
        break;
      case 2:
        context.push(RouteNames.tailoringPath);
        break;
      case 3:
        context.push(RouteNames.jobTrackerPath);
        break;
      case 4:
        context.push(RouteNames.profilePath);
        break;
    }
  }

  /// Starts a fresh draft via the CV builder controller, then opens the builder.
  Future<void> _createCv(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(cvBuilderControllerProvider.notifier);
    await controller.startNewDraft();
    final state = ref.read(cvBuilderControllerProvider);

    if (!context.mounted) {
      return;
    }

    if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }

    context.push(RouteNames.cvBuilderPath);
  }

  /// Loads the selected CV into the builder controller, then opens its preview.
  Future<void> _openCv(BuildContext context, WidgetRef ref, String id) async {
    final controller = ref.read(cvBuilderControllerProvider.notifier);
    await controller.loadDraft(id);
    final state = ref.read(cvBuilderControllerProvider);

    if (!context.mounted) {
      return;
    }

    if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }

    context.push(RouteNames.cvPreviewPath);
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.routePath,
  });

  final String label;
  final IconData icon;
  final String routePath;
}

/// "WELCOME BACK" eyebrow + "Ready to apply?" title + profile avatar button.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.initial, required this.onProfileTap});

  final String? initial;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(AppStrings.homeWelcomeEyebrow),
              const SizedBox(height: AppSpacing.s6),
              Text(AppStrings.homeTitle, style: AppTextStyles.h1),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        _ProfileAvatarButton(initial: initial, onTap: onProfileTap),
      ],
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({required this.initial, required this.onTap});

  final String? initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profile',
      child: Material(
        color: AppColors.primarySoft,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: Center(
              child: initial == null
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 24,
                    )
                  : Text(
                      initial!,
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indigo hero card: eyebrow + title + body + amber CTA, with a faint crosshair
/// motif echoing the "Tailor" mark.
class _HeroTailorCard extends StatelessWidget {
  const _HeroTailorCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.cardRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadii.cardRadius,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -34,
              right: -28,
              child: Icon(
                Icons.gps_fixed,
                size: 150,
                color: AppColors.onPrimary.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.homeHeroEyebrow.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primarySoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    AppStrings.homeHeroCardTitle,
                    style: AppTextStyles.h2.copyWith(color: AppColors.onPrimary),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    AppStrings.homeHeroCardBody,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  AmberCtaButton(
                    label: AppStrings.homeHeroCta,
                    trailingIcon: Icons.arrow_forward_rounded,
                    expanded: false,
                    onPressed: onStart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-column grid of [QuickActionTile]s.
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    const spacing = AppSpacing.s12;
    const columns = 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: tileWidth,
                child: QuickActionTile(
                  icon: action.icon,
                  label: action.label,
                  onTap: () => context.push(action.routePath),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "+ New" text action beside the "Your CVs" label.
class _NewCvButton extends StatelessWidget {
  const _NewCvButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: AppRadii.pillRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.s4),
              Text(
                AppStrings.homeNewCv,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Your CVs" list bound to [cvLibraryControllerProvider] — handles loading,
/// error, empty, and data states.
class _YourCvsSection extends StatelessWidget {
  const _YourCvsSection({
    required this.cvLibrary,
    required this.maxItems,
    required this.onReload,
    required this.onCreate,
    required this.onOpen,
  });

  final AsyncValue<List<CvProfile>> cvLibrary;
  final int maxItems;
  final VoidCallback onReload;
  final VoidCallback onCreate;
  final ValueChanged<CvProfile> onOpen;

  @override
  Widget build(BuildContext context) {
    return cvLibrary.when(
      loading: () => const _CvsMessageCard(
        icon: Icons.hourglass_empty_rounded,
        title: null,
        body: 'Loading your CVs…',
      ),
      error: (error, stackTrace) => _CvsMessageCard(
        icon: Icons.error_outline_rounded,
        title: AppStrings.homeCvsError,
        body: null,
        actionLabel: AppStrings.homeRetry,
        onAction: onReload,
      ),
      data: (cvs) {
        if (cvs.isEmpty) {
          return _CvsMessageCard(
            icon: Icons.description_outlined,
            title: AppStrings.homeCvsEmptyTitle,
            body: AppStrings.homeCvsEmptyBody,
            actionLabel: AppStrings.actionCreateCv,
            onAction: onCreate,
          );
        }

        final visible = cvs.take(maxItems).toList();
        return Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s12),
              CvListTile(
                title: visible[i].displayTitle,
                subtitle: _subtitleFor(visible[i]),
                onTap: () => onOpen(visible[i]),
              ),
            ],
          ],
        );
      },
    );
  }

  String _subtitleFor(CvProfile cv) {
    return 'Edited ${DateFormatter.shortDate(cv.updatedAt)} · '
        '${cv.template.label}';
  }
}

/// Compact card used for the loading / empty / error states of "Your CVs".
class _CvsMessageCard extends StatelessWidget {
  const _CvsMessageCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String? title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadii.iconTileRadius,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(title!, style: AppTextStyles.itemTitle),
                if (title != null && body != null)
                  const SizedBox(height: AppSpacing.s4),
                if (body != null)
                  Text(body!, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.s8),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

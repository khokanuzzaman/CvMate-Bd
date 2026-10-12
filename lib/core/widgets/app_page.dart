import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';

/// Page chrome for the app's screens: the page ground, [AppTopBar] and a body,
/// with an optional pinned [footer]. [headerTrailing] sits after the top bar
/// (e.g. a ⋮ menu).
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.trailingIcon,
    this.trailingTooltip,
    this.onTrailingTap,
    this.headerTrailing,
    this.footer,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final IconData? trailingIcon;
  final String? trailingTooltip;
  final VoidCallback? onTrailingTap;
  final Widget? headerTrailing;
  final Widget? footer;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.s12,
                AppSpacing.screen,
                AppSpacing.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTopBar(
                      title: title,
                      onBack: onBack,
                      trailingIcon: trailingIcon,
                      trailingTooltip: trailingTooltip,
                      onTrailingTap: onTrailingTap,
                    ),
                  ),
                  ?headerTrailing,
                ],
              ),
            ),
            Expanded(child: body),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// A scrolling column with the standard screen padding, for [AppPage.body].
class AppPageScroll extends StatelessWidget {
  const AppPageScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Pinned bottom area for [AppPage.footer] (standard padding).
class AppPageFooter extends StatelessWidget {
  const AppPageFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      child: child,
    );
  }
}

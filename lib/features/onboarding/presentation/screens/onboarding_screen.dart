import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, const Color(0xFF144B7D)],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            AppStrings.shortTagline,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.onboardingHeadline,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.onboardingBody,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _OnboardingPoint(
                    icon: Icons.description_outlined,
                    title: 'Create ATS-friendly CVs',
                    description:
                        'Step-by-step CV building for freshers, internships, and junior professionals.',
                  ),
                  const SizedBox(height: 16),
                  const _OnboardingPoint(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Improve writing with AI',
                    description:
                        'Sharpen summaries, cover letters, and experience bullets without inventing fake achievements.',
                  ),
                  const SizedBox(height: 16),
                  const _OnboardingPoint(
                    icon: Icons.track_changes_outlined,
                    title: 'Track applications clearly',
                    description:
                        'Keep company names, interview stages, and follow-ups organized instead of scattered in notes.',
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: AppStrings.startBuilding,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push(RouteNames.loginPath),
                  ),
                  const SizedBox(height: 12),
                  CustomButton.secondary(
                    label: AppStrings.createAccount,
                    onPressed: () => context.push(RouteNames.registerPath),
                  ),
                  const SizedBox(height: 12),
                  CustomButton.secondary(
                    label: AppStrings.exploreAsGuest,
                    onPressed: () => context.go(RouteNames.homePath),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: colorScheme.primary,
            child: Icon(icon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

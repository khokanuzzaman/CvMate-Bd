import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Honest paywall PLACEHOLDER shown after a user's free export is used.
///
/// No billing SDK, no countdowns, no fake urgency, no pre-ticked auto-renew.
/// It plainly explains what CvMate Pro will include and that it is not yet
/// available. Real purchase flow arrives in Phase 2.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source});

  /// Where the user hit the paywall from (for analytics only).
  final String? source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.paywallViewed,
        params: {AnalyticsEvents.paramSource: widget.source ?? 'unknown'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const benefits = <String>[
      'Unlimited CV exports (no watermark)',
      'Every template unlocked',
      'Unlimited per-job tailoring and cover letters',
      'More AI credits for rewriting and suggestions',
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'CvMate Pro'),
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
                  Text(
                    'You have used your free export',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your first CV export is always free and clean. To keep '
                    'exporting, CvMate Pro is on the way. Nothing is charged '
                    'today, and your CVs stay saved on this device.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CvMate Pro will include',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        for (final benefit in benefits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_rounded, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Coming soon',
                    icon: Icons.lock_clock_outlined,
                    // Deliberately disabled: no purchase is possible yet, and we
                    // will not pretend otherwise.
                    onPressed: null,
                  ),
                  const SizedBox(height: 12),
                  CustomButton.text(
                    label: 'Not now',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No subscription, no auto-renew, and no charge until Pro '
                    'actually launches.',
                    style: theme.textTheme.bodySmall,
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

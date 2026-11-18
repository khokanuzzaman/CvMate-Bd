import 'dart:async';

import 'package:careermatebd/app/constants/app_links.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/review/review_prompt_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

/// The platform rating calls. [InAppReviewPlatform] in the app; tests fake.
abstract class ReviewPlatform {
  Future<bool> isAvailable();

  /// Asks iOS / Android to show its rating sheet. The OS decides whether it
  /// actually appears (iOS: at most 3 times a year) and never tells us.
  Future<void> requestReview();

  /// Opens the App Store page (Settings > Rate CvMate).
  Future<void> openStoreListing();
}

class InAppReviewPlatform implements ReviewPlatform {
  const InAppReviewPlatform();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing() =>
      InAppReview.instance.openStoreListing(appStoreId: AppLinks.appStoreId);
}

final reviewPlatformProvider = Provider<ReviewPlatform>((ref) {
  return const InAppReviewPlatform();
});

final reviewPrompterProvider = Provider<ReviewPrompter>((ref) {
  return ReviewPrompter(
    store: ref.watch(reviewPromptStoreProvider),
    platform: ref.watch(reviewPlatformProvider),
    analytics: ref.watch(analyticsServiceProvider),
  );
});

/// When CvMate asks for a rating. Only at success moments (an export, or
/// the 2nd and later successful tailoring), at most once every
/// [minGap], never in the first launch, never within [quietAfterSetback] of
/// an error or the paywall. Everyone is asked the same way: there is no
/// "Do you like CvMate?" pre-question (no review gating).
class ReviewPrompter {
  ReviewPrompter({
    required this.store,
    required this.platform,
    required this.analytics,
    DateTime Function()? now,
    this.minGap = const Duration(days: 60),
    this.quietAfterSetback = const Duration(minutes: 10),
  }) : _now = now ?? DateTime.now;

  final ReviewPromptStore store;
  final ReviewPlatform platform;
  final AnalyticsService analytics;
  final DateTime Function() _now;
  final Duration minGap;
  final Duration quietAfterSetback;

  /// In memory on purpose: a setback only matters for this launch.
  DateTime? _lastSetbackAt;
  bool _launchCounted = false;

  /// Once per app launch.
  Future<void> recordLaunch() async {
    if (_launchCounted) {
      return;
    }
    _launchCounted = true;
    await _update((record) => record.copyWith(launches: record.launches + 1));
  }

  /// An error, a failed export or the paywall: no rating request for a while.
  void recordSetback() => _lastSetbackAt = _now();

  Future<void> onExportSucceeded() => _maybeRequest(ReviewTrigger.export);

  Future<void> onTailoringSucceeded() async {
    final record = await _update(
      (record) => record.copyWith(
        successfulTailorings: record.successfulTailorings + 1,
      ),
    );
    if (record != null && record.successfulTailorings >= 2) {
      await _maybeRequest(ReviewTrigger.tailoring);
    }
  }

  /// Settings > Rate CvMate: always allowed, it is the user's own tap.
  Future<void> openStoreListing() => platform.openStoreListing();

  Future<bool> _allowed(ReviewPromptRecord record) async {
    final now = _now();
    if (record.launches < 2) {
      return false;
    }
    final last = record.lastRequestedAt;
    if (last != null && now.difference(last) < minGap) {
      return false;
    }
    final setback = _lastSetbackAt;
    if (setback != null && now.difference(setback) < quietAfterSetback) {
      return false;
    }
    return platform.isAvailable();
  }

  Future<void> _maybeRequest(ReviewTrigger trigger) async {
    try {
      final record = await store.load();
      if (!await _allowed(record)) {
        return;
      }
      await store.save(record.copyWith(lastRequestedAt: _now()));
      unawaited(analytics.log(AnalyticsEvent.reviewPromptRequested(trigger)));
      await platform.requestReview();
    } catch (_) {
      // A rating request must never get in the user's way.
    }
  }

  Future<ReviewPromptRecord?> _update(
    ReviewPromptRecord Function(ReviewPromptRecord record) change,
  ) async {
    try {
      final next = change(await store.load());
      await store.save(next);
      return next;
    } catch (_) {
      return null;
    }
  }
}

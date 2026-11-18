import 'package:careermatebd/shared/services/review/review_prompt_store.dart';
import 'package:careermatebd/shared/services/review/review_prompter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/core_flow_harness.dart';

class _FakeReviewPlatform implements ReviewPlatform {
  int requests = 0;
  int storeOpens = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requests++;

  @override
  Future<void> openStoreListing() async => storeOpens++;
}

void main() {
  late DateTime now;
  late MemoryReviewPromptStore store;
  late _FakeReviewPlatform platform;
  late RecordingAnalytics analytics;

  ReviewPrompter prompter() => ReviewPrompter(
    store: store,
    platform: platform,
    analytics: analytics,
    now: () => now,
  );

  setUp(() {
    now = DateTime(2026, 11, 16, 10);
    store = MemoryReviewPromptStore();
    platform = _FakeReviewPlatform();
    analytics = RecordingAnalytics();
  });

  test('never in the first launch; asks after an export from the second '
      'launch, then not again for 60 days', () async {
    final first = prompter();
    await first.recordLaunch();
    await first.onExportSucceeded();
    expect(platform.requests, 0, reason: 'first launch');

    final second = prompter();
    await second.recordLaunch();
    await second.onExportSucceeded();
    expect(platform.requests, 1);
    expect(analytics.paramsFor('review_prompt_requested').single, {
      'trigger': 'export',
    });

    now = now.add(const Duration(days: 59));
    await second.onExportSucceeded();
    expect(platform.requests, 1, reason: 'within 60 days');

    now = now.add(const Duration(days: 2));
    await second.onExportSucceeded();
    expect(platform.requests, 2);
  });

  test('only from the 2nd successful tailoring, and never right after an '
      'error or the paywall', () async {
    store.record = const ReviewPromptRecord(launches: 3);
    final review = prompter();

    await review.onTailoringSucceeded();
    expect(platform.requests, 0, reason: 'first tailoring');

    review.recordSetback();
    now = now.add(const Duration(minutes: 2));
    await review.onTailoringSucceeded();
    expect(platform.requests, 0, reason: 'just after a setback');

    now = now.add(const Duration(minutes: 15));
    await review.onTailoringSucceeded();
    expect(platform.requests, 1);
    expect(analytics.paramsFor('review_prompt_requested').single, {
      'trigger': 'tailoring',
    });
  });

  test('Rate CvMate opens the store page without any rules', () async {
    await prompter().openStoreListing();
    expect(platform.storeOpens, 1);
    expect(platform.requests, 0);
  });
}

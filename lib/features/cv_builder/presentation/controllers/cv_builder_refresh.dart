import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped whenever something outside the builder fields (e.g. the AI Improve
/// screen) may have rewritten the draft. The builder includes this value in its
/// page key so fields re-read the latest draft instead of showing stale text.
final cvBuilderRefreshProvider = NotifierProvider<CvBuilderRefresh, int>(
  CvBuilderRefresh.new,
);

class CvBuilderRefresh extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

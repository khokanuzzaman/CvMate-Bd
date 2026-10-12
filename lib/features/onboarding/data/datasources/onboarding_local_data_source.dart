import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return const OnboardingLocalDataSource();
});

/// Hive-backed "onboarding seen" flag.
class OnboardingLocalDataSource {
  const OnboardingLocalDataSource();

  static const String _boxName = 'onboarding_box';
  static const String _seenKey = 'onboarding_seen';

  Future<bool> isSeen() async {
    final box = await _openBox();
    return box.get(_seenKey, defaultValue: false) ?? false;
  }

  Future<void> markSeen() async {
    final box = await _openBox();
    await box.put(_seenKey, true);
  }

  Future<Box<bool>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<bool>(_boxName);
    }

    return Hive.openBox<bool>(_boxName);
  }
}

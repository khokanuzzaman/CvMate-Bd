import 'package:careermatebd/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:careermatebd/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  Future<bool> isOnboardingSeen() => _localDataSource.isSeen();

  @override
  Future<void> markOnboardingSeen() => _localDataSource.markSeen();
}

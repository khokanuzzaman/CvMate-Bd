import 'dart:async';

import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:careermatebd/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('app boots through splash to onboarding and home', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository();
    final settingsRepository = _FakeSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
        ],
        child: const CareerMateApp(),
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);

    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingHeadline), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.exploreAsGuest));
    await tester.tap(find.text(AppStrings.exploreAsGuest));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeTitle), findsOneWidget);
    expect(find.text(AppStrings.homeHeroCardTitle), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository();

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield currentUser;
    yield* _controller.stream;
  }

  @override
  Future<Result<AuthUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return Success(AuthUser(uid: 'test-user', email: email));
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return Success(AuthUser(uid: 'test-user', email: email));
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    return const Success(
      AuthUser(uid: 'guest-user', email: '', isAnonymous: true),
    );
  }

  @override
  Future<Result<AuthUser>> linkEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return Success(AuthUser(uid: 'test-user', email: email));
  }

  @override
  Future<Result<void>> signOut() async {
    return const Success<void>(null);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppPreferences _preferences = const AppPreferences.defaults();

  @override
  Future<AppPreferences> loadPreferences() async {
    return _preferences;
  }

  @override
  Future<AppPreferences> savePreferences(AppPreferences preferences) async {
    _preferences = preferences;
    return _preferences;
  }
}

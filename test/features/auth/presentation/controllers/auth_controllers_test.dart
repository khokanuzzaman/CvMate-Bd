import 'dart:async';

import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:careermatebd/features/auth/presentation/controllers/login_controller.dart';
import 'package:careermatebd/features/auth/presentation/controllers/logout_controller.dart';
import 'package:careermatebd/features/auth/presentation/controllers/register_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login controller signs in successfully', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });

    final success = await container
        .read(loginControllerProvider.notifier)
        .signIn(email: 'rahim@example.com', password: 'secret12');

    expect(success, isTrue);
    expect(repository.currentUser?.email, 'rahim@example.com');
    expect(
      container.read(loginControllerProvider).successMessage,
      'Logged in successfully.',
    );
  });

  test('register controller blocks mismatched passwords', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });

    final success = await container
        .read(registerControllerProvider.notifier)
        .register(
          email: 'rahim@example.com',
          password: 'secret12',
          confirmPassword: 'different12',
        );

    expect(success, isFalse);
    expect(repository.createdUsers, isEmpty);
    expect(
      container.read(registerControllerProvider).errorMessage,
      'Passwords do not match.',
    );
  });

  test('auth session provider and reset/logout flows stay in sync', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await repository.dispose();
      container.dispose();
    });

    container.listen(
      authSessionProvider,
      (previous, next) {},
      fireImmediately: true,
    );

    final resetSuccess = await container
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetLink(email: 'rahim@example.com');
    expect(resetSuccess, isTrue);
    expect(repository.lastResetEmail, 'rahim@example.com');

    await container
        .read(loginControllerProvider.notifier)
        .signIn(email: 'rahim@example.com', password: 'secret12');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentAuthUserProvider)?.email, 'rahim@example.com');

    final logoutSuccess = await container
        .read(logoutControllerProvider.notifier)
        .signOut();
    await Future<void>.delayed(Duration.zero);
    expect(logoutSuccess, isTrue);
    expect(repository.currentUser, isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository();

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  final List<String> createdUsers = [];
  String? lastResetEmail;
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

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
    createdUsers.add(email);
    final user = AuthUser(uid: 'created-user', email: email);
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    lastResetEmail = email;
    return const Success<void>(null);
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = AuthUser(uid: 'signed-in-user', email: email);
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _controller.add(null);
    return const Success<void>(null);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

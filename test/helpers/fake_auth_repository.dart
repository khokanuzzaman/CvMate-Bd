import 'dart:async';

import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository] for widget tests. Records calls and can be told to
/// fail sign-in / sign-up with a message via [failWith].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failWith, this.displayName});

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  /// When non-null, sign-in and sign-up return a failure with this message.
  String? failWith;

  /// Display name given to the users this fake signs in.
  final String? displayName;

  final List<String> signInEmails = [];
  final List<String> createdEmails = [];
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield currentUser;
    yield* _controller.stream;
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInEmails.add(email);
    return _authenticate(uid: 'signed-in-user', email: email);
  }

  @override
  Future<Result<AuthUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createdEmails.add(email);
    return _authenticate(uid: 'created-user', email: email);
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    return _authenticate(uid: 'guest-user', email: '', isAnonymous: true);
  }

  @override
  Future<Result<AuthUser>> linkEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _authenticate(uid: _currentUser?.uid ?? 'guest-user', email: email);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _controller.add(null);
    return const Success<void>(null);
  }

  Future<void> dispose() => _controller.close();

  Result<AuthUser> _authenticate({
    required String uid,
    required String email,
    bool isAnonymous = false,
  }) {
    final message = failWith;
    if (message != null) {
      return FailureResult<AuthUser>(Failure(message));
    }

    final user = AuthUser(
      uid: uid,
      email: email,
      displayName: displayName,
      isAnonymous: isAnonymous,
    );
    _currentUser = user;
    _controller.add(user);
    return Success(user);
  }
}

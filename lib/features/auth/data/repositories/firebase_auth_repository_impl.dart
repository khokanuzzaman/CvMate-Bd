import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<fb_auth.FirebaseAuth>((ref) {
  return fb_auth.FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthRepositoryImpl(firebaseAuth);
});

class FirebaseAuthRepositoryImpl implements AuthRepository {
  const FirebaseAuthRepositoryImpl(this._firebaseAuth);

  final fb_auth.FirebaseAuth _firebaseAuth;

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(credential.user);
      if (user == null) {
        return const FailureResult<AuthUser>(
          Failure('Could not sign in right now. Please try again.'),
        );
      }
      return Success(user);
    } on fb_auth.FirebaseAuthException catch (error) {
      return FailureResult<AuthUser>(
        Failure(_messageForException(error), code: error.code),
      );
    } catch (_) {
      return const FailureResult<AuthUser>(
        Failure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Result<AuthUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(credential.user);
      if (user == null) {
        return const FailureResult<AuthUser>(
          Failure('Could not create your account right now. Please try again.'),
        );
      }
      return Success(user);
    } on fb_auth.FirebaseAuthException catch (error) {
      return FailureResult<AuthUser>(
        Failure(_messageForException(error), code: error.code),
      );
    } catch (_) {
      return const FailureResult<AuthUser>(
        Failure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = _mapUser(credential.user);
      if (user == null) {
        return const FailureResult<AuthUser>(
          Failure('Could not start a guest session. Please try again.'),
        );
      }
      return Success(user);
    } on fb_auth.FirebaseAuthException catch (error) {
      return FailureResult<AuthUser>(
        Failure(_messageForException(error), code: error.code),
      );
    } catch (_) {
      return const FailureResult<AuthUser>(
        Failure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Result<AuthUser>> linkEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final current = _firebaseAuth.currentUser;
    if (current == null) {
      return const FailureResult<AuthUser>(
        Failure('Please start a session before linking an account.'),
      );
    }

    try {
      final credential = fb_auth.EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final linked = await current.linkWithCredential(credential);
      final user = _mapUser(linked.user);
      if (user == null) {
        return const FailureResult<AuthUser>(
          Failure('Could not upgrade your account right now. Please try again.'),
        );
      }
      return Success(user);
    } on fb_auth.FirebaseAuthException catch (error) {
      return FailureResult<AuthUser>(
        Failure(_messageForException(error), code: error.code),
      );
    } catch (_) {
      return const FailureResult<AuthUser>(
        Failure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const Success<void>(null);
    } on fb_auth.FirebaseAuthException catch (error) {
      return FailureResult<void>(
        Failure(_messageForException(error), code: error.code),
      );
    } catch (_) {
      return const FailureResult<void>(
        Failure('Could not send a reset link right now. Please try again.'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Success<void>(null);
    } catch (_) {
      return const FailureResult<void>(
        Failure('Could not log out right now. Please try again.'),
      );
    }
  }

  AuthUser? _mapUser(fb_auth.User? user) {
    if (user == null) {
      return null;
    }

    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }

  String _messageForException(fb_auth.FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' =>
        'This account has been disabled. Please contact support.',
      'user-not-found' => 'No account found with this email address.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists with this email.',
      'credential-already-in-use' =>
        'This email is already linked to another account. Please sign in instead.',
      'provider-already-linked' =>
        'This account is already linked to an email login.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled. Please contact support.',
      'weak-password' => 'Password must be at least 6 characters.',
      'too-many-requests' =>
        'Too many attempts detected. Please try again later.',
      'network-request-failed' =>
        'Network error. Please check your internet connection.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }
}

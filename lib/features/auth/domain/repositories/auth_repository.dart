import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<Result<AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// Signs the user in as an anonymous guest so a brand-new user can start
  /// building immediately and still get cloud backup.
  Future<Result<AuthUser>> signInAnonymously();

  /// Upgrades the current (typically anonymous) user by linking an
  /// email/password credential. The Firebase uid is preserved, so any CVs
  /// already synced under that uid stay with the account — no orphaned data.
  ///
  /// TODO(auth): add Google linking (linkWithCredential with a Google
  /// credential) once `google_sign_in` + OAuth client config are wired in.
  Future<Result<AuthUser>> linkEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}

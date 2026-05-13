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

  Future<Result<void>> signOut();
}

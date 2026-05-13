import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authSessionProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

final currentAuthUserProvider = Provider<AuthUser?>((ref) {
  ref.watch(authSessionProvider);
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

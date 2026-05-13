import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginControllerProvider =
    NotifierProvider<LoginController, AuthFormState>(LoginController.new);

class LoginController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => AuthFormState.initial();

  void clearFeedback() {
    state = state.copyWith(clearErrorMessage: true, clearSuccessMessage: true);
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    final result = await ref
        .read(authRepositoryProvider)
        .signInWithEmailAndPassword(email: email, password: password);

    return result.when(
      success: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Logged in successfully.',
          clearErrorMessage: true,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          clearSuccessMessage: true,
        );
        return false;
      },
    );
  }
}

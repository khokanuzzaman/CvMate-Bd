import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final registerControllerProvider =
    NotifierProvider<RegisterController, AuthFormState>(RegisterController.new);

class RegisterController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => AuthFormState.initial();

  void clearFeedback() {
    state = state.copyWith(clearErrorMessage: true, clearSuccessMessage: true);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password.trim() != confirmPassword.trim()) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Passwords do not match.',
        clearSuccessMessage: true,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    final result = await ref
        .read(authRepositoryProvider)
        .createUserWithEmailAndPassword(email: email, password: password);

    return result.when(
      success: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Account created successfully.',
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

import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final logoutControllerProvider =
    NotifierProvider<LogoutController, AuthFormState>(LogoutController.new);

class LogoutController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => AuthFormState.initial();

  Future<bool> signOut() async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    final result = await ref.read(authRepositoryProvider).signOut();
    return result.when(
      success: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Logged out successfully.',
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

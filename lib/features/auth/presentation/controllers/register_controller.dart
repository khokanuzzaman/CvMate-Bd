import 'dart:async';

import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_form_state.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/auth/presentation/controllers/new_account_session_provider.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
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
    String? displayName,
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
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );

    return result.when(
      success: (user) {
        ref.read(newAccountSessionProvider.notifier).markCreated(user.uid);
        // The name is saved after the sign-in event, so read the user again.
        ref.invalidate(currentAuthUserProvider);
        unawaited(
          ref
              .read(analyticsServiceProvider)
              .log(AnalyticsEvent.signUp(AuthMethod.email)),
        );
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

class AuthFormState {
  const AuthFormState({
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
  });

  factory AuthFormState.initial() => const AuthFormState(
    isLoading: false,
    errorMessage: null,
    successMessage: null,
  );

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AuthFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

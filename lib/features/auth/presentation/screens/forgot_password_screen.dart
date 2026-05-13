import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearFeedback);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_clearFeedback)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reset password'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppConstants.defaultPadding,
            AppConstants.defaultPadding,
            AppConstants.defaultPadding,
            AppConstants.defaultPadding +
                MediaQuery.of(context).viewInsets.bottom +
                24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recover your account',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the email address you used for CareerMate BD. Firebase Auth will send a password reset email.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  CustomCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.errorMessage != null) ...[
                            _FeedbackCard(
                              message: state.errorMessage!,
                              isError: true,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (state.successMessage != null) ...[
                            _FeedbackCard(
                              message: state.successMessage!,
                              isError: false,
                            ),
                            const SizedBox(height: 16),
                          ],
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            label: state.isLoading
                                ? 'Sending reset link...'
                                : 'Send reset link',
                            onPressed: state.isLoading ? null : _submit,
                            icon: Icons.mark_email_read_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomCard(
                    child: CustomButton.secondary(
                      label: 'Back to login',
                      onPressed: () => context.go(RouteNames.loginPath),
                      icon: Icons.arrow_back_rounded,
                      isExpanded: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearFeedback() {
    ref.read(forgotPasswordControllerProvider.notifier).clearFeedback();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetLink(email: _emailController.text);
    if (!mounted) {
      return;
    }

    final state = ref.read(forgotPasswordControllerProvider);
    if (success && state.successMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
    }
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isError ? colorScheme.error : const Color(0xFF0D6B44);
    final background = isError
        ? colorScheme.error.withValues(alpha: 0.08)
        : const Color(0xFFDFF7EA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: foreground),
      ),
    );
  }
}

import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/auth/presentation/controllers/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearFeedback);
    _passwordController.addListener(_clearFeedback);
    _confirmPasswordController.addListener(_clearFeedback);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_clearFeedback)
      ..dispose();
    _passwordController
      ..removeListener(_clearFeedback)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_clearFeedback)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Create account'),
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
                    'Create your account',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email/password auth is ready, while your local CVs, drafts, and job-tracker data stay on this device.',
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
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Minimum 6 characters',
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: Validators.password,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm password',
                            hintText: 'Re-enter your password',
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) => Validators.confirmPassword(
                              value,
                              password: _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            label: state.isLoading
                                ? 'Creating account...'
                                : 'Create account',
                            onPressed: state.isLoading ? null : _submit,
                            icon: Icons.app_registration_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Already have an account?',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in with the same email later. Local drafts remain available even before cloud sync exists.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        CustomButton.secondary(
                          label: 'Go to login',
                          onPressed: () => context.push(RouteNames.loginPath),
                          icon: Icons.login_rounded,
                          isExpanded: false,
                        ),
                      ],
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
    ref.read(registerControllerProvider.notifier).clearFeedback();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final success = await ref
        .read(registerControllerProvider.notifier)
        .register(
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (!mounted) {
      return;
    }

    final state = ref.read(registerControllerProvider);
    if (success) {
      if (state.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
      }
      context.go(RouteNames.homePath);
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

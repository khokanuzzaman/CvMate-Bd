import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/custom_app_bar.dart';
import 'package:careermatebd/core/widgets/custom_button.dart';
import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/core/widgets/custom_text_field.dart';
import 'package:careermatebd/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearFeedback);
    _passwordController.addListener(_clearFeedback);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_clearFeedback)
      ..dispose();
    _passwordController
      ..removeListener(_clearFeedback)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Login'),
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
                  Text('Welcome back', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with email and password. Your existing CVs and local drafts will stay on this device.',
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
                            textInputAction: TextInputAction.done,
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
                          const SizedBox(height: 20),
                          CustomButton(
                            label: state.isLoading ? 'Logging in...' : 'Login',
                            onPressed: state.isLoading ? null : _submit,
                            icon: Icons.login_rounded,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CustomButton.text(
                              label: 'Forgot password?',
                              onPressed: state.isLoading
                                  ? null
                                  : () => context.push(
                                      RouteNames.forgotPasswordPath,
                                    ),
                            ),
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
                          'New to CareerMate BD?',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create an account for Firebase Auth now, or keep using local-first tools as a guest.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            CustomButton.secondary(
                              label: 'Create account',
                              onPressed: () =>
                                  context.push(RouteNames.registerPath),
                              icon: Icons.app_registration_rounded,
                              isExpanded: false,
                            ),
                            CustomButton.secondary(
                              label: 'Explore as guest',
                              onPressed: () => context.go(RouteNames.homePath),
                              icon: Icons.arrow_forward_rounded,
                              isExpanded: false,
                            ),
                          ],
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
    ref.read(loginControllerProvider.notifier).clearFeedback();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final success = await ref
        .read(loginControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) {
      return;
    }

    final state = ref.read(loginControllerProvider);
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

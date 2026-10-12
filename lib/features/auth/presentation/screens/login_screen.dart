import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/brand_logo_tile.dart';
import 'package:careermatebd/core/widgets/social_auth_button.dart';
import 'package:careermatebd/features/auth/presentation/controllers/login_controller.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_or_divider.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_switch_link.dart';
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

    return AuthPageLayout(
      footer: AuthSwitchLink(
        prompt: AppStrings.loginNewHere,
        actionLabel: AppStrings.createAccount,
        onTap: () => context.push(RouteNames.registerPath),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandLogoTile(),
              const SizedBox(width: AppSpacing.s12),
              Text(AppStrings.brandName, style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: AppSpacing.s22 * 2),
          Text(AppStrings.loginTitle, style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.s8),
          Text(
            AppStrings.loginSubtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s22 + AppSpacing.s6),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.errorMessage != null) ...[
                  AuthErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: AppSpacing.s16),
                ],
                AppTextField(
                  controller: _emailController,
                  label: AppStrings.authEmailLabel,
                  hintText: AppStrings.authEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.s16),
                AppTextField(
                  controller: _passwordController,
                  label: AppStrings.authPasswordLabel,
                  labelTrailing: TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => context.push(RouteNames.forgotPasswordPath),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        AppSpacing.minTouchTarget,
                        AppSpacing.minTouchTarget,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s6,
                      ),
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      AppStrings.loginForgot,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  hintText: AppStrings.loginPasswordHint,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    tooltip: _obscurePassword
                        ? AppStrings.authShowPassword
                        : AppStrings.authHidePassword,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted2,
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.s20),
                PrimaryButton(
                  label: state.isLoading
                      ? AppStrings.loginSubmitting
                      : AppStrings.authLogIn,
                  onPressed: state.isLoading ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.s20),
                const AuthOrDivider(),
                const SizedBox(height: AppSpacing.s20),
                // TODO(google-sign-in): wire once AuthRepository supports it.
                const SocialAuthButton(
                  label: AppStrings.loginGoogle,
                  onPressed: null,
                  disabledHint: AppStrings.authGoogleComingSoon,
                ),
              ],
            ),
          ),
        ],
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

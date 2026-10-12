import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/core/widgets/social_auth_button.dart';
import 'package:careermatebd/features/auth/domain/password_strength.dart';
import 'package:careermatebd/features/auth/presentation/controllers/register_controller.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_or_divider.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:careermatebd/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const int _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _showTermsError = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearFeedback);
    _passwordController.addListener(_clearFeedback);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final state = ref.watch(registerControllerProvider);

    return AuthPageLayout(
      footer: AuthSwitchLink(
        prompt: AppStrings.authHaveAccount,
        actionLabel: AppStrings.authLogIn,
        onTap: _goToLogin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTopBar(title: AppStrings.createAccount, onBack: _goToLogin),
          const SizedBox(height: AppSpacing.s22),
          Text(AppStrings.registerHeadline, style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.s8),
          Text(
            AppStrings.registerSubtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.errorMessage != null) ...[
                  AuthErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: AppSpacing.s16),
                ],
                // TODO(display-name): the name is validated but not yet saved —
                // AuthRepository has no display-name API.
                AppTextField(
                  controller: _nameController,
                  label: AppStrings.registerNameLabel,
                  hintText: AppStrings.registerNameHint,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.requiredText(
                    value,
                    fieldName: AppStrings.registerNameLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
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
                  hintText: AppStrings.registerPasswordHint,
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
                  validator: (value) => Validators.password(
                    value,
                    minLength: _minPasswordLength,
                  ),
                ),
                const SizedBox(height: AppSpacing.s10),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _passwordController,
                  builder: (context, value, _) => PasswordStrengthMeter(
                    strength: PasswordStrength.evaluate(value.text),
                  ),
                ),
                const SizedBox(height: AppSpacing.s14),
                _TermsCheckbox(
                  value: _acceptedTerms,
                  showError: _showTermsError && !_acceptedTerms,
                  onChanged: _setAcceptedTerms,
                ),
                const SizedBox(height: AppSpacing.s16),
                PrimaryButton(
                  label: state.isLoading
                      ? AppStrings.registerSubmitting
                      : AppStrings.createAccount,
                  onPressed: state.isLoading ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.s20),
                const AuthOrDivider(),
                const SizedBox(height: AppSpacing.s20),
                // TODO(google-sign-in): wire once AuthRepository supports it.
                const SocialAuthButton(
                  label: AppStrings.registerGoogle,
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

  void _setAcceptedTerms(bool accepted) {
    setState(() {
      _acceptedTerms = accepted;
    });
  }

  /// Register is only reachable from Login, so back / "Log in" returns there.
  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.loginPath);
    }
  }

  void _clearFeedback() {
    ref.read(registerControllerProvider.notifier).clearFeedback();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!_acceptedTerms) {
      setState(() {
        _showTermsError = true;
      });
    }
    if (!isFormValid || !_acceptedTerms) {
      return;
    }

    // The design has a single password field, so the password confirms itself.
    final password = _passwordController.text;
    final success = await ref
        .read(registerControllerProvider.notifier)
        .register(
          email: _emailController.text,
          password: password,
          confirmPassword: password,
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

/// "I agree to the Terms and Privacy Policy." row with an inline error.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTextStyles.bodySm.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: AppRadii.inputRadius,
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: AppColors.primary,
                checkColor: AppColors.onPrimary,
                side: const BorderSide(color: AppColors.muted2, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                // TODO(legal-links): Terms / Privacy are styled as links but
                // not tappable until the legal pages exist.
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodySm,
                    children: [
                      const TextSpan(text: AppStrings.registerTermsPrefix),
                      TextSpan(text: AppStrings.registerTerms, style: linkStyle),
                      const TextSpan(text: AppStrings.registerTermsAnd),
                      TextSpan(
                        text: AppStrings.registerPrivacy,
                        style: linkStyle,
                      ),
                      const TextSpan(text: AppStrings.registerTermsSuffix),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s12),
            child: Text(
              AppStrings.registerTermsRequired,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

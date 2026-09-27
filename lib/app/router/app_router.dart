import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/features/ats_checker/presentation/screens/ats_checker_screen.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:careermatebd/features/auth/presentation/screens/login_screen.dart';
import 'package:careermatebd/features/auth/presentation/screens/register_screen.dart';
import 'package:careermatebd/features/cover_letter/presentation/screens/cover_letter_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/ai_improve_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_builder_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_list_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_pdf_preview_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_preview_screen.dart';
import 'package:careermatebd/features/home/presentation/screens/home_screen.dart';
import 'package:careermatebd/features/interview_prep/presentation/screens/interview_prep_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_details_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_form_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_tracker_screen.dart';
import 'package:careermatebd/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:careermatebd/features/profile/presentation/screens/profile_screen.dart';
import 'package:careermatebd/features/settings/presentation/screens/settings_screen.dart';
import 'package:careermatebd/features/splash/presentation/screens/splash_screen.dart';
import 'package:careermatebd/features/tailoring/presentation/screens/tailoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _splashGateProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(AppConstants.splashDuration);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final authSession = ref.watch(authSessionProvider);
  final splashGate = ref.watch(_splashGateProvider);
  final currentUser = authSession.asData?.value ?? repository.currentUser;
  final isLoggedIn = currentUser != null;
  final isAuthLoading = authSession.isLoading && currentUser == null;
  final isSplashReady = splashGate.hasValue;

  return GoRouter(
    initialLocation: RouteNames.splashPath,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isSplashRoute = location == RouteNames.splashPath;
      final isPublicAuthRoute =
          location == RouteNames.onboardingPath ||
          location == RouteNames.loginPath ||
          location == RouteNames.registerPath ||
          location == RouteNames.forgotPasswordPath;

      if (isSplashRoute) {
        if (!isSplashReady || isAuthLoading) {
          return null;
        }
        return isLoggedIn ? RouteNames.homePath : RouteNames.onboardingPath;
      }

      if (isLoggedIn && isPublicAuthRoute) {
        return RouteNames.homePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingPath,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.profilePath,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.cvListPath,
        name: RouteNames.cvList,
        builder: (context, state) => const CvListScreen(),
      ),
      GoRoute(
        path: RouteNames.cvBuilderPath,
        name: RouteNames.cvBuilder,
        builder: (context, state) => const CvBuilderScreen(),
      ),
      GoRoute(
        path: RouteNames.cvPreviewPath,
        name: RouteNames.cvPreview,
        builder: (context, state) => const CvPreviewScreen(),
      ),
      GoRoute(
        path: RouteNames.cvPdfPreviewPath,
        name: RouteNames.cvPdfPreview,
        builder: (context, state) => const CvPdfPreviewScreen(),
      ),
      GoRoute(
        path: RouteNames.aiImprovePath,
        name: RouteNames.aiImprove,
        builder: (context, state) => const AiImproveScreen(),
      ),
      GoRoute(
        path: RouteNames.coverLetterPath,
        name: RouteNames.coverLetter,
        builder: (context, state) => const CoverLetterScreen(),
      ),
      GoRoute(
        path: RouteNames.jobTrackerPath,
        name: RouteNames.jobTracker,
        builder: (context, state) => const JobTrackerScreen(),
      ),
      GoRoute(
        path: RouteNames.jobApplicationFormPath,
        name: RouteNames.jobApplicationForm,
        builder: (context, state) => JobApplicationFormScreen(
          applicationId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: RouteNames.jobApplicationDetailsPath,
        name: RouteNames.jobApplicationDetails,
        builder: (context, state) => JobApplicationDetailsScreen(
          applicationId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: RouteNames.interviewPrepPath,
        name: RouteNames.interviewPrep,
        builder: (context, state) => const InterviewPrepScreen(),
      ),
      GoRoute(
        path: RouteNames.atsCheckerPath,
        name: RouteNames.atsChecker,
        builder: (context, state) => const AtsCheckerScreen(),
      ),
      GoRoute(
        path: RouteNames.tailoringPath,
        name: RouteNames.tailoring,
        builder: (context, state) => const TailoringScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: SafeArea(
          child: CustomErrorView(
            title: AppStrings.routeErrorTitle,
            message: '${AppStrings.routeErrorMessage}\n${state.uri}',
          ),
        ),
      );
    },
  );
});

import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/screens/login_screen.dart';
import 'package:careermatebd/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_auth_repository.dart';

const String loginPlaceholder = 'login-page';
const String registerPlaceholder = 'register-page';
const String homePlaceholder = 'home-page';

/// Pumps the real [LoginScreen] / [RegisterScreen] inside a tiny router, with
/// placeholder pages for the routes they navigate to, on a phone-sized surface.
Future<void> pumpAuthScreen(
  WidgetTester tester, {
  required FakeAuthRepository repository,
  required String initialLocation,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget placeholder(String label) => Scaffold(body: Center(child: Text(label)));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.homePath,
        builder: (context, state) => placeholder(homePlaceholder),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        builder: (context, state) => placeholder('forgot-page'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

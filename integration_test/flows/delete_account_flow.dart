import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/app_router.dart';
import 'package:careermatebd/features/account_deletion/presentation/controllers/account_deletion_controller.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_harness.dart';

/// The QA password every `launchSignedIn` user gets (Auth emulator only).
const _qaPassword = 'QaPass123';

/// One server answer for `DELETE /v1/me`, after [delay].
class _Reply {
  const _Reply(this.status, {this.code, this.delay = Duration.zero});

  final int status;
  final String? code;
  final Duration delay;
}

/// Stands in for cvmate-api: answers `DELETE /v1/me` from [replies] in order
/// (the last one repeats) and the entitlement read with a free plan. The
/// real Firebase ID token is read (no override), so a 401 makes the client
/// call `getIdToken(true)` against the Auth emulator, as on a device.
class _DeleteServer implements HttpClientAdapter {
  _DeleteServer(this.replies);

  final List<_Reply> replies;
  int deletes = 0;

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'https://ai.test'))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    var reply = const _Reply(200);
    Map<String, Object?> body = {'deleted': true};
    if (options.method == 'DELETE' && options.path == deleteMePath) {
      reply = replies[deletes.clamp(0, replies.length - 1)];
      deletes++;
      body = reply.code == null
          ? {'deleted': true}
          : {
              'error': {'code': reply.code, 'message': reply.code},
            };
    } else if (options.path == '/v1/me/entitlement') {
      body = {
        'plan': 'free',
        'proExpiresAt': null,
        'actionsLeft': 3,
        'resetsAt': null,
      };
    }
    await Future<void>.delayed(reply.delay);
    return ResponseBody.fromString(
      jsonEncode(body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _reauth = _Reply(401, code: 'reauth_required');
const _ok = _Reply(200);

/// Where a Delete ended. Exactly one of the first three is allowed.
enum _End { deletedOnboarding, passwordPrompt, visibleError, silent }

_End _whereItEnded(WidgetTester tester) {
  final signedOut = FirebaseAuth.instance.currentUser == null;
  if (find.text(AppStrings.deleteAccountPasswordTitle).evaluate().isNotEmpty) {
    return _End.passwordPrompt;
  }
  if (signedOut &&
      find.text(AppStrings.onboardingGetStarted).evaluate().isNotEmpty) {
    return _End.deletedOnboarding;
  }
  final onSettings = find.text(AppStrings.settings).evaluate().isNotEmpty;
  final message = appContainer(
    tester,
  ).read(accountDeletionControllerProvider).errorMessage;
  final errorShown =
      message != null && find.text(message).evaluate().isNotEmpty;
  if (!signedOut && onSettings && errorShown) {
    return _End.visibleError;
  }
  return _End.silent;
}

String _visibleScreen() {
  for (final (label, text) in [
    ('onboarding', AppStrings.onboardingGetStarted),
    ('login', AppStrings.loginTitle),
    ('settings', AppStrings.settings),
    ('home', 'Ready to apply?'),
  ]) {
    if (find.text(text).evaluate().isNotEmpty) {
      return label;
    }
  }
  return 'unknown';
}

/// Signs in a new emulator user, opens Settings through the UI and counts
/// router rebuilds and auth emissions while [run] taps through a deletion.
Future<void> _deleteCase(
  WidgetTester tester, {
  required String name,
  required List<_Reply> replies,
  required Set<_End> allowed,
  required Future<void> Function(WidgetTester tester) run,
  int? expectedDeletes,
}) async {
  final server = _DeleteServer(replies);
  await launchSignedIn(
    tester,
    overrides: [aiServerDioProvider.overrideWithValue(server.dio())],
  );
  final container = appContainer(tester);
  var routers = 0;
  var authEvents = 0;
  final routerSub = container.listen(appRouterProvider, (_, _) => routers++);
  final authSub = container.listen(authSessionProvider, (_, _) => authEvents++);
  try {
    await tapText(tester, 'Profile');
    await tapText(tester, AppStrings.profileMoreSettings);
    await waitFor(tester, find.text(AppStrings.deleteAccount));

    await run(tester);
    await pumpFor(tester, const Duration(seconds: 2));

    final end = _whereItEnded(tester);
    debugPrint(
      'QA-DELETE | $name | end=${end.name} | screen=${_visibleScreen()} '
      '| signedOut=${FirebaseAuth.instance.currentUser == null} '
      '| deletes=${server.deletes} | routerRebuilds=$routers '
      '| authEvents=$authEvents',
    );
    await shot(tester, 'delete-account', name);
    expect(
      allowed,
      contains(end),
      reason:
          '$name ended "${end.name}" on ${_visibleScreen()} '
          '(router rebuilt $routers times, $authEvents auth events)',
    );
    if (expectedDeletes != null) {
      expect(server.deletes, expectedDeletes, reason: '$name DELETE calls');
    }
  } finally {
    routerSub.close();
    authSub.close();
    // Leave no dialog open for the next case.
    FirebaseAuth.instance.currentUser != null
        ? await FirebaseAuth.instance.signOut()
        : null;
  }
}

Future<void> _tapDelete(WidgetTester tester) =>
    tapText(tester, AppStrings.deleteAccount);

/// Taps the topmost dialog's Delete (dialog buttons need no scrolling).
Future<void> _confirm(WidgetTester tester, {Duration? settle}) async {
  final confirm = find
      .widgetWithText(FilledButton, AppStrings.deleteAccountConfirm)
      .hitTestable();
  await waitFor(tester, confirm);
  await tester.tap(confirm.last);
  await pumpFor(tester, settle ?? const Duration(milliseconds: 500));
}

Future<void> _enterPassword(WidgetTester tester, String password) async {
  await waitFor(tester, find.text(AppStrings.deleteAccountPasswordTitle));
  await typeInto(tester, find.byType(TextField).last, password);
  await _confirm(tester, settle: const Duration(seconds: 2));
}

const _deleted = {_End.deletedOnboarding};

/// Settings > Delete account, 10 ways. Every case must end in exactly one of:
/// deleted and back on onboarding, the password prompt, or a visible error
/// on Settings. Never a silent navigation.
void registerDeleteAccountFlow() {
  qaTest('delete 1: fresh sign-in, server deletes', (tester) async {
    await _deleteCase(
      tester,
      name: '01-fresh',
      replies: const [_ok],
      allowed: _deleted,
      expectedDeletes: 1,
      run: (tester) async {
        await _tapDelete(tester);
        await _confirm(tester);
      },
    );
  });

  qaTest('delete 2: fresh sign-in, slow server (3 s)', (tester) async {
    await _deleteCase(
      tester,
      name: '02-fresh-slow',
      replies: const [_Reply(200, delay: Duration(seconds: 3))],
      allowed: _deleted,
      expectedDeletes: 1,
      run: (tester) async {
        await _tapDelete(tester);
        await _confirm(tester);
        await pumpFor(tester, const Duration(seconds: 4));
      },
    );
  });

  qaTest('delete 3: old sign-in stops at the password prompt', (tester) async {
    await _deleteCase(
      tester,
      name: '03-old-signin-prompt',
      replies: const [_reauth],
      allowed: const {_End.passwordPrompt},
      run: (tester) async {
        await _tapDelete(tester);
        await _confirm(tester, settle: const Duration(seconds: 2));
      },
    );
  });

  qaTest('delete 4: old sign-in, password, server deletes', (tester) async {
    await _deleteCase(
      tester,
      name: '04-old-signin-password',
      replies: const [_reauth, _reauth, _ok],
      allowed: _deleted,
      run: (tester) async {
        await _tapDelete(tester);
        await _confirm(tester, settle: const Duration(seconds: 2));
        await _enterPassword(tester, _qaPassword);
      },
    );
  });

  qaTest('delete 5: old sign-in, wrong password', (tester) async {
    await _deleteCase(
      tester,
      name: '05-old-signin-wrong-password',
      replies: const [_reauth],
      allowed: const {_End.visibleError},
      run: (tester) async {
        await _tapDelete(tester);
        await _confirm(tester, settle: const Duration(seconds: 2));
        await _enterPassword(tester, 'not-the-password');
      },
    );
  });

  qaTest('delete 6: right after a re-authentication', (tester) async {
    await _deleteCase(
      tester,
      name: '06-after-reauth',
      replies: const [_ok],
      allowed: _deleted,
      expectedDeletes: 1,
      run: (tester) async {
        final user = FirebaseAuth.instance.currentUser!;
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email!,
            password: _qaPassword,
          ),
        );
        await pumpFor(tester, const Duration(seconds: 1));
        await _tapDelete(tester);
        await _confirm(tester);
      },
    );
  });

  qaTest('delete 7: double-tap on Delete account', (tester) async {
    await _deleteCase(
      tester,
      name: '07-double-tap-button',
      replies: const [_ok],
      allowed: _deleted,
      expectedDeletes: 1,
      run: (tester) async {
        final button = find.text(AppStrings.deleteAccount);
        await scrollIntoReach(tester, button);
        await tester.tap(button.first);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(button.first, warnIfMissed: false);
        await pumpFor(tester, const Duration(milliseconds: 600));
        expect(
          find.text(AppStrings.deleteAccountTitle),
          findsOneWidget,
          reason: 'a double tap opens one confirm dialog',
        );
        await _confirm(tester);
        // A second confirm dialog, if one opened, must not delete twice.
        final again = find.widgetWithText(
          FilledButton,
          AppStrings.deleteAccountConfirm,
        );
        if (again.evaluate().isNotEmpty) {
          await tester.tap(again.first, warnIfMissed: false);
          await pumpFor(tester, const Duration(seconds: 1));
        }
      },
    );
  });

  qaTest('delete 8: double-tap on the dialog\'s Delete', (tester) async {
    await _deleteCase(
      tester,
      name: '08-double-tap-confirm',
      replies: const [_Reply(200, delay: Duration(milliseconds: 800))],
      allowed: _deleted,
      expectedDeletes: 1,
      run: (tester) async {
        await _tapDelete(tester);
        final confirm = find.widgetWithText(
          FilledButton,
          AppStrings.deleteAccountConfirm,
        );
        await tester.tap(confirm.first);
        await tester.pump(const Duration(milliseconds: 40));
        await tester.tap(confirm.first, warnIfMissed: false);
        await pumpFor(tester, const Duration(seconds: 2));
      },
    );
  });

  qaTest('delete 9: taps while the server call is pending', (tester) async {
    await _deleteCase(
      tester,
      name: '09-tap-during-pending',
      replies: const [_Reply(200, delay: Duration(seconds: 3))],
      allowed: _deleted,
      expectedDeletes: 1,
      run: (tester) async {
        await _tapDelete(tester);
        await _confirm(tester, settle: const Duration(milliseconds: 300));
        for (final text in [
          AppStrings.deleteAccountDeleting,
          AppStrings.deleteAccount,
        ]) {
          final target = find.text(text);
          if (target.evaluate().isNotEmpty) {
            await tester.tap(target.first, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 200));
          }
        }
        await pumpFor(tester, const Duration(seconds: 4));
      },
    );
  });

  qaTest('delete 10: server error stays on Settings', (tester) async {
    await _deleteCase(
      tester,
      name: '10-server-error',
      replies: const [_Reply(500, code: 'internal')],
      allowed: const {_End.visibleError},
      expectedDeletes: 1,
      run: (tester) async {
        await _tapDelete(tester);
        await _confirm(tester, settle: const Duration(seconds: 2));
      },
    );
  });
}

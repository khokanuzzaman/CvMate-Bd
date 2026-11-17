import 'dart:async';

import 'package:careermatebd/features/account_deletion/data/account_deletion_service.dart';
import 'package:careermatebd/features/account_deletion/data/local_data_wipe.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:careermatebd/shared/services/crash/crash_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server path that deletes this user's account: server data, Firestore
/// backup and Firebase Auth user (cvmate-api).
const String deleteMePath = '/v1/me';

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    auth: ref.watch(authRepositoryProvider),
    deleteAccountOnServer: () =>
        ref.read(aiServerClientProvider).deleteJson(deleteMePath),
    billing: ref.watch(billingServiceProvider),
    wipeLocalData: () => wipeLocalCvMateData(ref),
  );
});

class AccountDeletionState {
  const AccountDeletionState({this.isDeleting = false, this.errorMessage});

  final bool isDeleting;
  final String? errorMessage;
}

final accountDeletionControllerProvider =
    NotifierProvider<AccountDeletionController, AccountDeletionState>(
      AccountDeletionController.new,
    );

/// Runs [AccountDeletionService] for the Settings screen and keeps its
/// loading / error state. The screen asks for confirmation first.
class AccountDeletionController extends Notifier<AccountDeletionState> {
  @override
  AccountDeletionState build() => const AccountDeletionState();

  Future<AccountDeletionOutcome> delete() async {
    if (state.isDeleting) {
      return AccountDeletionOutcome.failed;
    }
    state = const AccountDeletionState(isDeleting: true);
    final analytics = ref.read(analyticsServiceProvider);
    final account = ref.read(currentAuthUserProvider) == null
        ? AccountKind.guest
        : AccountKind.signedIn;
    unawaited(analytics.log(AnalyticsEvent.accountDeleteStart(account)));
    final result = await ref.read(accountDeletionServiceProvider).delete();
    await analytics.log(
      AnalyticsEvent.accountDeleteResult(account, switch (result.outcome) {
        AccountDeletionOutcome.deleted => DeleteResult.deleted,
        AccountDeletionOutcome.failed => DeleteResult.failed,
      }),
    );
    if (result.outcome == AccountDeletionOutcome.deleted) {
      // From here on this device is a new, unlinked analytics user.
      await analytics.resetIdentity();
    } else if (result.outcome == AccountDeletionOutcome.failed) {
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordNonFatal(CrashArea.account, 'account_delete_failed'),
      );
    }
    if (ref.mounted) {
      state = AccountDeletionState(
        errorMessage: result.outcome == AccountDeletionOutcome.failed
            ? result.message
            : null,
      );
    }
    return result.outcome;
  }
}

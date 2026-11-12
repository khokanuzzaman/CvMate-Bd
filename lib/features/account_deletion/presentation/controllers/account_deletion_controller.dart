import 'package:careermatebd/features/account_deletion/data/account_deletion_service.dart';
import 'package:careermatebd/features/account_deletion/data/local_data_wipe.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/datasources/cv_remote_data_source.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server path that deletes this user's data (cvmate-api).
const String deleteMePath = '/v1/me';

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    auth: ref.watch(authRepositoryProvider),
    deleteServerData: () =>
        ref.read(aiServerClientProvider).deleteJson(deleteMePath),
    deleteCloudData: (uid) =>
        ref.read(cvRemoteDataSourceProvider).deleteAllForUser(uid),
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
/// loading / error state. The screen asks for confirmation and, when the
/// result is [AccountDeletionOutcome.needsPassword], for the password.
class AccountDeletionController extends Notifier<AccountDeletionState> {
  @override
  AccountDeletionState build() => const AccountDeletionState();

  Future<AccountDeletionOutcome> delete({String? password}) async {
    if (state.isDeleting) {
      return AccountDeletionOutcome.failed;
    }
    state = const AccountDeletionState(isDeleting: true);
    final result = await ref
        .read(accountDeletionServiceProvider)
        .delete(password: password);
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

import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';

/// How a deletion attempt ended.
enum AccountDeletionOutcome {
  /// Everything is gone; the app should go back to onboarding.
  deleted,

  /// The server call failed; [AccountDeletionResult.message] says what to
  /// tell the user. Nothing on this device was touched.
  failed,
}

class AccountDeletionResult {
  const AccountDeletionResult(this.outcome, {this.message});

  final AccountDeletionOutcome outcome;
  final String? message;
}

abstract final class AccountDeletionMessages {
  static const String failed =
      "Couldn't finish deleting your account. Check your connection and try "
      'again; it continues from where it stopped.';
}

/// Deletes the signed-in user's account (App Store guideline 5.1.1(v)):
///
/// 1. one server call (`DELETE /v1/me`), which deletes the user's data on
///    our server, the CV backup in Firestore (`users/{uid}/**`) and the
///    Firebase Auth user, with the Admin SDK;
/// 2. sign-out here (the Auth user is already gone);
/// 3. RevenueCat `logOut()`;
/// 4. all CvMate data on this device.
///
/// The app needs no Firestore access and no fresh sign-in. If the server
/// call fails nothing else happens and the user stays signed in; the server
/// steps are idempotent, so a retry finishes the job. A guest with no
/// account only gets step 4.
class AccountDeletionService {
  AccountDeletionService({
    required this.auth,
    required this.deleteAccountOnServer,
    required this.billing,
    required this.wipeLocalData,
  });

  final AuthRepository auth;
  final Future<void> Function() deleteAccountOnServer;
  final BillingService billing;
  final Future<void> Function() wipeLocalData;

  Future<AccountDeletionResult> delete() async {
    if (auth.currentUser != null) {
      try {
        await deleteAccountOnServer();
      } catch (_) {
        return const AccountDeletionResult(
          AccountDeletionOutcome.failed,
          message: AccountDeletionMessages.failed,
        );
      }
      // Clears the Firebase session on this device. A failure here only
      // leaves a session whose user no longer exists, so carry on.
      await auth.signOut();
      try {
        await billing.logOut();
      } catch (_) {
        // RevenueCat falls back to an anonymous id on its own.
      }
    }
    await wipeLocalData();
    return const AccountDeletionResult(AccountDeletionOutcome.deleted);
  }
}

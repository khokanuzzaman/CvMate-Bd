import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';

/// How a deletion attempt ended.
enum AccountDeletionOutcome {
  /// Everything is gone; the app should go back to onboarding.
  deleted,

  /// Firebase needs a fresh sign-in: ask for the password and call again.
  needsPassword,

  /// A step failed; [AccountDeletionResult.message] says what to tell the user.
  failed,
}

class AccountDeletionResult {
  const AccountDeletionResult(this.outcome, {this.message});

  final AccountDeletionOutcome outcome;
  final String? message;
}

abstract final class AccountDeletionMessages {
  static const String server =
      "Couldn't reach CvMate to delete your account. Nothing was deleted. "
      'Check your connection and try again.';
  static const String cloud =
      "Couldn't delete your CV backup. Please try again; the rest of the "
      'deletion will continue from there.';
  static const String auth =
      "Couldn't delete your sign-in account. Please try again.";
}

/// Deletes the signed-in user's account (App Store guideline 5.1.1(v)), in
/// this order, stopping at the first failure:
///
/// 1. the user's data on our server (`DELETE /v1/me`, needs the token);
/// 2. the CV backup in Firestore (`users/{uid}/**`);
/// 3. the Firebase Auth user;
/// 4. RevenueCat `logOut()`;
/// 5. all CvMate data on this device.
///
/// Every step can run again, so a retry after a failure is safe. A guest
/// with no account only gets step 5. Firebase may first ask for a fresh
/// sign-in ([AccountDeletionOutcome.needsPassword]); that is checked before
/// anything is deleted.
class AccountDeletionService {
  AccountDeletionService({
    required this.auth,
    required this.deleteServerData,
    required this.deleteCloudData,
    required this.billing,
    required this.wipeLocalData,
  });

  final AuthRepository auth;
  final Future<void> Function() deleteServerData;
  final Future<void> Function(String uid) deleteCloudData;
  final BillingService billing;
  final Future<void> Function() wipeLocalData;

  Future<AccountDeletionResult> delete({String? password}) async {
    final user = auth.currentUser;
    if (user == null) {
      await wipeLocalData();
      return const AccountDeletionResult(AccountDeletionOutcome.deleted);
    }

    if (password != null) {
      final reauth = await auth.reauthenticateWithPassword(password);
      final failure = _failureOf(reauth);
      if (failure != null) {
        return AccountDeletionResult(
          AccountDeletionOutcome.failed,
          message: failure.message,
        );
      }
    } else if (auth.needsRecentLogin) {
      return const AccountDeletionResult(AccountDeletionOutcome.needsPassword);
    }

    try {
      await deleteServerData();
    } catch (_) {
      return const AccountDeletionResult(
        AccountDeletionOutcome.failed,
        message: AccountDeletionMessages.server,
      );
    }
    try {
      await deleteCloudData(user.uid);
    } catch (_) {
      return const AccountDeletionResult(
        AccountDeletionOutcome.failed,
        message: AccountDeletionMessages.cloud,
      );
    }

    final deleted = await auth.deleteCurrentUser();
    final failure = _failureOf(deleted);
    if (failure != null) {
      return failure.code == AuthErrorCodes.requiresRecentLogin
          ? const AccountDeletionResult(AccountDeletionOutcome.needsPassword)
          : AccountDeletionResult(
              AccountDeletionOutcome.failed,
              message: failure.message.isEmpty
                  ? AccountDeletionMessages.auth
                  : failure.message,
            );
    }

    try {
      await billing.logOut();
    } catch (_) {
      // RevenueCat falls back to an anonymous id on its own.
    }
    await wipeLocalData();
    return const AccountDeletionResult(AccountDeletionOutcome.deleted);
  }

  static Failure? _failureOf(Result<void> result) => switch (result) {
    FailureResult(:final error) => error,
    Success() => null,
  };
}

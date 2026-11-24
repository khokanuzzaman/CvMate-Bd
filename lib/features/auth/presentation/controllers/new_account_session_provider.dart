import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The uid of the account created on this device in this app session (set
/// by sign-up). In memory on purpose: after a restart it is no longer the
/// account's first session.
final newAccountSessionProvider = NotifierProvider<NewAccountSession, String?>(
  NewAccountSession.new,
);

class NewAccountSession extends Notifier<String?> {
  @override
  String? build() => null;

  void markCreated(String uid) => state = uid;
}

/// True while the signed-in user is the account created in this session,
/// so Home says "Welcome" rather than "Welcome back".
final isNewAccountSessionProvider = Provider<bool>((ref) {
  final createdUid = ref.watch(newAccountSessionProvider);
  final user = ref.watch(currentAuthUserProvider);
  return createdUid != null && user?.uid == createdUid;
});

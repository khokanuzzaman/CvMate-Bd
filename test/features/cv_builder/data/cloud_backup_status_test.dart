import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/cv_cloud_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(() {
      container.dispose();
      auth.dispose();
    });
  });

  test('is off while signed out', () {
    expect(container.read(cloudBackupStatusProvider), CloudBackupStatus.off);
  });

  test('is on once a user (account or guest) is available', () async {
    await auth.signInWithEmailAndPassword(email: 'a@b.co', password: 'pw');
    expect(container.read(cloudBackupStatusProvider), CloudBackupStatus.on);
  });

  test('is on for a guest session', () async {
    await auth.signInAnonymously();
    expect(container.read(cloudBackupStatusProvider), CloudBackupStatus.on);
  });

  test('goes back off after signing out', () async {
    await auth.signInWithEmailAndPassword(email: 'a@b.co', password: 'pw');
    expect(container.read(cloudBackupStatusProvider), CloudBackupStatus.on);

    container.listen(cloudBackupStatusProvider, (_, _) {});
    await auth.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(cloudBackupStatusProvider), CloudBackupStatus.off);
  });
}

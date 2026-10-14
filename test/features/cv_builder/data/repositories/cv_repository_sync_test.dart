import 'dart:io';

import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:careermatebd/features/cv_builder/data/datasources/cv_local_data_source.dart';
import 'package:careermatebd/features/cv_builder/data/datasources/cv_remote_data_source.dart';
import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'cv_profiles_box';

CvProfile _cv({
  required String id,
  required String title,
  required DateTime updatedAt,
}) {
  return CvProfile.empty().copyWith(
    id: id,
    title: title,
    personalInfo: const PersonalInfo(fullName: 'Test User'),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt,
  );
}

Future<void> _flushMirror() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cv_sync_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    final box = await Hive.openBox<String>(_boxName);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  CvRepositoryImpl buildRepository({
    required _FakeRemote remote,
    required AuthRepository auth,
    List<Object>? errors,
  }) {
    return CvRepositoryImpl(
      localDataSource: const CvLocalDataSource(),
      remoteDataSource: remote,
      authRepository: auth,
      onSyncError: errors?.add,
    );
  }

  test('mirror-on-write pushes a saved CV to the remote when signed in', () async {
    final remote = _FakeRemote();
    final repo = buildRepository(remote: remote, auth: _FakeAuth('u1'));

    await repo.saveCv(_cv(id: 'a', title: 'Alpha', updatedAt: DateTime(2024, 5)));
    await _flushMirror();

    expect(remote.store['u1']?.containsKey('a'), isTrue);
    expect(remote.store['u1']!['a']!.profile.title, 'Alpha');
    final local = await repo.getAllCvs();
    expect(local.map((cv) => cv.id), contains('a'));
  });

  test('write works offline: local save succeeds, remote error is captured', () async {
    final errors = <Object>[];
    final remote = _FakeRemote()..failWrites = true;
    final repo = buildRepository(
      remote: remote,
      auth: _FakeAuth('u1'),
      errors: errors,
    );

    await repo.saveCv(_cv(id: 'a', title: 'Alpha', updatedAt: DateTime(2024, 5)));
    await _flushMirror();

    final local = await repo.getAllCvs();
    expect(local.map((cv) => cv.id), contains('a'), reason: 'local must persist');
    expect(errors, isNotEmpty, reason: 'remote error should be captured, not thrown');
  });

  test('signed-out writes never touch the remote', () async {
    final remote = _FakeRemote();
    final repo = buildRepository(remote: remote, auth: _FakeAuth(null));

    await repo.saveCv(_cv(id: 'a', title: 'Alpha', updatedAt: DateTime(2024, 5)));
    await _flushMirror();

    expect(remote.store, isEmpty);
    final local = await repo.getAllCvs();
    expect(local.map((cv) => cv.id), contains('a'));
  });

  test('pullAndReconcile merges remote+local with last-write-wins', () async {
    final remote = _FakeRemote();
    final auth = _FakeAuth('u1');
    final repo = buildRepository(remote: remote, auth: auth);

    // Remote: A (newer) + B (remote-only).
    remote.seed('u1', _cv(id: 'a', title: 'A-remote', updatedAt: DateTime(2024, 6)));
    remote.seed('u1', _cv(id: 'b', title: 'B-remote', updatedAt: DateTime(2024, 6)));
    // Local: A (older) + C (local-only).
    await const CvLocalDataSource().saveCv(
      CvProfileDto(_cv(id: 'a', title: 'A-local', updatedAt: DateTime(2024, 1))),
    );
    await const CvLocalDataSource().saveCv(
      CvProfileDto(_cv(id: 'c', title: 'C-local', updatedAt: DateTime(2024, 3))),
    );

    await repo.pullAndReconcile();

    final localById = {for (final cv in await repo.getAllCvs()) cv.id: cv};
    expect(localById.keys, containsAll(['a', 'b', 'c']));
    expect(localById['a']!.title, 'A-remote', reason: 'remote A was newer (LWW)');
    expect(localById['c']!.title, 'C-local', reason: 'local-only must never be dropped');

    // Local-only C is pushed up; remote keeps everything.
    expect(remote.store['u1']!.keys, containsAll(['a', 'b', 'c']));
    expect(remote.store['u1']!['c']!.profile.title, 'C-local');
  });

  test('pullAndReconcile is a no-op when the remote is unreachable', () async {
    final remote = _FakeRemote()..failReads = true;
    final repo = buildRepository(remote: remote, auth: _FakeAuth('u1'));

    await const CvLocalDataSource().saveCv(
      CvProfileDto(_cv(id: 'c', title: 'C-local', updatedAt: DateTime(2024, 3))),
    );

    await repo.pullAndReconcile(); // must not throw / hang

    final local = await repo.getAllCvs();
    expect(local.map((cv) => cv.id), ['c'], reason: 'local untouched when offline');
  });

  test('anonymous → account upgrade keeps the user CVs (same uid)', () async {
    final remote = _FakeRemote();
    final auth = _FakeAuth('u1', isAnonymous: true);
    final repo = buildRepository(remote: remote, auth: auth);

    // Guest builds a CV; it mirrors to the cloud under the guest uid.
    await repo.saveCv(_cv(id: 'a', title: 'Guest CV', updatedAt: DateTime(2024, 5)));
    await _flushMirror();
    expect(remote.store['u1']?.containsKey('a'), isTrue);

    // Upgrade to a real account: linkWithCredential keeps the SAME uid.
    auth.upgradeToAccount();

    // Simulate a fresh install (empty local) and restore.
    await (await Hive.openBox<String>(_boxName)).clear();
    await repo.pullAndReconcile();

    final local = await repo.getAllCvs();
    expect(local.map((cv) => cv.id), contains('a'));
    expect(local.first.title, 'Guest CV');
  });
}

class _FakeRemote implements CvRemoteDataSource {
  final Map<String, Map<String, CvProfileDto>> store = {};
  bool failWrites = false;
  bool failReads = false;

  void seed(String uid, CvProfile profile) {
    (store[uid] ??= {})[profile.id] = CvProfileDto(profile);
  }

  @override
  Future<void> upsert(String uid, CvProfileDto dto) async {
    if (failWrites) {
      throw Exception('offline');
    }
    (store[uid] ??= {})[dto.profile.id] = dto;
  }

  @override
  Future<void> delete(String uid, String id) async {
    if (failWrites) {
      throw Exception('offline');
    }
    store[uid]?.remove(id);
  }

  @override
  Future<List<CvProfileDto>> fetchAll(String uid) async {
    if (failReads) {
      throw Exception('offline');
    }
    return store[uid]?.values.toList() ?? const [];
  }
}

class _FakeAuth implements AuthRepository {
  _FakeAuth(this._uid, {bool isAnonymous = false}) : _isAnonymous = isAnonymous;

  final String? _uid;
  bool _isAnonymous;

  void upgradeToAccount() => _isAnonymous = false;

  @override
  AuthUser? get currentUser {
    final uid = _uid;
    if (uid == null) {
      return null;
    }
    return AuthUser(
      uid: uid,
      email: _isAnonymous ? '' : 'user@example.com',
      isAnonymous: _isAnonymous,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

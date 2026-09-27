import 'dart:async';

import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/domain/repositories/auth_repository.dart';
import 'package:careermatebd/features/cv_builder/data/datasources/cv_local_data_source.dart';
import 'package:careermatebd/features/cv_builder/data/datasources/cv_remote_data_source.dart';
import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/repositories/cv_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Concrete repository. Exposed separately from [cvRepositoryProvider] so the
/// cloud-sync wiring can call [pullAndReconcile] (not part of the domain
/// [CvRepository] contract) without every fake having to implement it.
final cvRepositoryImplProvider = Provider<CvRepositoryImpl>((ref) {
  return CvRepositoryImpl(
    localDataSource: ref.watch(cvLocalDataSourceProvider),
    remoteDataSource: ref.watch(cvRemoteDataSourceProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final cvRepositoryProvider = Provider<CvRepository>((ref) {
  return ref.watch(cvRepositoryImplProvider);
});

/// Local-first CV repository with an optional Firestore mirror.
///
/// Hive is always the source of truth for reads and offline use. When a user is
/// signed in, writes are additionally mirrored to Firestore fire-and-forget:
/// the local save never waits on the network and any remote error is captured,
/// so the app behaves exactly as before when Firestore is unreachable.
class CvRepositoryImpl implements CvRepository {
  CvRepositoryImpl({
    required CvLocalDataSource localDataSource,
    required CvRemoteDataSource remoteDataSource,
    required AuthRepository authRepository,
    void Function(Object error)? onSyncError,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _authRepository = authRepository,
       _onSyncError = onSyncError;

  final CvLocalDataSource _localDataSource;
  final CvRemoteDataSource _remoteDataSource;
  final AuthRepository _authRepository;
  final void Function(Object error)? _onSyncError;

  String? get _uid => _authRepository.currentUser?.uid;

  @override
  Future<CvProfile> createEmptyCv({String? title}) async {
    final now = DateTime.now();
    final profile = CvProfile.empty().copyWith(
      id: _generateId(),
      title: (title == null || title.trim().isEmpty) ? 'New CV' : title.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await saveCv(profile);
    return profile;
  }

  @override
  Future<void> deleteCv(String id) async {
    await _localDataSource.deleteCv(id);
    _mirror((uid) => _remoteDataSource.delete(uid, id));
  }

  @override
  Future<void> clearAllCvs() {
    // Local-only reset (e.g. sign-out): never propagate a clear to the cloud,
    // so a user's Firestore backup is preserved and can be restored later.
    return _localDataSource.clearAllCvs();
  }

  @override
  Future<CvProfile> duplicateCv(String id) async {
    final source = await getCvById(id);
    if (source == null) {
      throw Exception('CV not found.');
    }

    final now = DateTime.now();
    final duplicated = source.copyWith(
      id: _generateId(),
      title: '${source.displayTitle} Copy',
      createdAt: now,
      updatedAt: now,
    );

    await saveCv(duplicated);
    return duplicated;
  }

  @override
  Future<List<CvProfile>> getAllCvs() async {
    final dtos = await _localDataSource.getAllCvs();
    final profiles = dtos.map((dto) => dto.profile).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return profiles;
  }

  @override
  Future<CvProfile?> getCvById(String id) async {
    final dto = await _localDataSource.getCvById(id);
    return dto?.profile;
  }

  @override
  Future<CvProfile> saveCv(CvProfile profile) async {
    final normalized = profile.copyWith(
      title: profile.displayTitle,
      updatedAt: DateTime.now(),
    );
    final dto = CvProfileDto(normalized);
    await _localDataSource.saveCv(dto);
    _mirror((uid) => _remoteDataSource.upsert(uid, dto));
    return normalized;
  }

  /// Pulls the signed-in user's cloud CVs and reconciles them into Hive, then
  /// pushes any local CVs the cloud is missing or older on. Conflict policy v1:
  /// last-write-wins by `updatedAt`; a local CV without a remote counterpart is
  /// never dropped. No-ops when signed out or when Firestore is unreachable.
  Future<void> pullAndReconcile() async {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    final List<CvProfileDto> remoteDtos;
    try {
      remoteDtos = await _remoteDataSource.fetchAll(uid);
    } catch (error) {
      // Offline / Firestore unreachable → keep working from local only.
      _onSyncError?.call(error);
      return;
    }

    final localById = {
      for (final dto in await _localDataSource.getAllCvs())
        dto.profile.id: dto.profile,
    };
    final remoteById = {for (final dto in remoteDtos) dto.profile.id: dto.profile};

    // Remote -> local: adopt remote entries that are new or newer locally.
    for (final remote in remoteById.values) {
      final local = localById[remote.id];
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        await _localDataSource.saveCv(CvProfileDto(remote));
      }
    }

    // Local -> remote: push local-only or locally-newer entries; never drop a
    // local CV just because the cloud has not seen it yet.
    for (final local in localById.values) {
      final remote = remoteById[local.id];
      if (remote == null || local.updatedAt.isAfter(remote.updatedAt)) {
        try {
          await _remoteDataSource.upsert(uid, CvProfileDto(local));
        } catch (error) {
          _onSyncError?.call(error);
        }
      }
    }
  }

  /// Fire-and-forget cloud mirror: runs only when signed in, never blocks the
  /// local write, and swallows/reports errors so callers cannot hang or crash.
  void _mirror(Future<void> Function(String uid) action) {
    final uid = _uid;
    if (uid == null) {
      return;
    }

    unawaited(
      Future(() => action(uid)).catchError((Object error) {
        _onSyncError?.call(error);
      }),
    );
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

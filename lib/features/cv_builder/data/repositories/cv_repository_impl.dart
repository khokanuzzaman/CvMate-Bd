import 'package:careermatebd/features/cv_builder/data/datasources/cv_local_data_source.dart';
import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/repositories/cv_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cvRepositoryProvider = Provider<CvRepository>((ref) {
  final localDataSource = ref.watch(cvLocalDataSourceProvider);
  return CvRepositoryImpl(localDataSource);
});

class CvRepositoryImpl implements CvRepository {
  const CvRepositoryImpl(this._localDataSource);

  final CvLocalDataSource _localDataSource;

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
  Future<void> deleteCv(String id) {
    return _localDataSource.deleteCv(id);
  }

  @override
  Future<void> clearAllCvs() {
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
    await _localDataSource.saveCv(CvProfileDto(normalized));
    return normalized;
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

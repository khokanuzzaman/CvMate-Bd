import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final cvLocalDataSourceProvider = Provider<CvLocalDataSource>((ref) {
  return const CvLocalDataSource();
});

class CvLocalDataSource {
  const CvLocalDataSource();

  static const String _boxName = 'cv_profiles_box';

  Future<List<CvProfileDto>> getAllCvs() async {
    final box = await _openBox();
    return box.values.map(CvProfileDto.fromJson).toList();
  }

  Future<CvProfileDto?> getCvById(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) {
      return null;
    }

    return CvProfileDto.fromJson(raw);
  }

  Future<void> saveCv(CvProfileDto dto) async {
    final box = await _openBox();
    await box.put(dto.profile.id, dto.toJson());
  }

  Future<void> deleteCv(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearAllCvs() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }

    return Hive.openBox<String>(_boxName);
  }
}

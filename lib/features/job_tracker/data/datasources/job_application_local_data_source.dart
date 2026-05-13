import 'package:careermatebd/features/job_tracker/data/dtos/job_application_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final jobApplicationLocalDataSourceProvider =
    Provider<JobApplicationLocalDataSource>((ref) {
      return const JobApplicationLocalDataSource();
    });

class JobApplicationLocalDataSource {
  const JobApplicationLocalDataSource();

  static const String _boxName = 'job_applications_box';

  Future<List<JobApplicationDto>> getAllApplications() async {
    final box = await _openBox();
    return box.values.map(JobApplicationDto.fromJson).toList();
  }

  Future<JobApplicationDto?> getApplicationById(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) {
      return null;
    }

    return JobApplicationDto.fromJson(raw);
  }

  Future<void> saveApplication(JobApplicationDto dto) async {
    final box = await _openBox();
    await box.put(dto.application.id, dto.toJson());
  }

  Future<void> deleteApplication(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearAllApplications() async {
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

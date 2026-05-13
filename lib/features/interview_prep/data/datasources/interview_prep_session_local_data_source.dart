import 'dart:convert';

import 'package:careermatebd/features/interview_prep/data/dtos/interview_prep_session_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final interviewPrepSessionLocalDataSourceProvider =
    Provider<InterviewPrepSessionLocalDataSource>((ref) {
      return const InterviewPrepSessionLocalDataSource();
    });

class InterviewPrepSessionLocalDataSource {
  const InterviewPrepSessionLocalDataSource();

  static const String _boxName = 'interview_prep_sessions_box';

  Future<List<InterviewPrepSessionDto>> getAllSessions() async {
    final box = await _openBox();
    return box.values.map(InterviewPrepSessionDto.fromJson).toList();
  }

  Future<InterviewPrepSessionDto?> getSessionById(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) {
      return null;
    }

    return InterviewPrepSessionDto.fromJson(raw);
  }

  Future<void> saveSession(InterviewPrepSessionDto dto) async {
    final box = await _openBox();
    await box.put(dto.session.id, jsonEncode(dto.toJson()));
  }

  Future<void> clearAllSessions() async {
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

import 'package:careermatebd/features/cover_letter/data/dtos/cover_letter_draft_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final coverLetterLocalDataSourceProvider = Provider<CoverLetterLocalDataSource>(
  (ref) {
    return const CoverLetterLocalDataSource();
  },
);

class CoverLetterLocalDataSource {
  const CoverLetterLocalDataSource();

  static const String _boxName = 'cover_letter_drafts_box';

  Future<List<CoverLetterDraftDto>> getAllDrafts() async {
    final box = await _openBox();
    return box.values.map(CoverLetterDraftDto.fromJson).toList();
  }

  Future<CoverLetterDraftDto?> getDraftById(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) {
      return null;
    }

    return CoverLetterDraftDto.fromJson(raw);
  }

  Future<void> saveDraft(CoverLetterDraftDto dto) async {
    final box = await _openBox();
    await box.put(dto.draft.id, dto.toJson());
  }

  Future<void> deleteDraft(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<void> clearAllDrafts() async {
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

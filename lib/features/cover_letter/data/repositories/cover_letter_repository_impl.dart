import 'package:careermatebd/features/cover_letter/data/datasources/cover_letter_local_data_source.dart';
import 'package:careermatebd/features/cover_letter/data/dtos/cover_letter_draft_dto.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/repositories/cover_letter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coverLetterRepositoryProvider = Provider<CoverLetterRepository>((ref) {
  final localDataSource = ref.watch(coverLetterLocalDataSourceProvider);
  return CoverLetterRepositoryImpl(localDataSource);
});

class CoverLetterRepositoryImpl implements CoverLetterRepository {
  const CoverLetterRepositoryImpl(this._localDataSource);

  final CoverLetterLocalDataSource _localDataSource;

  @override
  Future<void> deleteDraft(String id) {
    return _localDataSource.deleteDraft(id);
  }

  @override
  Future<void> clearAllDrafts() {
    return _localDataSource.clearAllDrafts();
  }

  @override
  Future<List<CoverLetterDraft>> getAllDrafts() async {
    final dtos = await _localDataSource.getAllDrafts();
    final drafts = dtos.map((dto) => dto.draft).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  @override
  Future<CoverLetterDraft?> getDraftById(String id) async {
    final dto = await _localDataSource.getDraftById(id);
    return dto?.draft;
  }

  @override
  Future<CoverLetterDraft> saveDraft(CoverLetterDraft draft) async {
    final now = DateTime.now();
    final normalized = draft.copyWith(
      updatedAt: now,
      createdAt: draft.createdAt,
    );
    await _localDataSource.saveDraft(CoverLetterDraftDto(normalized));
    return normalized;
  }
}

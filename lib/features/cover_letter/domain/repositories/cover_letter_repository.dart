import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';

abstract class CoverLetterRepository {
  Future<List<CoverLetterDraft>> getAllDrafts();

  Future<CoverLetterDraft?> getDraftById(String id);

  Future<CoverLetterDraft> saveDraft(CoverLetterDraft draft);

  Future<void> deleteDraft(String id);

  Future<void> clearAllDrafts();
}

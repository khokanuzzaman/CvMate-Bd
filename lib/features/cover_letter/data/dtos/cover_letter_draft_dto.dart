import 'dart:convert';

import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class CoverLetterDraftDto {
  const CoverLetterDraftDto(this.draft);

  final CoverLetterDraft draft;

  factory CoverLetterDraftDto.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return CoverLetterDraftDto(_fromMap(map));
  }

  String toJson() => jsonEncode(_toMap(draft));

  static CoverLetterDraft _fromMap(Map<String, dynamic> map) {
    return CoverLetterDraft(
      id: map['id'] as String? ?? '',
      userId: _optionalString(map['userId']),
      cvId: _optionalString(map['cvId']),
      targetCompany: map['targetCompany'] as String? ?? '',
      jobTitle: map['jobTitle'] as String? ?? '',
      jobDetails: map['jobDetails'] as String? ?? '',
      hiringManagerName: map['hiringManagerName'] as String? ?? '',
      candidateSummary: map['candidateSummary'] as String? ?? '',
      outputType: CoverLetterOutputType.values.firstWhere(
        (value) => value.name == map['outputType'],
        orElse: () => CoverLetterOutputType.formalCoverLetter,
      ),
      language: switch ((map['language'] as String? ?? '')
          .trim()
          .toLowerCase()) {
        'bangla' => AiOutputLanguage.bangla,
        _ => AiOutputLanguage.english,
      },
      tone: switch ((map['tone'] as String? ?? '').trim().toLowerCase()) {
        'simple' => AiTone.simple,
        'confident' => AiTone.confident,
        'professional' => AiTone.professional,
        _ => AiTone.formal,
      },
      subjectLine: map['subjectLine'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> _toMap(CoverLetterDraft draft) {
    return {
      'id': draft.id,
      'userId': draft.userId,
      'cvId': draft.cvId,
      'targetCompany': draft.targetCompany,
      'jobTitle': draft.jobTitle,
      'jobDetails': draft.jobDetails,
      'hiringManagerName': draft.hiringManagerName,
      'candidateSummary': draft.candidateSummary,
      'outputType': draft.outputType.name,
      'language': draft.language.code,
      'tone': draft.tone.code,
      'subjectLine': draft.subjectLine,
      'content': draft.content,
      'createdAt': draft.createdAt.toIso8601String(),
      'updatedAt': draft.updatedAt.toIso8601String(),
    };
  }

  static String? _optionalString(Object? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}

import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_output_type.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

const Object _fieldUnset = Object();

class CoverLetterDraft {
  const CoverLetterDraft({
    required this.id,
    required this.userId,
    required this.cvId,
    required this.targetCompany,
    required this.jobTitle,
    required this.jobDetails,
    required this.hiringManagerName,
    required this.candidateSummary,
    required this.outputType,
    required this.language,
    required this.tone,
    required this.subjectLine,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? userId;
  final String? cvId;
  final String targetCompany;
  final String jobTitle;
  final String jobDetails;
  final String hiringManagerName;
  final String candidateSummary;
  final CoverLetterOutputType outputType;
  final AiOutputLanguage language;
  final AiTone tone;
  final String subjectLine;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CoverLetterDraft.empty() {
    final now = DateTime.now();
    return CoverLetterDraft(
      id: now.microsecondsSinceEpoch.toString(),
      userId: null,
      cvId: null,
      targetCompany: '',
      jobTitle: '',
      jobDetails: '',
      hiringManagerName: '',
      candidateSummary: '',
      outputType: CoverLetterOutputType.formalCoverLetter,
      language: AiOutputLanguage.english,
      tone: AiTone.formal,
      subjectLine: '',
      content: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  CoverLetterDraft copyWith({
    String? id,
    Object? userId = _fieldUnset,
    Object? cvId = _fieldUnset,
    String? targetCompany,
    String? jobTitle,
    String? jobDetails,
    String? hiringManagerName,
    String? candidateSummary,
    CoverLetterOutputType? outputType,
    AiOutputLanguage? language,
    AiTone? tone,
    String? subjectLine,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoverLetterDraft(
      id: id ?? this.id,
      userId: identical(userId, _fieldUnset) ? this.userId : userId as String?,
      cvId: identical(cvId, _fieldUnset) ? this.cvId : cvId as String?,
      targetCompany: targetCompany ?? this.targetCompany,
      jobTitle: jobTitle ?? this.jobTitle,
      jobDetails: jobDetails ?? this.jobDetails,
      hiringManagerName: hiringManagerName ?? this.hiringManagerName,
      candidateSummary: candidateSummary ?? this.candidateSummary,
      outputType: outputType ?? this.outputType,
      language: language ?? this.language,
      tone: tone ?? this.tone,
      subjectLine: subjectLine ?? this.subjectLine,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasContent => content.trim().isNotEmpty;

  String get displayTitle {
    final company = targetCompany.trim();
    final role = jobTitle.trim();
    if (role.isNotEmpty && company.isNotEmpty) {
      return '$role at $company';
    }
    if (role.isNotEmpty) {
      return role;
    }
    if (company.isNotEmpty) {
      return company;
    }
    return outputType.label;
  }

  String get previewText {
    final value = content.trim();
    if (value.isEmpty) {
      return 'Draft content will appear here after generation.';
    }
    if (value.length <= 140) {
      return value;
    }
    return '${value.substring(0, 140).trimRight()}...';
  }
}

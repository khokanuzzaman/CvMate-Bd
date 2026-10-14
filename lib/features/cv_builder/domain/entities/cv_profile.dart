import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_declaration.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';

class CvProfile {
  const CvProfile({
    required this.id,
    required this.title,
    required this.personalInfo,
    required this.professionalSummary,
    required this.careerObjective,
    required this.education,
    required this.experiences,
    required this.skills,
    required this.projects,
    required this.trainings,
    required this.languages,
    required this.template,
    required this.createdAt,
    required this.updatedAt,
    this.sectionLayout,
    this.customSections = const [],
    this.style = CvStyle.international,
    this.paperSize = PaperSize.a4,
    this.shownFields = const {},
    this.details = const PersonalDetails(),
    this.declaration = const CvDeclaration(),
    this.photo,
    this.signature,
  });

  final String id;
  final String title;
  final PersonalInfo personalInfo;
  final String professionalSummary;
  final String careerObjective;
  final List<EducationInfo> education;
  final List<ExperienceInfo> experiences;
  final List<SkillInfo> skills;
  final List<ProjectInfo> projects;
  final List<TrainingInfo> trainings;
  final List<LanguageInfo> languages;
  final CvTemplate template;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The user's section order / visibility / renames, or null when they never
  /// changed it (then the template's default order applies, as it always did).
  /// Read it through [sections], which cleans it up.
  final List<SectionConfig>? sectionLayout;

  /// Sections the user added. Their position and visibility live in
  /// [sectionLayout].
  final List<CustomSection> customSections;

  /// The market this CV is written for. A new or old CV is international: no
  /// photo and no personal details.
  final CvStyle style;
  final PaperSize paperSize;

  /// The optional personal fields (and declaration / signature) that are
  /// printed. The data behind a hidden field is kept.
  final Set<PersonalField> shownFields;

  /// Optional personal details. Never sent to the AI or read by the ATS check.
  final PersonalDetails details;
  final CvDeclaration declaration;

  /// Passport-ratio (35x45) JPEG, and the signature PNG.
  final Uint8List? photo;
  final Uint8List? signature;

  bool isFieldShown(PersonalField field) => shownFields.contains(field);

  /// The photo, only when it is both added and switched on.
  Uint8List? get photoToShow =>
      isFieldShown(PersonalField.photo) ? photo : null;

  Uint8List? get signatureToShow =>
      isFieldShown(PersonalField.signature) ? signature : null;

  bool get showDeclaration => isFieldShown(PersonalField.declaration);

  factory CvProfile.empty() => CvProfile(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    title: 'New CV',
    personalInfo: PersonalInfo.empty(),
    professionalSummary: '',
    careerObjective: '',
    education: const [],
    experiences: const [],
    skills: const [],
    projects: const [],
    trainings: const [],
    languages: const [],
    template: CvTemplate.professional,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  CvProfile copyWith({
    String? id,
    String? title,
    PersonalInfo? personalInfo,
    String? professionalSummary,
    String? careerObjective,
    List<EducationInfo>? education,
    List<ExperienceInfo>? experiences,
    List<SkillInfo>? skills,
    List<ProjectInfo>? projects,
    List<TrainingInfo>? trainings,
    List<LanguageInfo>? languages,
    CvTemplate? template,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SectionConfig>? sectionLayout,
    bool clearSectionLayout = false,
    List<CustomSection>? customSections,
    CvStyle? style,
    PaperSize? paperSize,
    Set<PersonalField>? shownFields,
    PersonalDetails? details,
    CvDeclaration? declaration,
    Uint8List? photo,
    bool clearPhoto = false,
    Uint8List? signature,
    bool clearSignature = false,
  }) {
    return CvProfile(
      id: id ?? this.id,
      title: title ?? this.title,
      personalInfo: personalInfo ?? this.personalInfo,
      professionalSummary: professionalSummary ?? this.professionalSummary,
      careerObjective: careerObjective ?? this.careerObjective,
      education: education ?? this.education,
      experiences: experiences ?? this.experiences,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      trainings: trainings ?? this.trainings,
      languages: languages ?? this.languages,
      template: template ?? this.template,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sectionLayout: clearSectionLayout
          ? null
          : sectionLayout ?? this.sectionLayout,
      customSections: customSections ?? this.customSections,
      style: style ?? this.style,
      paperSize: paperSize ?? this.paperSize,
      shownFields: shownFields ?? this.shownFields,
      details: details ?? this.details,
      declaration: declaration ?? this.declaration,
      photo: clearPhoto ? null : photo ?? this.photo,
      signature: clearSignature ? null : signature ?? this.signature,
    );
  }

  /// The render order: [sectionLayout] cleaned against [customSections]
  /// (every section once, nothing dangling), or the template default.
  List<SectionConfig> get sections => CvSectionLayout.resolve(
    stored: sectionLayout,
    customs: customSections,
    template: template,
  );

  /// [sections] joined with their custom content, hidden ones included.
  List<CvSection> get resolvedSections {
    final customById = {for (final custom in customSections) custom.id: custom};
    return [
      for (final config in sections)
        CvSection(config: config, custom: customById[config.id]),
    ];
  }

  /// What renderers print: the visible sections, in order.
  List<CvSection> get visibleSections => [
    for (final section in resolvedSections)
      if (section.visible) section,
  ];

  /// Whether the built-in [kind] is shown. A hidden section is neither printed
  /// nor scored as missing content.
  bool isSectionVisible(CvSectionKind kind) {
    for (final config in sections) {
      if (config.kind == kind) {
        return config.visible;
      }
    }
    return true;
  }

  /// The text of every visible custom section, for ATS / AI scoring.
  String get visibleCustomText => [
    for (final section in visibleSections)
      if (section.custom != null) section.custom!.plainText,
  ].where((text) => text.trim().isNotEmpty).join(' ');

  CustomSection? customSectionById(String id) {
    for (final custom in customSections) {
      if (custom.id == id) {
        return custom;
      }
    }
    return null;
  }

  String get displayTitle {
    final value = title.trim();
    if (value.isNotEmpty) {
      return value;
    }

    final name = personalInfo.fullName.trim();
    if (name.isNotEmpty) {
      return '$name CV';
    }

    return 'Untitled CV';
  }

  String get displayName {
    final name = personalInfo.fullName.trim();
    return name.isEmpty ? 'Untitled CV' : name;
  }

  String get displayRole {
    final role = personalInfo.desiredRole.trim();
    return role.isEmpty ? 'Career profile in progress' : role;
  }

  bool get hasContent =>
      !personalInfo.isEmpty ||
      professionalSummary.trim().isNotEmpty ||
      careerObjective.trim().isNotEmpty ||
      education.isNotEmpty ||
      experiences.isNotEmpty ||
      skills.isNotEmpty ||
      projects.isNotEmpty ||
      trainings.isNotEmpty ||
      languages.isNotEmpty ||
      customSections.any((section) => section.hasContent);
}

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
    );
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
      languages.isNotEmpty;
}

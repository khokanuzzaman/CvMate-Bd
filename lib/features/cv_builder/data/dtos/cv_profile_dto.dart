import 'dart:convert';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';

class CvProfileDto {
  const CvProfileDto(this.profile);

  final CvProfile profile;

  factory CvProfileDto.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return CvProfileDto(_fromMap(map));
  }

  /// Builds a DTO from a decoded map (e.g. a Firestore document). Uses the exact
  /// same field format as [fromJson]/[toJson] — no second serialization scheme.
  factory CvProfileDto.fromMap(Map<String, dynamic> map) =>
      CvProfileDto(_fromMap(map));

  String toJson() => jsonEncode(_toMap(profile));

  /// The same map [toJson] encodes, but left as a map for map-based stores like
  /// Firestore. Reuses the shared [_toMap] so both stores stay in sync.
  Map<String, dynamic> toMap() => _toMap(profile);

  static CvProfile _fromMap(Map<String, dynamic> map) {
    return CvProfile(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled CV',
      personalInfo: _personalInfoFromMap(
        map['personalInfo'] as Map<String, dynamic>? ?? const {},
      ),
      professionalSummary: map['professionalSummary'] as String? ?? '',
      careerObjective: map['careerObjective'] as String? ?? '',
      education: (map['education'] as List<dynamic>? ?? const [])
          .map((item) => _educationFromMap(item as Map<String, dynamic>))
          .toList(),
      experiences: (map['experiences'] as List<dynamic>? ?? const [])
          .map((item) => _experienceFromMap(item as Map<String, dynamic>))
          .toList(),
      skills: (map['skills'] as List<dynamic>? ?? const [])
          .map((item) => _skillFromMap(item as Map<String, dynamic>))
          .toList(),
      projects: (map['projects'] as List<dynamic>? ?? const [])
          .map((item) => _projectFromMap(item as Map<String, dynamic>))
          .toList(),
      trainings: (map['trainings'] as List<dynamic>? ?? const [])
          .map((item) => _trainingFromMap(item as Map<String, dynamic>))
          .toList(),
      languages: (map['languages'] as List<dynamic>? ?? const [])
          .map((item) => _languageFromMap(item as Map<String, dynamic>))
          .toList(),
      template: CvTemplate.values.firstWhere(
        (value) => value.name == map['template'],
        orElse: () => CvTemplate.professional,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> _toMap(CvProfile profile) {
    return {
      'id': profile.id,
      'title': profile.title,
      'personalInfo': _personalInfoToMap(profile.personalInfo),
      'professionalSummary': profile.professionalSummary,
      'careerObjective': profile.careerObjective,
      'education': profile.education.map(_educationToMap).toList(),
      'experiences': profile.experiences.map(_experienceToMap).toList(),
      'skills': profile.skills.map(_skillToMap).toList(),
      'projects': profile.projects.map(_projectToMap).toList(),
      'trainings': profile.trainings.map(_trainingToMap).toList(),
      'languages': profile.languages.map(_languageToMap).toList(),
      'template': profile.template.name,
      'createdAt': profile.createdAt.toIso8601String(),
      'updatedAt': profile.updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> _personalInfoToMap(PersonalInfo value) => {
    'fullName': value.fullName,
    'desiredRole': value.desiredRole,
    'email': value.email,
    'phone': value.phone,
    'address': value.address,
    'linkedInUrl': value.linkedInUrl,
    'portfolioUrl': value.portfolioUrl,
  };

  static PersonalInfo _personalInfoFromMap(Map<String, dynamic> map) =>
      PersonalInfo(
        fullName: map['fullName'] as String? ?? '',
        desiredRole: map['desiredRole'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        linkedInUrl: map['linkedInUrl'] as String? ?? '',
        portfolioUrl: map['portfolioUrl'] as String? ?? '',
      );

  static Map<String, dynamic> _educationToMap(EducationInfo value) => {
    'id': value.id,
    'institution': value.institution,
    'degree': value.degree,
    'fieldOfStudy': value.fieldOfStudy,
    'startYear': value.startYear,
    'endYear': value.endYear,
    'result': value.result,
    'location': value.location,
    'isOngoing': value.isOngoing,
  };

  static EducationInfo _educationFromMap(Map<String, dynamic> map) =>
      EducationInfo(
        id: map['id'] as String? ?? '',
        institution: map['institution'] as String? ?? '',
        degree: map['degree'] as String? ?? '',
        fieldOfStudy: map['fieldOfStudy'] as String? ?? '',
        startYear: map['startYear'] as String? ?? '',
        endYear: map['endYear'] as String? ?? '',
        result: map['result'] as String? ?? '',
        location: map['location'] as String? ?? '',
        isOngoing: map['isOngoing'] as bool? ?? false,
      );

  static Map<String, dynamic> _experienceToMap(ExperienceInfo value) => {
    'id': value.id,
    'companyName': value.companyName,
    'jobTitle': value.jobTitle,
    'location': value.location,
    'startDate': value.startDate,
    'endDate': value.endDate,
    'isCurrentRole': value.isCurrentRole,
    'highlights': value.highlights,
  };

  static ExperienceInfo _experienceFromMap(Map<String, dynamic> map) =>
      ExperienceInfo(
        id: map['id'] as String? ?? '',
        companyName: map['companyName'] as String? ?? '',
        jobTitle: map['jobTitle'] as String? ?? '',
        location: map['location'] as String? ?? '',
        startDate: map['startDate'] as String? ?? '',
        endDate: map['endDate'] as String? ?? '',
        isCurrentRole: map['isCurrentRole'] as bool? ?? false,
        highlights: (map['highlights'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
      );

  static Map<String, dynamic> _skillToMap(SkillInfo value) => {
    'id': value.id,
    'name': value.name,
    'level': value.level,
  };

  static SkillInfo _skillFromMap(Map<String, dynamic> map) => SkillInfo(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    level: map['level'] as String? ?? '',
  );

  static Map<String, dynamic> _projectToMap(ProjectInfo value) => {
    'id': value.id,
    'title': value.title,
    'role': value.role,
    'description': value.description,
    'technologies': value.technologies,
    'link': value.link,
  };

  static ProjectInfo _projectFromMap(Map<String, dynamic> map) => ProjectInfo(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    role: map['role'] as String? ?? '',
    description: map['description'] as String? ?? '',
    technologies: (map['technologies'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(),
    link: map['link'] as String? ?? '',
  );

  static Map<String, dynamic> _trainingToMap(TrainingInfo value) => {
    'id': value.id,
    'title': value.title,
    'organization': value.organization,
    'completionYear': value.completionYear,
    'details': value.details,
  };

  static TrainingInfo _trainingFromMap(Map<String, dynamic> map) =>
      TrainingInfo(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        organization: map['organization'] as String? ?? '',
        completionYear: map['completionYear'] as String? ?? '',
        details: map['details'] as String? ?? '',
      );

  static Map<String, dynamic> _languageToMap(LanguageInfo value) => {
    'id': value.id,
    'name': value.name,
    'proficiency': value.proficiency,
  };

  static LanguageInfo _languageFromMap(Map<String, dynamic> map) =>
      LanguageInfo(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        proficiency: map['proficiency'] as String? ?? '',
      );
}

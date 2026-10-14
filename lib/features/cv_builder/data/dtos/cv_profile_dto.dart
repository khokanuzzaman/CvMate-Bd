import 'dart:convert';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
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

  /// Version of the stored shape (Hive JSON and Firestore documents share it).
  ///
  /// - missing / 1: before section layouts. Read as the template's default
  ///   order, everything visible, no custom sections.
  /// - 2: adds `sectionLayout` and `customSections`.
  ///
  /// Changes are additive: every field older versions read is still written
  /// unchanged, and unknown keys are ignored on read, so an older app reading a
  /// newer document still sees a complete CV (it just won't show the custom
  /// sections or the custom order).
  static const int schemaVersion = 2;

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
      sectionLayout: _sectionLayoutFromObject(map['sectionLayout']),
      customSections: _customSectionsFromObject(map['customSections']),
    );
  }

  static Map<String, dynamic> _toMap(CvProfile profile) {
    return {
      'schemaVersion': schemaVersion,
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
      // Only written once the user customised the layout, so an untouched CV
      // keeps following its template's default order.
      if (profile.sectionLayout != null)
        'sectionLayout': profile.sectionLayout!
            .map(_sectionConfigToMap)
            .toList(),
      'customSections': profile.customSections
          .map(_customSectionToMap)
          .toList(),
    };
  }

  // --- Section layout --------------------------------------------------------
  // Everything below tolerates missing, mistyped or unknown data and falls back
  // to defaults: reading an old or odd document must never throw.

  static Map<String, dynamic> _sectionConfigToMap(SectionConfig value) => {
    'id': value.id,
    'kind': value.kind.name,
    if (value.cleanTitleOverride != null)
      'titleOverride': value.cleanTitleOverride,
    'visible': value.visible,
  };

  static List<SectionConfig>? _sectionLayoutFromObject(Object? raw) {
    if (raw is! List) {
      return null;
    }
    final configs = <SectionConfig>[];
    for (final entry in raw) {
      final map = _asStringMap(entry);
      final kind = CvSectionKind.tryParse(map?['kind']);
      if (map == null || kind == null) {
        continue; // unknown kind (from a newer app) or not an object
      }
      final id = map['id'];
      final titleOverride = map['titleOverride'];
      configs.add(
        SectionConfig(
          id: id is String && id.isNotEmpty ? id : kind.name,
          kind: kind,
          titleOverride: titleOverride is String ? titleOverride : null,
          visible: map['visible'] is bool ? map['visible'] as bool : true,
        ),
      );
    }
    // An empty or wholly unreadable list means "no custom layout".
    return configs.isEmpty ? null : configs;
  }

  static Map<String, dynamic> _customSectionToMap(CustomSection value) => {
    'id': value.id,
    'title': value.title,
    'layout': value.layout.name,
    'items': value.items.map(_customItemToMap).toList(),
  };

  static Map<String, dynamic> _customItemToMap(CustomSectionItem value) => {
    'id': value.id,
    'title': value.title,
    'description': value.description,
  };

  static List<CustomSection> _customSectionsFromObject(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final sections = <CustomSection>[];
    final seenIds = <String>{};
    for (final entry in raw) {
      final map = _asStringMap(entry);
      if (map == null) {
        continue;
      }
      final id = map['id'];
      if (id is! String || id.isEmpty || !seenIds.add(id)) {
        continue; // a section without a usable, unique id cannot be referenced
      }
      final rawItems = map['items'];
      sections.add(
        CustomSection(
          id: id,
          title: map['title'] is String ? map['title'] as String : '',
          layout: CustomSectionLayout.parse(map['layout']),
          items: [
            if (rawItems is List)
              for (final (index, item) in rawItems.indexed)
                if (_asStringMap(item) case final itemMap?)
                  CustomSectionItem(
                    id:
                        itemMap['id'] is String &&
                            (itemMap['id'] as String).isNotEmpty
                        ? itemMap['id'] as String
                        : '$id-item-$index',
                    title: itemMap['title'] is String
                        ? itemMap['title'] as String
                        : '',
                    description: itemMap['description'] is String
                        ? itemMap['description'] as String
                        : '',
                  ),
          ],
        ),
      );
    }
    return sections;
  }

  /// A decoded JSON object, whatever concrete map type the store produced.
  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return {
        for (final entry in value.entries) entry.key.toString(): entry.value,
      };
    }
    return null;
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

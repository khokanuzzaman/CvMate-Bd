import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

/// Builds the request body the AI server expects for every action:
/// `{action, language, tone, cvData?, inputText?, jobPost?, metadata?}`.
///
/// Only whitelisted CV fields are serialized. Passport number, date of birth,
/// religion, marital status, gender and the photo are never part of it (the
/// server drops them too, as a second line of defence).
abstract final class AiRequestPayload {
  static Map<String, dynamic> build({
    required String action,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    CvProfile? profile,
    String inputText = '',
    String jobPost = '',
    Map<String, dynamic>? metadata,
  }) {
    return {
      'action': action,
      'language': language.code,
      'tone': tone.code,
      if (profile != null) 'cvData': serializeCvProfile(profile),
      if (inputText.trim().isNotEmpty) 'inputText': inputText.trim(),
      if (jobPost.trim().isNotEmpty) 'jobPost': jobPost.trim(),
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  static Map<String, dynamic> serializeCvProfile(CvProfile profile) {
    return {
      'title': profile.title.trim(),
      'desiredRole': profile.personalInfo.desiredRole.trim(),
      'professionalSummary': profile.professionalSummary.trim(),
      'careerObjective': profile.careerObjective.trim(),
      'education': [
        for (final education in profile.education)
          {
            'institution': education.institution.trim(),
            'degree': education.degree.trim(),
            'fieldOfStudy': education.fieldOfStudy.trim(),
            'result': education.result.trim(),
            'startYear': education.startYear.trim(),
            'endYear': education.endYear.trim(),
          },
      ],
      'experiences': [
        for (final experience in profile.experiences)
          {
            // Tailoring returns rewritten bullets keyed by this id.
            'id': experience.id,
            'companyName': experience.companyName.trim(),
            'jobTitle': experience.jobTitle.trim(),
            'startDate': experience.startDate.trim(),
            'endDate': experience.endDate.trim(),
            'isCurrentRole': experience.isCurrentRole,
            'highlights': _nonEmpty(experience.highlights),
          },
      ],
      'skills': [
        for (final skill in profile.skills)
          {'name': skill.name.trim(), 'level': skill.level.trim()},
      ],
      'projects': [
        for (final project in profile.projects)
          {
            'title': project.title.trim(),
            'role': project.role.trim(),
            'description': project.description.trim(),
            'technologies': _nonEmpty(project.technologies),
          },
      ],
      'trainings': [
        for (final training in profile.trainings)
          {
            'title': training.title.trim(),
            'organization': training.organization.trim(),
            'completionYear': training.completionYear.trim(),
            'details': training.details.trim(),
          },
      ],
      'languages': [
        for (final language in profile.languages)
          {
            'name': language.name.trim(),
            'proficiency': language.proficiency.trim(),
          },
      ],
      // The user's own visible sections; omitted when there are none so the
      // payload for an ordinary CV is unchanged.
      if (profile.visibleSections.any((s) => s.custom?.hasContent ?? false))
        'customSections': [
          for (final section in profile.visibleSections)
            if (section.custom != null && section.custom!.hasContent)
              {
                'title': section.titleOr(section.custom!.title).trim(),
                'items': [
                  for (final item in section.custom!.filledItems)
                    {
                      'title': item.title.trim(),
                      'description': item.description.trim(),
                    },
                ],
              },
        ],
    };
  }

  static List<String> _nonEmpty(List<String> values) => values
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

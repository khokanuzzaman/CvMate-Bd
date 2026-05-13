import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';

class CvBuilderValidators {
  const CvBuilderValidators._();

  static String? validateStep(CvBuilderStep step, CvProfile draft) {
    return switch (step) {
      CvBuilderStep.personalInfo => validatePersonalInfo(
        draft.personalInfo,
        cvTitle: draft.title,
      ),
      CvBuilderStep.summaryObjective => validateSummary(
        professionalSummary: draft.professionalSummary,
        careerObjective: draft.careerObjective,
      ),
      CvBuilderStep.education => validateEducation(draft.education),
      CvBuilderStep.experience => validateExperience(draft.experiences),
      CvBuilderStep.skills => validateSkills(draft.skills),
      CvBuilderStep.projects => validateProjects(draft.projects),
      CvBuilderStep.training => validateTrainings(draft.trainings),
      CvBuilderStep.languages => validateLanguages(draft.languages),
      CvBuilderStep.template => null,
      CvBuilderStep.preview => validatePreview(draft),
    };
  }

  static String? validatePreview(CvProfile draft) {
    for (final step in CvBuilderStep.values) {
      if (step.isPreview) {
        continue;
      }

      final error = validateStep(step, draft);
      if (error != null) {
        return error;
      }
    }

    return null;
  }

  static List<String> buildPreviewWarnings(CvProfile draft) {
    final warnings = <String>[];

    if (draft.experiences.isEmpty) {
      warnings.add(
        'No experience added yet. That is acceptable for freshers, but projects should be strong.',
      );
    }

    if (draft.projects.isEmpty) {
      warnings.add(
        'Projects are empty. Adding one or two projects can strengthen a fresher CV.',
      );
    }

    if (draft.trainings.isEmpty) {
      warnings.add(
        'No training or certifications added. Skip if not relevant, otherwise include recent courses.',
      );
    }

    if (draft.languages.isEmpty) {
      warnings.add(
        'Languages are empty. Most applicants should mention Bangla and English proficiency clearly.',
      );
    }

    return warnings;
  }

  static String? validatePersonalInfo(
    PersonalInfo info, {
    String cvTitle = '',
  }) {
    final titleError = Validators.requiredText(cvTitle, fieldName: 'CV title');
    if (titleError != null) {
      return titleError;
    }

    final fullNameError = Validators.requiredText(
      info.fullName,
      fieldName: 'Full name',
    );
    if (fullNameError != null) {
      return fullNameError;
    }

    final roleError = Validators.requiredText(
      info.desiredRole,
      fieldName: 'Target role',
    );
    if (roleError != null) {
      return roleError;
    }

    final emailError = Validators.email(info.email);
    if (emailError != null) {
      return emailError;
    }

    final phoneError = Validators.bangladeshPhone(info.phone);
    if (phoneError != null) {
      return phoneError;
    }

    final addressError = Validators.requiredText(
      info.address,
      fieldName: 'Address',
    );
    if (addressError != null) {
      return addressError;
    }

    final linkedInError = Validators.optionalUrl(info.linkedInUrl);
    if (linkedInError != null) {
      return linkedInError;
    }

    final portfolioError = Validators.optionalUrl(info.portfolioUrl);
    if (portfolioError != null) {
      return portfolioError;
    }

    return null;
  }

  static String? validateSummary({
    required String professionalSummary,
    required String careerObjective,
  }) {
    if (professionalSummary.trim().isEmpty && careerObjective.trim().isEmpty) {
      return 'Add a professional summary or a career objective before continuing.';
    }

    if (professionalSummary.trim().isNotEmpty &&
        professionalSummary.trim().length < 40) {
      return 'Professional summary is too short. Add a clearer 2-3 line summary.';
    }

    if (careerObjective.trim().isNotEmpty &&
        careerObjective.trim().length < 20) {
      return 'Career objective is too short. Make it more specific.';
    }

    return null;
  }

  static String? validateEducation(List<EducationInfo> education) {
    if (education.isEmpty) {
      return 'Add at least one education entry.';
    }

    for (final item in education) {
      if (item.institution.trim().isEmpty || item.degree.trim().isEmpty) {
        return 'Each education entry needs institution and degree information.';
      }
    }

    return null;
  }

  static String? validateExperience(List<ExperienceInfo> experiences) {
    for (final item in experiences) {
      if (item.companyName.trim().isEmpty || item.jobTitle.trim().isEmpty) {
        return 'Each experience entry needs company and job title information.';
      }

      if (item.highlights.isEmpty) {
        return 'Add at least one highlight for each experience entry.';
      }
    }

    return null;
  }

  static String? validateSkills(List<SkillInfo> skills) {
    if (skills.length < 2) {
      return 'Add at least two skills for a stronger CV.';
    }

    for (final skill in skills) {
      if (skill.name.trim().isEmpty) {
        return 'Skills cannot be empty.';
      }
    }

    return null;
  }

  static String? validateProjects(List<ProjectInfo> projects) {
    for (final project in projects) {
      if (project.title.trim().isEmpty || project.description.trim().isEmpty) {
        return 'Each project entry needs a title and a short description.';
      }
    }

    return null;
  }

  static String? validateTrainings(List<TrainingInfo> trainings) {
    for (final training in trainings) {
      if (training.title.trim().isEmpty) {
        return 'Training title cannot be empty.';
      }
    }

    return null;
  }

  static String? validateLanguages(List<LanguageInfo> languages) {
    for (final language in languages) {
      if (language.name.trim().isEmpty || language.proficiency.trim().isEmpty) {
        return 'Each language entry needs a language name and proficiency level.';
      }
    }

    return null;
  }
}

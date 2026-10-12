import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/utils/cv_field_codec.dart';
import 'package:flutter/material.dart';

/// The CV rendered as a sheet of paper, as in the approved preview design.
/// Sections with no content are omitted rather than shown as placeholders.
class CvPreviewContent extends StatelessWidget {
  const CvPreviewContent({super.key, required this.profile});

  final CvProfile profile;

  /// A4 height / width, used so a short CV still reads as a full page.
  static const double _paperAspect = 1.414;

  @override
  Widget build(BuildContext context) {
    final info = profile.personalInfo;
    final contact = [
      info.address,
      info.phone,
      info.email,
      info.linkedInUrl,
      info.portfolioUrl,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty).join(' · ');

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: constraints.maxWidth * _paperAspect,
          ),
          padding: const EdgeInsets.all(AppSpacing.s22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.displayName, style: AppTextStyles.h2),
              if (info.desiredRole.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s4),
                Text(
                  info.desiredRole.trim(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (contact.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(contact, style: AppTextStyles.caption),
              ],
              const SizedBox(height: AppSpacing.s14),
              const SizedBox(
                height: 2,
                width: double.infinity,
                child: ColoredBox(color: AppColors.primary),
              ),
              _textSection(
                AppStrings.previewSummary,
                profile.professionalSummary,
              ),
              _textSection(
                AppStrings.previewObjective,
                profile.careerObjective,
              ),
              if (profile.experiences.isNotEmpty)
                _Section(
                  title: AppStrings.previewExperience,
                  children: [
                    for (final item in profile.experiences)
                      _Entry(
                        title: _joined(' — ', [
                          item.jobTitle,
                          item.companyName,
                        ]),
                        meta: DateRangeCodec.format(
                          start: item.startDate,
                          end: item.endDate,
                          ongoing: item.isCurrentRole,
                        ),
                        bullets: item.highlights,
                      ),
                  ],
                ),
              if (profile.skills.isNotEmpty)
                _Section(
                  title: AppStrings.previewSkills,
                  children: [
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final skill in profile.skills)
                          _Pill(label: skill.name),
                      ],
                    ),
                  ],
                ),
              if (profile.education.isNotEmpty)
                _Section(
                  title: AppStrings.previewEducation,
                  children: [
                    for (final item in profile.education)
                      _Entry(
                        title: _joined(' — ', [item.degree, item.fieldOfStudy]),
                        meta: DateRangeCodec.format(
                          start: item.startYear,
                          end: item.endYear,
                          ongoing: item.isOngoing,
                        ),
                        subtitle: _joined(' · ', [
                          item.institution,
                          item.location,
                          item.result,
                        ]),
                      ),
                  ],
                ),
              if (profile.projects.isNotEmpty)
                _Section(
                  title: AppStrings.previewProjects,
                  children: [
                    for (final item in profile.projects)
                      _Entry(
                        title: _joined(' — ', [item.title, item.role]),
                        meta: item.link.trim(),
                        subtitle: item.technologies.isEmpty
                            ? ''
                            : CommaListCodec.format(item.technologies),
                        body: item.description.trim(),
                      ),
                  ],
                ),
              if (profile.trainings.isNotEmpty)
                _Section(
                  title: AppStrings.previewTraining,
                  children: [
                    for (final item in profile.trainings)
                      _Entry(
                        title: item.title,
                        meta: item.completionYear.trim(),
                        subtitle: item.organization,
                        body: item.details.trim(),
                      ),
                  ],
                ),
              if (profile.languages.isNotEmpty)
                _Section(
                  title: AppStrings.previewLanguages,
                  children: [
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final language in profile.languages)
                          _Pill(
                            label: _joined(' · ', [
                              language.name,
                              language.proficiency,
                            ]),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  static Widget _textSection(String title, String text) {
    final value = text.trim();
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }
    return _Section(
      title: title,
      children: [Text(value, style: AppTextStyles.bodySm)],
    );
  }

  static String _joined(String separator, List<String> parts) {
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(separator);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.s8),
          ...children,
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.title,
    this.meta = '',
    this.subtitle = '',
    this.body = '',
    this.bullets = const [],
  });

  final String title;
  final String meta;
  final String subtitle;
  final String body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (meta.trim().isNotEmpty) ...[
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: Text(
                    meta,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ],
          ),
          if (subtitle.trim().isNotEmpty)
            Text(subtitle, style: AppTextStyles.caption),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(body, style: AppTextStyles.bodySm),
            ),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(
                '${BulletsCodec.marker}$bullet',
                style: AppTextStyles.bodySm,
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.primaryDeep),
      ),
    );
  }
}

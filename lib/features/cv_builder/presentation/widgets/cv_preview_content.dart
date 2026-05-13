import 'package:careermatebd/core/widgets/custom_card.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:flutter/material.dart';

class CvPreviewContent extends StatelessWidget {
  const CvPreviewContent({super.key, required this.profile});

  final CvProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = _headerColor(profile.template, theme.colorScheme);

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.displayRole,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _HeaderMeta(text: profile.personalInfo.email),
                    _HeaderMeta(text: profile.personalInfo.phone),
                    _HeaderMeta(text: profile.personalInfo.address),
                    if (profile.personalInfo.linkedInUrl.trim().isNotEmpty)
                      _HeaderMeta(text: profile.personalInfo.linkedInUrl),
                    if (profile.personalInfo.portfolioUrl.trim().isNotEmpty)
                      _HeaderMeta(text: profile.personalInfo.portfolioUrl),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PreviewSection(
                  title: 'Professional Summary',
                  child: _PreviewText(
                    text: profile.professionalSummary,
                    placeholder:
                        'Add a short 2-3 line summary to strengthen the top of the CV.',
                  ),
                ),
                _PreviewSection(
                  title: 'Career Objective',
                  child: _PreviewText(
                    text: profile.careerObjective,
                    placeholder:
                        'Add a career objective if you want to clarify your direction.',
                  ),
                ),
                _PreviewSection(
                  title: 'Education',
                  child: profile.education.isEmpty
                      ? const _PlaceholderLine(
                          text:
                              'Education is required and will appear here once added.',
                        )
                      : Column(
                          children: [
                            for (final item in profile.education)
                              _BulletBlock(
                                title:
                                    '${item.degree} ${_joinedWithDash(item.fieldOfStudy)}',
                                subtitle: item.institution,
                                meta: _joinedWithDash(
                                  item.location,
                                  item.isOngoing
                                      ? '${item.startYear} - Present'
                                      : _joinedWithDash(
                                          item.startYear,
                                          item.endYear,
                                        ),
                                ),
                                description: item.result,
                              ),
                          ],
                        ),
                ),
                _PreviewSection(
                  title: 'Experience',
                  child: profile.experiences.isEmpty
                      ? const _PlaceholderLine(
                          text:
                              'No experience added. Freshers can rely on projects and training instead.',
                        )
                      : Column(
                          children: [
                            for (final item in profile.experiences)
                              _BulletBlock(
                                title: item.jobTitle,
                                subtitle: item.companyName,
                                meta: _joinedWithDash(
                                  item.location,
                                  item.isCurrentRole
                                      ? '${item.startDate} - Present'
                                      : _joinedWithDash(
                                          item.startDate,
                                          item.endDate,
                                        ),
                                ),
                                bullets: item.highlights,
                              ),
                          ],
                        ),
                ),
                _PreviewSection(
                  title: 'Skills',
                  child: profile.skills.isEmpty
                      ? const _PlaceholderLine(
                          text:
                              'Add at least two skills so recruiters and ATS can scan them easily.',
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in profile.skills)
                              Chip(
                                label: Text(
                                  item.level.trim().isEmpty
                                      ? item.name
                                      : '${item.name} • ${item.level}',
                                ),
                              ),
                          ],
                        ),
                ),
                _PreviewSection(
                  title: 'Projects',
                  child: profile.projects.isEmpty
                      ? const _PlaceholderLine(
                          text:
                              'Add project work to make the CV stronger, especially for internships and fresher roles.',
                        )
                      : Column(
                          children: [
                            for (final item in profile.projects)
                              _BulletBlock(
                                title: item.title,
                                subtitle: item.role,
                                meta: item.link,
                                description: item.description,
                                bullets: item.technologies.isEmpty
                                    ? const []
                                    : [
                                        'Technologies: ${item.technologies.join(', ')}',
                                      ],
                              ),
                          ],
                        ),
                ),
                _PreviewSection(
                  title: 'Training / Certifications',
                  child: profile.trainings.isEmpty
                      ? const _PlaceholderLine(
                          text: 'Training details will appear here when added.',
                        )
                      : Column(
                          children: [
                            for (final item in profile.trainings)
                              _BulletBlock(
                                title: item.title,
                                subtitle: item.organization,
                                meta: item.completionYear,
                                description: item.details,
                              ),
                          ],
                        ),
                ),
                _PreviewSection(
                  title: 'Languages',
                  child: profile.languages.isEmpty
                      ? const _PlaceholderLine(
                          text:
                              'Add language proficiency such as Bangla and English.',
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in profile.languages)
                              Chip(
                                label: Text(
                                  '${item.name} • ${item.proficiency}',
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _headerColor(CvTemplate template, ColorScheme colorScheme) {
    return switch (template) {
      CvTemplate.classic => colorScheme.primary,
      CvTemplate.modern => colorScheme.secondary,
      CvTemplate.minimal => const Color(0xFF2D3A45),
      CvTemplate.professional => const Color(0xFF144B7D),
      CvTemplate.fresher => const Color(0xFF2F6F4F),
    };
  }

  static String _joinedWithDash(String first, [String second = '']) {
    final values = [
      first.trim(),
      second.trim(),
    ].where((item) => item.isNotEmpty);
    return values.join(' • ');
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PreviewText extends StatelessWidget {
  const _PreviewText({required this.text, required this.placeholder});

  final String text;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return _PlaceholderLine(text: placeholder);
    }

    return Text(text.trim(), style: Theme.of(context).textTheme.bodyLarge);
  }
}

class _PlaceholderLine extends StatelessWidget {
  const _PlaceholderLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _BulletBlock extends StatelessWidget {
  const _BulletBlock({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.description = '',
    this.bullets = const [],
  });

  final String title;
  final String subtitle;
  final String meta;
  final String description;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyLarge),
          ],
          if (meta.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meta, style: theme.textTheme.labelMedium),
          ],
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyLarge),
          ],
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(bullet, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.86),
      ),
    );
  }
}

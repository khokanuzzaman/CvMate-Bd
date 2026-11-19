import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_declaration.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:image/image.dart' as img;

/// The three CVs every template is checked with (see docs/qa/templates/).
enum TemplateFixture { full, minimal, nonAscii }

/// A fixture CV, with the strings that must appear in its preview and its PDF.
class FixtureCv {
  const FixtureCv(this.profile, this.expected, {this.absentTitles = const []});

  final CvProfile profile;

  /// Every non-empty value the CV holds, as typed (one per field or bullet).
  final List<String> expected;

  /// Section titles (and the declaration) that must not be printed, because
  /// their sections are empty or switched off.
  final List<String> absentTitles;
}

FixtureCv fixtureCv(TemplateFixture fixture, CvTemplate template) =>
    switch (fixture) {
      TemplateFixture.full => fullCv(template),
      TemplateFixture.minimal => minimalCv(template),
      TemplateFixture.nonAscii => nonAsciiCv(template),
    };

final DateTime _fixed = DateTime(2026, 11, 17);

/// A tiny solid-grey JPEG in the 35x45 passport ratio.
Uint8List fixturePhoto() => img.encodeJpg(
  img.Image(width: 35, height: 45)..clear(img.ColorRgb8(120, 120, 120)),
);

/// A tiny signature PNG.
Uint8List fixtureSignature() => img.encodePng(
  img.Image(width: 60, height: 20)..clear(img.ColorRgb8(20, 20, 20)),
);

CvProfile _base(CvTemplate template, String id) => CvProfile.empty().copyWith(
  id: id,
  title: 'QA CV',
  template: template,
  createdAt: _fixed,
  updatedAt: _fixed,
);

/// (a) Every section filled, photo / details / declaration / signature shown,
/// long bullets so the PDF runs to two pages in every template.
FixtureCv fullCv(CvTemplate template) {
  const name = 'Ayesha Rahman';
  const role = 'Senior Frontend Engineer';
  const info = PersonalInfo(
    fullName: name,
    desiredRole: role,
    email: 'ayesha.rahman@example.com',
    phone: '+880 1712-345678',
    address: 'House 12, Road 5, Dhanmondi, Dhaka',
    linkedInUrl: 'linkedin.com/in/ayesha-rahman',
    portfolioUrl: 'ayesha.dev',
  );
  const summary =
      'Frontend engineer with seven years of experience building accessible, '
      'fast web and mobile interfaces for fintech and e-commerce products used '
      'by millions of customers across South Asia and the Gulf.';
  const objective =
      'Seeking a senior frontend role where I can lead a small team and own '
      'the design system end to end.';

  final experiences = [
    for (var i = 1; i <= 2; i++)
      ExperienceInfo(
        id: 'exp-$i',
        jobTitle: 'Frontend Engineer $i',
        companyName: 'Company $i Ltd.',
        location: const ['Chattogram', 'Sylhet', 'Dubai'][i - 1],
        startDate: '${2015 + 2 * i}',
        endDate: i == 2 ? '' : '${2017 + 2 * i}',
        isCurrentRole: i == 2,
        highlights: [
          for (var b = 1; b <= 2; b++)
            'Bullet $i.$b: moved a legacy dashboard to shared components, '
                'cutting page load time by 40 percent.',
        ],
      ),
  ];
  const education = [
    EducationInfo(
      id: 'edu-1',
      degree: 'BSc in Computer Science',
      fieldOfStudy: 'Software Engineering',
      institution: 'University of Dhaka',
      location: 'Dhaka',
      startYear: '2011',
      endYear: '2015',
      result: 'CGPA 3.8 out of 4',
    ),
  ];
  final skills = [
    for (final (i, s) in [
      'React',
      'TypeScript',
      'Flutter',
      'Accessibility',
      'GraphQL',
      'Testing',
    ].indexed)
      SkillInfo(id: 'skill-$i', name: s, level: i.isEven ? 'Advanced' : ''),
  ];
  const projects = [
    ProjectInfo(
      id: 'pro-1',
      title: 'Expense Tracker App',
      role: 'Lead Developer',
      link: 'github.com/ayesha/expenses',
      technologies: ['Flutter', 'Firebase'],
      description: 'Personal finance app with charts, budgets and reminders.',
    ),
    ProjectInfo(
      id: 'pro-2',
      title: 'Design System Kit',
      role: 'Maintainer',
      technologies: ['React', 'Storybook'],
      description: 'Forty shared components used by six product teams.',
    ),
  ];
  const trainings = [
    TrainingInfo(
      id: 'tr-1',
      title: 'AWS Certified Developer',
      organization: 'Amazon Web Services',
      completionYear: '2023',
      details: 'Serverless APIs and CI pipelines.',
    ),
  ];
  const languages = [
    LanguageInfo(id: 'lang-1', name: 'Bangla', proficiency: 'Native'),
    LanguageInfo(id: 'lang-2', name: 'English', proficiency: 'Fluent'),
  ];
  const awards = CustomSection(
    id: 'custom-awards',
    title: 'Awards',
    items: [
      CustomSectionItem(
        id: 'aw-1',
        title: 'Employee of the Year',
        description: 'Recognised for shipping the payments revamp.',
      ),
    ],
  );
  const volunteering = CustomSection(
    id: 'custom-vol',
    title: 'Volunteering',
    layout: CustomSectionLayout.bullets,
    items: [
      CustomSectionItem(id: 'vol-1', title: 'Mentor at Code for Dhaka'),
      CustomSectionItem(id: 'vol-2', title: 'Organiser of DhakaJS meetups'),
    ],
  );
  const details = PersonalDetails(
    dateOfBirth: '12 March 1993',
    nationality: 'Bangladeshi',
    passportNumber: 'A01234567',
    passportExpiry: '2030',
    visaStatus: 'Employment visa',
    drivingLicence: 'Light vehicle',
    maritalStatus: 'Single',
    religion: 'Islam',
    gender: 'Female',
  );

  final profile = _base(template, 'qa-full').copyWith(
    personalInfo: info,
    professionalSummary: summary,
    careerObjective: objective,
    experiences: experiences,
    education: education,
    skills: skills,
    projects: projects,
    trainings: trainings,
    languages: languages,
    customSections: const [awards, volunteering],
    style: CvStyle.southAsia,
    shownFields: PersonalField.values.toSet(),
    details: details,
    declaration: const CvDeclaration(place: 'Dhaka', date: '17 Nov 2026'),
    photo: fixturePhoto(),
    signature: fixtureSignature(),
  );

  return FixtureCv(profile, [
    name,
    role,
    info.email,
    info.phone,
    info.address,
    info.linkedInUrl,
    info.portfolioUrl,
    summary,
    objective,
    for (final e in experiences) ...[
      e.jobTitle,
      e.companyName,
      e.location,
      ...e.highlights,
    ],
    for (final e in education) ...[e.degree, e.institution, e.result],
    for (final s in skills) s.name,
    'Advanced',
    for (final p in projects) ...[p.title, p.role, p.description],
    for (final t in trainings) ...[t.title, t.organization, t.details],
    for (final l in languages) ...[l.name, l.proficiency],
    awards.title,
    'Employee of the Year',
    'Recognised for shipping the payments revamp.',
    volunteering.title,
    'Mentor at Code for Dhaka',
    'Organiser of DhakaJS meetups',
    details.dateOfBirth,
    details.nationality,
    details.passportNumber,
    details.visaStatus,
    details.drivingLicence,
    details.maritalStatus,
    details.religion,
    details.gender,
    CvDeclaration.defaultEnglish,
    'Dhaka',
    '17 Nov 2026',
  ]);
}

/// (b) Only what the builder requires (CvBuilderValidators): title, name,
/// role, email, phone, address, a summary, one education entry and two
/// skills. Every optional section is empty, so none of their titles may print.
FixtureCv minimalCv(CvTemplate template) {
  const info = PersonalInfo(
    fullName: 'Rahim Uddin',
    desiredRole: 'Junior Accountant',
    email: 'rahim@example.com',
    phone: '01711111111',
    address: 'Khulna',
  );
  const summary = 'Commerce graduate who keeps ledgers tidy and on time.';
  const education = EducationInfo(
    id: 'edu-1',
    degree: 'BCom',
    institution: 'Khulna University',
  );
  return FixtureCv(
    _base(template, 'qa-minimal').copyWith(
      personalInfo: info,
      professionalSummary: summary,
      education: const [education],
      skills: const [
        SkillInfo(id: 'skill-1', name: 'Tally'),
        SkillInfo(id: 'skill-2', name: 'Excel'),
      ],
    ),
    [
      info.fullName,
      info.desiredRole,
      info.email,
      info.phone,
      info.address,
      summary,
      education.degree,
      education.institution,
      'Tally',
      'Excel',
    ],
    absentTitles: const [
      'Objective',
      'Experience',
      'Projects',
      'Training',
      'Languages',
      'Personal Details',
      'I hereby declare',
    ],
  );
}

/// Bangla, accented Latin and an emoji, in the header and in the body.
const String banglaName = 'নুসরাত জাহান';
const String banglaAddress = 'ঢাকা, বাংলাদেশ';
const String accentedName = 'José Müller';
const String accentedCity = 'Zürich, Ångström';
const String emojiBullet = 'Shipped v2 🚀';

/// (c) Non-ASCII text in every kind of field.
FixtureCv nonAsciiCv(CvTemplate template) {
  const info = PersonalInfo(
    fullName: banglaName,
    desiredRole: 'Product Designer',
    email: 'nusrat@example.com',
    address: banglaAddress,
  );
  const summary = 'Worked with $accentedName in $accentedCity.';
  const experience = ExperienceInfo(
    id: 'exp-1',
    jobTitle: 'Designer',
    companyName: 'Café Señor GmbH',
    startDate: '2022',
    isCurrentRole: true,
    highlights: [emojiBullet, 'Redesigned the onboarding flow'],
  );
  return FixtureCv(
    _base(template, 'qa-non-ascii').copyWith(
      personalInfo: info,
      professionalSummary: summary,
      experiences: const [experience],
    ),
    [
      banglaName,
      banglaAddress,
      summary,
      'Café Señor GmbH',
      emojiBullet,
      'Redesigned the onboarding flow',
    ],
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

List<CvSectionKind> _kinds(CvProfile profile) => [
  for (final section in profile.sections) section.kind,
];

/// Custom sections have no value equality; compare what they hold.
List<Object> _plain(List<CustomSection> sections) => [
  for (final section in sections)
    [
      section.id,
      section.title,
      section.layout,
      for (final item in section.items) [item.id, item.title, item.description],
    ],
];

void main() {
  test(
    'an old CV (Hive JSON and Firestore shape) loads with the default order',
    () {
      final hive = CvProfileDto.fromJson(_fixture('cv_v1_hive.json')).profile;
      expect(hive.title, 'Staff Nurse CV');
      expect(hive.sectionLayout, isNull);
      expect(hive.customSections, isEmpty);
      expect(_kinds(hive), CvSectionLayout.standardOrder);
      expect(
        hive.sections.every((s) => s.visible && s.titleOverride == null),
        isTrue,
      );

      final firestore = CvProfileDto.fromMap(
        jsonDecode(_fixture('cv_v1_firestore.json')) as Map<String, dynamic>,
      ).profile;
      expect(firestore.template, CvTemplate.fresher);
      expect(firestore.sectionLayout, isNull);
      expect(_kinds(firestore), CvSectionLayout.fresherOrder);

      // Market style (schema 3): an old CV is international, A4, with every new
      // personal field hidden and no photo or signature.
      for (final cv in [hive, firestore]) {
        expect(cv.style, CvStyle.international);
        expect(cv.paperSize, PaperSize.a4);
        expect(cv.shownFields, isEmpty);
        expect(cv.details.isEmpty, isTrue);
        expect(cv.photo, isNull);
        expect(cv.signature, isNull);
        expect(cv.showDeclaration, isFalse);
      }
    },
  );

  test(
    'v2 round trip: layout and custom sections survive Hive and Firestore',
    () {
      final original = CvProfile.empty().copyWith(
        id: 'cv-new',
        title: 'Custom CV',
        customSections: const [
          CustomSection(
            id: 'custom-1',
            title: 'Awards',
            layout: CustomSectionLayout.bullets,
            items: [
              CustomSectionItem(id: 'a1', title: 'Best Nurse 2024'),
              CustomSectionItem(
                id: 'a2',
                title: 'Dean’s list',
                description: '2019',
              ),
            ],
          ),
        ],
        sectionLayout: [
          SectionConfig.builtIn(CvSectionKind.skills),
          SectionConfig.custom('custom-1'),
          SectionConfig.builtIn(
            CvSectionKind.experience,
            titleOverride: 'Work history',
          ),
          SectionConfig.builtIn(CvSectionKind.summary, visible: false),
        ],
      );

      final hive = CvProfileDto.fromJson(
        CvProfileDto(original).toJson(),
      ).profile;
      // Firestore hands back plain decoded maps.
      final cloud = CvProfileDto.fromMap(
        jsonDecode(jsonEncode(CvProfileDto(original).toMap()))
            as Map<String, dynamic>,
      ).profile;

      for (final loaded in [hive, cloud]) {
        expect(loaded.sections, original.sections);
        expect(_plain(loaded.customSections), _plain(original.customSections));
        expect(loaded.isSectionVisible(CvSectionKind.summary), isFalse);
      }
    },
  );
}

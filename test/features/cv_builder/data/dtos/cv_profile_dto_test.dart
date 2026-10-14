import 'dart:convert';
import 'dart:io';

import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

List<CvSectionKind> _kinds(CvProfile profile) => [
  for (final section in profile.sections) section.kind,
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
    },
  );
}

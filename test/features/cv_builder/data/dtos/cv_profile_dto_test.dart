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

CvProfile _customised() {
  final base = CvProfile.empty().copyWith(
    id: 'cv-new',
    title: 'Custom CV',
    template: CvTemplate.modern,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
  const volunteering = CustomSection(
    id: 'custom-1',
    title: 'Volunteering',
    layout: CustomSectionLayout.titledRows,
    items: [
      CustomSectionItem(
        id: 'i1',
        title: 'Red Crescent',
        description: 'First-aid trainer, weekends.',
      ),
    ],
  );
  const awards = CustomSection(
    id: 'custom-2',
    title: 'Awards',
    layout: CustomSectionLayout.bullets,
    items: [
      CustomSectionItem(id: 'a1', title: 'Best Nurse 2024'),
      CustomSectionItem(id: 'a2', title: 'Dean’s list', description: '2019'),
    ],
  );
  return base.copyWith(
    customSections: const [volunteering, awards],
    sectionLayout: [
      SectionConfig.builtIn(CvSectionKind.skills),
      SectionConfig.custom('custom-2'),
      SectionConfig.builtIn(
        CvSectionKind.experience,
        titleOverride: 'Work history',
      ),
      SectionConfig.builtIn(CvSectionKind.summary, visible: false),
      SectionConfig.custom('custom-1', visible: false),
    ],
  );
}

void main() {
  group('reading old data (no section layout)', () {
    test('a v1 Hive JSON CV loads with the default order, all visible', () {
      final profile = CvProfileDto.fromJson(
        _fixture('cv_v1_hive.json'),
      ).profile;

      expect(profile.title, 'Staff Nurse CV');
      expect(profile.personalInfo.fullName, 'Nusrat Jahan');
      expect(profile.experiences.single.highlights, hasLength(2));
      expect(profile.sectionLayout, isNull);
      expect(profile.customSections, isEmpty);
      expect(_kinds(profile), CvSectionLayout.standardOrder);
      expect(profile.sections.every((section) => section.visible), isTrue);
      expect(
        profile.sections.every((section) => section.titleOverride == null),
        isTrue,
      );
    });

    test(
      'a v1 Firestore document loads the same way (Fresher keeps its order)',
      () {
        final map =
            jsonDecode(_fixture('cv_v1_firestore.json'))
                as Map<String, dynamic>;
        final profile = CvProfileDto.fromMap(map).profile;

        expect(profile.template, CvTemplate.fresher);
        expect(profile.sectionLayout, isNull);
        expect(_kinds(profile), CvSectionLayout.fresherOrder);
        expect(profile.projects.single.title, 'CvMate');
      },
    );

    test('re-saving an old CV does not invent a layout', () {
      final profile = CvProfileDto.fromJson(
        _fixture('cv_v1_hive.json'),
      ).profile;
      final written = CvProfileDto(profile).toMap();

      expect(written['schemaVersion'], CvProfileDto.schemaVersion);
      expect(written.containsKey('sectionLayout'), isFalse);
      expect(written['customSections'], isEmpty);
      expect(
        _kinds(CvProfileDto.fromMap(written).profile),
        CvSectionLayout.standardOrder,
      );
    });
  });

  group('writing keeps old readers safe', () {
    test('every field an old reader uses is still written, unchanged', () {
      final map =
          jsonDecode(_fixture('cv_v1_hive.json')) as Map<String, dynamic>;
      final profile = CvProfileDto.fromMap(map).profile;
      final written = CvProfileDto(
        profile.copyWith(
          sectionLayout: [SectionConfig.builtIn(CvSectionKind.skills)],
        ),
      ).toMap();

      for (final entry in map.entries) {
        expect(written.containsKey(entry.key), isTrue, reason: entry.key);
        if (entry.key != 'createdAt' && entry.key != 'updatedAt') {
          expect(written[entry.key], entry.value, reason: entry.key);
        }
      }
      // Only additions: the version, the layout, the custom sections.
      expect(written.keys.toSet().difference(map.keys.toSet()), {
        'schemaVersion',
        'sectionLayout',
        'customSections',
      });
    });
  });

  group('round trips', () {
    test('layout and custom sections survive JSON (Hive)', () {
      final original = _customised();
      final loaded = CvProfileDto.fromJson(
        CvProfileDto(original).toJson(),
      ).profile;

      expect(loaded.sectionLayout, original.sectionLayout);
      expect(loaded.customSections.map((s) => s.id), ['custom-1', 'custom-2']);
      final awards = loaded.customSectionById('custom-2')!;
      expect(awards.layout, CustomSectionLayout.bullets);
      expect(awards.items.map((i) => i.title), [
        'Best Nurse 2024',
        'Dean’s list',
      ]);
      expect(awards.items.last.description, '2019');
      expect(loaded.sections, original.sections);
    });

    test('and through a Firestore map, including nested Map<Object?, …>', () {
      final original = _customised();
      final map = CvProfileDto(original).toMap();
      // Firestore can hand nested maps back with looser key types.
      final loose = jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
      final looseLayout = [
        for (final entry in loose['sectionLayout'] as List)
          Map<Object?, Object?>.from(entry as Map),
      ];
      loose['sectionLayout'] = looseLayout;

      final loaded = CvProfileDto.fromMap(loose).profile;
      expect(loaded.sectionLayout, original.sectionLayout);
      expect(loaded.customSections.length, 2);
    });

    test('hidden, renamed and reordered state is preserved exactly', () {
      final loaded = CvProfileDto.fromJson(
        CvProfileDto(_customised()).toJson(),
      ).profile;
      final byId = {for (final s in loaded.sections) s.id: s};

      expect(byId['summary']!.visible, isFalse);
      expect(byId['custom-1']!.visible, isFalse);
      expect(byId['experience']!.cleanTitleOverride, 'Work history');
      expect(_kinds(loaded).take(3), [
        CvSectionKind.skills,
        CvSectionKind.custom,
        CvSectionKind.experience,
      ]);
    });
  });

  group('resolving a layout', () {
    test('missing built-ins are appended and custom sections never vanish', () {
      final loaded = CvProfileDto.fromJson(
        CvProfileDto(_customised()).toJson(),
      ).profile;

      expect(
        _kinds(loaded).where((k) => k == CvSectionKind.custom),
        hasLength(2),
      );
      for (final kind in CvSectionLayout.standardOrder) {
        expect(
          _kinds(loaded).where((k) => k == kind),
          hasLength(1),
          reason: '$kind',
        );
      }
    });

    test('a layout naming a custom section that is gone drops it', () {
      final profile = CvProfile.empty().copyWith(
        sectionLayout: [SectionConfig.custom('ghost')],
      );
      expect(_kinds(profile), CvSectionLayout.standardOrder);
    });
  });

  group('never fails on odd data', () {
    Map<String, dynamic> oldMap() =>
        jsonDecode(_fixture('cv_v1_hive.json')) as Map<String, dynamic>;

    test('wrong types fall back to the default layout', () {
      for (final bad in <Object?>[
        'nope',
        42,
        {'a': 1},
        <Object?>[],
        <Object?>['x', 5, null],
        <Object?>[
          {'kind': 'martian', 'id': 'm', 'visible': true},
        ],
      ]) {
        final map = oldMap()..['sectionLayout'] = bad;
        final profile = CvProfileDto.fromMap(map).profile;
        expect(_kinds(profile), CvSectionLayout.standardOrder, reason: '$bad');
      }
    });

    test('unknown kinds are skipped, the rest kept', () {
      final map = oldMap()
        ..['sectionLayout'] = [
          {'kind': 'hologram', 'id': 'h'},
          {'kind': 'skills', 'id': 'skills', 'visible': false},
          {'kind': 'education', 'id': 'education', 'visible': 'yes'},
        ];
      final profile = CvProfileDto.fromMap(map).profile;

      expect(_kinds(profile).first, CvSectionKind.skills);
      expect(profile.isSectionVisible(CvSectionKind.skills), isFalse);
      expect(
        profile.isSectionVisible(CvSectionKind.education),
        isTrue,
        reason: 'a non-bool visible means the default (shown)',
      );
    });

    test('malformed custom sections are skipped or defaulted', () {
      final map = oldMap()
        ..['customSections'] = [
          'junk',
          {'title': 'No id'},
          {'id': 'dup', 'title': 'First'},
          {'id': 'dup', 'title': 'Second'},
          {
            'id': 'ok',
            'title': 5,
            'layout': 'sideways',
            'items': [
              'x',
              {'title': 'Row', 'description': null},
            ],
          },
        ];
      final profile = CvProfileDto.fromMap(map).profile;

      expect(profile.customSections.map((s) => s.id), ['dup', 'ok']);
      expect(profile.customSections.first.title, 'First');
      final ok = profile.customSectionById('ok')!;
      expect(ok.title, '');
      expect(ok.layout, CustomSectionLayout.titledRows);
      expect(ok.items.single.title, 'Row');
      expect(ok.items.single.description, '');
      expect(ok.items.single.id, isNotEmpty);
    });

    test('a newer schemaVersion with extra keys still loads', () {
      final map = oldMap()
        ..['schemaVersion'] = 99
        ..['somethingFromTheFuture'] = {'a': 1};
      final profile = CvProfileDto.fromMap(map).profile;
      expect(profile.title, 'Staff Nurse CV');
    });
  });
}

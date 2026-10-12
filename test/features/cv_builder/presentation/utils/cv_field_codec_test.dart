import 'package:careermatebd/features/cv_builder/presentation/utils/cv_field_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateRangeCodec.format', () {
    test('joins start and end with an em dash', () {
      expect(
        DateRangeCodec.format(start: '2018', end: '2022', ongoing: false),
        '2018 — 2022',
      );
    });

    test('shows Now for an ongoing range and ignores any stored end', () {
      expect(
        DateRangeCodec.format(start: '2022', end: '2023', ongoing: true),
        '2022 — Now',
      );
    });

    test('handles missing parts', () {
      expect(DateRangeCodec.format(start: '', end: '', ongoing: false), '');
      expect(
        DateRangeCodec.format(start: '2020', end: '', ongoing: false),
        '2020',
      );
      expect(
        DateRangeCodec.format(start: '', end: '2022', ongoing: false),
        '— 2022',
      );
      expect(DateRangeCodec.format(start: '', end: '', ongoing: true), '— Now');
    });
  });

  group('DateRangeCodec.parse', () {
    test('splits on em dash, en dash and spaced hyphen', () {
      for (final text in ['2018 — 2022', '2018 – 2022', '2018 - 2022']) {
        expect(DateRangeCodec.parse(text), (
          start: '2018',
          end: '2022',
          ongoing: false,
        ), reason: text);
      }
    });

    test('splits an unspaced year-to-year hyphen range', () {
      expect(DateRangeCodec.parse('2018-2022'), (
        start: '2018',
        end: '2022',
        ongoing: false,
      ));
      expect(DateRangeCodec.parse('2020-present'), (
        start: '2020',
        end: '',
        ongoing: true,
      ));
    });

    test('recognises ongoing keywords case-insensitively', () {
      for (final word in [
        'Now',
        'present',
        'CURRENT',
        'Ongoing',
        'till date',
      ]) {
        expect(DateRangeCodec.parse('Jan 2022 — $word'), (
          start: 'Jan 2022',
          end: '',
          ongoing: true,
        ), reason: word);
      }
    });

    test('keeps free-text dates intact', () {
      expect(DateRangeCodec.parse('Jan 2022 — Dec 2023'), (
        start: 'Jan 2022',
        end: 'Dec 2023',
        ongoing: false,
      ));
      expect(
        DateRangeCodec.parse('2024-06'),
        (start: '2024-06', end: '', ongoing: false),
        reason: 'a hyphenated month is not a range',
      );
    });

    test('a single value is only the start; blank clears everything', () {
      expect(DateRangeCodec.parse('2020'), (
        start: '2020',
        end: '',
        ongoing: false,
      ));
      expect(DateRangeCodec.parse('   '), (start: '', end: '', ongoing: false));
    });

    test('round-trips what format produces', () {
      final cases = <({String start, String end, bool ongoing})>[
        (start: '2018', end: '2022', ongoing: false),
        (start: 'Jan 2022', end: '', ongoing: true),
        (start: '2020', end: '', ongoing: false),
        (start: '', end: '2022', ongoing: false),
        (start: '', end: '', ongoing: false),
      ];
      for (final value in cases) {
        final text = DateRangeCodec.format(
          start: value.start,
          end: value.end,
          ongoing: value.ongoing,
        );
        expect(DateRangeCodec.parse(text), value, reason: text);
      }
    });
  });

  group('BulletsCodec', () {
    test('formats one bullet per line and skips blanks', () {
      expect(
        BulletsCodec.format(['Built X', '  ', ' Shipped Y ']),
        '• Built X\n• Shipped Y',
      );
      expect(BulletsCodec.format(const []), '');
    });

    test('parses with or without bullet markers', () {
      expect(
        BulletsCodec.parse(
          '• Built X\n- Shipped Y\n* Fixed Z\nPlain line\n\n  ',
        ),
        ['Built X', 'Shipped Y', 'Fixed Z', 'Plain line'],
      );
    });

    test('does not strip a hyphen that is part of the text', () {
      expect(BulletsCodec.parse('-5% cost, 20-30% faster'), [
        '-5% cost, 20-30% faster',
      ]);
    });

    test('round-trips', () {
      const items = [
        'Built responsive interfaces',
        'Collaborated with designers',
      ];
      expect(BulletsCodec.parse(BulletsCodec.format(items)), items);
    });
  });

  group('CommaListCodec', () {
    test('formats and parses comma separated values', () {
      expect(
        CommaListCodec.format(['React', ' Firebase ', '']),
        'React, Firebase',
      );
      expect(CommaListCodec.parse('React, Firebase,, ,Git '), [
        'React',
        'Firebase',
        'Git',
      ]);
      expect(CommaListCodec.parse(''), isEmpty);
    });
  });
}

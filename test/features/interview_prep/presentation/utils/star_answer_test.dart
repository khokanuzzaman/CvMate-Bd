import 'package:careermatebd/features/interview_prep/presentation/utils/star_answer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const star =
      'Situation: Key screens were slow on mobile. Task: Make them faster. '
      'Action: Split bundles, memoized lists. Result: [add your number].';

  group('parseStarAnswer', () {
    test('splits an answer at its STAR labels', () {
      final segments = parseStarAnswer(star);

      expect(segments.map((s) => s.label), [
        'Situation:',
        'Task:',
        'Action:',
        'Result:',
      ]);
      expect(segments.first.text, 'Key screens were slow on mobile.');
      expect(segments.last.text, '[add your number].');
    });

    test('keeps text before the first label', () {
      final segments = parseStarAnswer('In short: Situation: A. Task: B.');

      expect(segments.first.label, isNull);
      expect(segments.first.text, 'In short:');
      expect(segments[1].label, 'Situation:');
    });

    test('an answer without labels stays one plain segment', () {
      final segments = parseStarAnswer('I walked through the trade-offs.');

      expect(segments, hasLength(1));
      expect(segments.single.label, isNull);
      expect(segments.single.text, 'I walked through the trade-offs.');
    });

    test('an empty answer has no segments', () {
      expect(parseStarAnswer('   '), isEmpty);
    });

    test('labels match case-insensitively but are shown as written', () {
      final segments = parseStarAnswer('situation: A. result: B.');

      expect(segments.map((s) => s.label), ['situation:', 'result:']);
    });
  });

  group('isStarAnswer', () {
    test('needs at least three of the four labels', () {
      expect(isStarAnswer(star), isTrue);
      expect(isStarAnswer('Situation: A. Task: B. Action: C.'), isTrue);
      expect(isStarAnswer('Situation: A. Result: B.'), isFalse);
      expect(isStarAnswer('I walked through the trade-offs.'), isFalse);
    });

    test('a label repeated does not count twice', () {
      expect(isStarAnswer('Action: A. Action: B. Action: C.'), isFalse);
    });
  });
}

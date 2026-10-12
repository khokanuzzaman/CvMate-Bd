import 'package:careermatebd/features/cv_builder/presentation/utils/suggested_skills.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frontend roles get web skills first', () {
    final skills = SuggestedSkills.forRole(
      'Frontend Developer',
      existing: const [],
    );
    expect(skills.take(3), ['React', 'TypeScript', 'CSS']);
  });

  test('skips skills the CV already has (case-insensitive)', () {
    final skills = SuggestedSkills.forRole(
      'Frontend Developer',
      existing: const ['react', ' CSS '],
    );
    expect(skills, isNot(contains('React')));
    expect(skills, isNot(contains('CSS')));
    expect(skills.first, 'TypeScript');
  });

  test('respects the limit and never repeats a skill', () {
    final skills = SuggestedSkills.forRole(
      'Flutter Mobile Developer',
      existing: const [],
      limit: 5,
    );
    expect(skills.length, 5);
    expect(skills.toSet().length, 5);
    expect(skills, contains('Flutter'));
  });

  test('unknown or empty roles fall back to general skills', () {
    for (final role in ['', 'Astronaut']) {
      expect(SuggestedSkills.forRole(role, existing: const []), [
        'Communication',
        'Teamwork',
        'Problem solving',
        'Time management',
      ], reason: role);
    }
  });

  test('short keywords match whole words only', () {
    // "ui" must not match inside "build", "hr" not inside "three".
    final skills = SuggestedSkills.forRole(
      'Builder of three things',
      existing: const [],
    );
    expect(skills, isNot(contains('React')));
    expect(skills.first, 'Communication');
  });

  test('stops once every candidate is already taken', () {
    final skills = SuggestedSkills.forRole(
      '',
      existing: const [
        'Communication',
        'Teamwork',
        'Problem solving',
        'Time management',
        'MS Office',
      ],
    );
    expect(skills, isEmpty);
  });
}

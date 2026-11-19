import 'package:careermatebd/core/utils/skill_list_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('commas inside brackets do not split a skill; lines and other commas '
      'do', () {
    expect(
      SkillListText.parse(
        'REST API Integration\n'
        'State Management (Provider, Riverpod, or BLoC)\n'
        'Git, Docker\n'
        'git\n'
        '\n',
      ),
      [
        'REST API Integration',
        'State Management (Provider, Riverpod, or BLoC)',
        'Git',
        'Docker',
      ],
    );
  });
}

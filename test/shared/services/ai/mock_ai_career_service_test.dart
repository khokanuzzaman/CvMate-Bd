import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_prompt_builder.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAiCareerService service;

  setUp(() {
    service = const MockAiCareerService(
      promptBuilder: AiPromptBuilder(),
      responseParser: AiResponseParser(),
    );
  });

  final sampleProfile = CvProfile.empty().copyWith(
    title: 'Flutter CV',
    personalInfo: const PersonalInfo(
      fullName: 'Khokan Uzzaman',
      desiredRole: 'Flutter Developer',
      email: 'khokan@example.com',
      phone: '01700000000',
      address: 'Dhaka, Bangladesh',
    ),
    skills: const [
      SkillInfo(id: '1', name: 'Flutter', level: 'Advanced'),
      SkillInfo(id: '2', name: 'Dart', level: 'Advanced'),
      SkillInfo(id: '3', name: 'Firebase', level: 'Intermediate'),
    ],
    projects: const [
      ProjectInfo(
        id: '1',
        title: 'Appointment App',
        role: 'Developer',
        description: 'built an appointment booking app',
        technologies: ['Flutter', 'Firebase'],
      ),
    ],
  );

  test('generateProfessionalSummary returns structured mock output', () async {
    final result = await service.generateProfessionalSummary(
      profile: sampleProfile,
      language: AiOutputLanguage.english,
    );

    expect(result.isSuccess, isTrue);

    switch (result) {
      case Success<AiTextSuggestion>(:final data):
        expect(data.title, 'Professional Summary');
        expect(data.suggestedText, contains('Flutter Developer'));
        expect(data.guidancePoints, isNotEmpty);
      case FailureResult<AiTextSuggestion>(:final error):
        fail('Expected success but got ${error.message}');
    }
  });

  test(
    'calculateCvJobMatch returns deterministic structured match data',
    () async {
      const jobPost = '''
We are hiring a Flutter Developer with experience in Dart, Firebase, REST API,
Git, and strong communication skills. Candidates should be comfortable building
mobile apps and collaborating with product teams.
''';

      final result = await service.calculateCvJobMatch(
        profile: sampleProfile,
        jobPostText: jobPost,
        language: AiOutputLanguage.english,
      );

      expect(result.isSuccess, isTrue);

      switch (result) {
        case Success<CvJobMatchResult>(:final data):
          expect(data.matchScore, greaterThan(50));
          expect(data.matchedSkills, contains('Flutter'));
          expect(data.priorityActions, isNotEmpty);
        case FailureResult<CvJobMatchResult>(:final error):
          fail('Expected success but got ${error.message}');
      }
    },
  );
}

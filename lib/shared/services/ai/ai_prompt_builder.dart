import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';

class AiPromptBuilder {
  const AiPromptBuilder();

  String generateProfessionalSummary({
    required CvProfile profile,
    required AiOutputLanguage language,
    required AiTone tone,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    return _buildPrompt(
      action: 'generateProfessionalSummary',
      language: language,
      responseSchema:
          '{"title":"","originalText":"","suggestedText":"","guidancePoints":[""],"language":""}',
      inputs: [
        _profileSnapshot(profile),
        _jobContext(jobTitle: jobTitle, jobPostText: jobPostText),
        'Requested tone: ${tone.code}',
      ],
      extraRules: const [
        'Write a concise ATS-friendly professional summary.',
        'Do not invent experience, companies, or achievements.',
        'Match the user experience level.',
      ],
    );
  }

  String generateCareerObjective({
    required CvProfile profile,
    required AiOutputLanguage language,
    required AiTone tone,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    return _buildPrompt(
      action: 'generateCareerObjective',
      language: language,
      responseSchema:
          '{"title":"","originalText":"","suggestedText":"","guidancePoints":[""],"language":""}',
      inputs: [
        _profileSnapshot(profile),
        _jobContext(jobTitle: jobTitle, jobPostText: jobPostText),
        'Requested tone: ${tone.code}',
      ],
      extraRules: const [
        'Write a short, specific, fresher-friendly objective when relevant.',
        'Keep the tone honest and practical.',
      ],
    );
  }

  String improveExperienceBullet({
    required String bullet,
    required CvProfile profile,
    required AiOutputLanguage language,
    required AiTone tone,
    String companyName = '',
    String jobTitle = '',
  }) {
    return _buildPrompt(
      action: 'improveExperienceBullet',
      language: language,
      responseSchema:
          '{"title":"","originalText":"","suggestedText":"","guidancePoints":[""],"language":""}',
      inputs: [
        _profileSnapshot(profile),
        'Experience context: role="$jobTitle", company="$companyName"',
        'Original bullet: $bullet',
        'Requested tone: ${tone.code}',
      ],
      extraRules: const [
        'Rewrite the bullet with stronger action verbs.',
        'Do not add metrics unless they are clearly implied.',
      ],
    );
  }

  String improveProjectDescription({
    required ProjectInfo project,
    required CvProfile profile,
    required AiOutputLanguage language,
    required AiTone tone,
  }) {
    return _buildPrompt(
      action: 'improveProjectDescription',
      language: language,
      responseSchema:
          '{"title":"","originalText":"","suggestedText":"","guidancePoints":[""],"language":""}',
      inputs: [
        _profileSnapshot(profile),
        'Project title: ${project.title}',
        'Project role: ${project.role}',
        'Project technologies: ${project.technologies.join(', ')}',
        'Original description: ${project.description}',
        'Requested tone: ${tone.code}',
      ],
      extraRules: const [
        'Keep the project description professional and easy to scan.',
        'Do not invent features that are not hinted in the input.',
      ],
    );
  }

  String suggestSkills({
    required CvProfile profile,
    required AiOutputLanguage language,
    required AiTone tone,
    String jobTitle = '',
    String jobPostText = '',
    int maxSuggestions = 5,
  }) {
    return _buildPrompt(
      action: 'suggestSkills',
      language: language,
      responseSchema: '[{"name":"","reason":""}] up to $maxSuggestions items',
      inputs: [
        _profileSnapshot(profile),
        _jobContext(jobTitle: jobTitle, jobPostText: jobPostText),
        'Requested tone: ${tone.code}',
      ],
      extraRules: const [
        'Suggest relevant skills only.',
        'Prioritize ATS-friendly phrasing and job relevance.',
      ],
    );
  }

  String generateCoverLetter({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    required AiOutputLanguage language,
    required AiTone tone,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
    bool isShortVersion = false,
  }) {
    return _buildPrompt(
      action: 'generateCoverLetter',
      language: language,
      responseSchema:
          '{"title":"","subjectLine":"","body":"","highlights":[""],"language":"","tone":""}',
      inputs: [
        _profileSnapshot(profile),
        'Target company: $companyName',
        'Target job title: $jobTitle',
        'Hiring manager: $hiringManagerName',
        'Candidate summary: $candidateSummary',
        'Output style: ${isShortVersion ? 'short_cover_letter' : 'formal_cover_letter'}',
        'Requested tone: ${tone.code}',
        'Job post: $jobPostText',
      ],
      extraRules: [
        'Write a clean editable cover letter.',
        if (isShortVersion)
          'Keep it short, direct, and suitable for quick applications.'
        else
          'Keep it honest and role-specific.',
      ],
    );
  }

  String generateJobApplicationEmail({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    required AiOutputLanguage language,
    required AiTone tone,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
  }) {
    return _buildPrompt(
      action: 'generateJobApplicationEmail',
      language: language,
      responseSchema:
          '{"title":"","subjectLine":"","body":"","highlights":[""],"language":"","tone":""}',
      inputs: [
        _profileSnapshot(profile),
        'Target company: $companyName',
        'Target job title: $jobTitle',
        'Hiring manager: $hiringManagerName',
        'Candidate summary: $candidateSummary',
        'Requested tone: ${tone.code}',
        'Job post: $jobPostText',
      ],
      extraRules: const [
        'Write a short professional job application email.',
        'Keep the email respectful and direct.',
      ],
    );
  }

  String generateLinkedInMessage({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    required AiOutputLanguage language,
    required AiTone tone,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
  }) {
    return _buildPrompt(
      action: 'generateLinkedInMessage',
      language: language,
      responseSchema:
          '{"title":"","subjectLine":"","body":"","highlights":[""],"language":"","tone":""}',
      inputs: [
        _profileSnapshot(profile),
        'Target company: $companyName',
        'Target job title: $jobTitle',
        'Hiring manager: $hiringManagerName',
        'Candidate summary: $candidateSummary',
        'Requested tone: ${tone.code}',
        'Job post: $jobPostText',
      ],
      extraRules: const [
        'Write a short LinkedIn message that feels human and professional.',
        'Avoid sounding pushy or generic.',
      ],
    );
  }

  String generateInterviewQuestions({
    required CvProfile profile,
    required AiOutputLanguage language,
    String jobTitle = '',
    String companyName = '',
    String jobPostText = '',
    String interviewType = '',
    String answerStyle = '',
  }) {
    return _buildPrompt(
      action: 'generateInterviewQuestions',
      language: language,
      responseSchema:
          '{"title":"","language":"","questions":[{"category":"","question":"","whyItMatters":"","answerTip":"","sampleAnswer":""}]}',
      inputs: [
        _profileSnapshot(profile),
        _jobContext(jobTitle: jobTitle, jobPostText: jobPostText),
        'Company name: $companyName',
        'Interview type: $interviewType',
        'Answer style: $answerStyle',
      ],
      extraRules: const [
        'Focus on practical interview preparation.',
        'Include CV-based and role-based questions.',
        'Group questions across HR, technical, behavioral, CV-based, and company-based categories when relevant.',
        'Do not invent false experience, achievements, or skills.',
      ],
    );
  }

  String generateAtsSuggestions({
    required CvProfile profile,
    required AiOutputLanguage language,
    String jobPostText = '',
  }) {
    return _buildPrompt(
      action: 'generateAtsSuggestions',
      language: language,
      responseSchema:
          '{"headline":"","strengths":[""],"suggestions":[{"title":"","description":"","severity":""}]}',
      inputs: [_profileSnapshot(profile), 'Job post: $jobPostText'],
      extraRules: const [
        'Use ATS-friendly suggestions wording only.',
        'Do not promise guaranteed ATS results.',
      ],
    );
  }

  String analyzeJobPost({
    required String jobPostText,
    required AiOutputLanguage language,
  }) {
    return _buildPrompt(
      action: 'analyzeJobPost',
      language: language,
      responseSchema:
          '{"roleTitle":"","companyName":"","summary":"","requiredSkills":[""],"preferredSkills":[""],"keywords":[""]}',
      inputs: ['Job post: $jobPostText'],
      extraRules: const [
        'Extract practical requirements and keywords.',
        'Keep the summary concise and readable.',
      ],
    );
  }

  String calculateCvJobMatch({
    required CvProfile profile,
    required String jobPostText,
    required AiOutputLanguage language,
  }) {
    return _buildPrompt(
      action: 'calculateCvJobMatch',
      language: language,
      responseSchema:
          '{"matchScore":0,"assessment":"","matchedSkills":[""],"missingSkills":[""],"suggestedSummary":"","priorityActions":[""]}',
      inputs: [_profileSnapshot(profile), 'Job post: $jobPostText'],
      extraRules: const [
        'Provide a realistic match score, not a guaranteed result.',
        'Highlight missing skills and priority improvements.',
      ],
    );
  }

  String _buildPrompt({
    required String action,
    required AiOutputLanguage language,
    required String responseSchema,
    required List<String> inputs,
    required List<String> extraRules,
  }) {
    final buffer = StringBuffer()
      ..writeln('You are CareerMate BD AI.')
      ..writeln('Task: $action')
      ..writeln('Output language: ${language.code}')
      ..writeln('Return JSON only.')
      ..writeln('Response schema: $responseSchema')
      ..writeln('Rules:')
      ..writeln('- Keep the output professional, editable, and realistic.')
      ..writeln('- Do not invent companies, degrees, achievements, or years.')
      ..writeln(
        '- Prefer ATS-friendly wording and practical Bangladesh job context.',
      );

    for (final rule in extraRules) {
      buffer.writeln('- $rule');
    }

    buffer.writeln('Inputs:');
    for (final input in inputs.where((item) => item.trim().isNotEmpty)) {
      buffer.writeln('- $input');
    }

    return buffer.toString();
  }

  String _profileSnapshot(CvProfile profile) {
    final skills = profile.skills.map((item) => item.name.trim()).where((item) {
      return item.isNotEmpty;
    }).toList();
    final projectTech = profile.projects
        .expand((item) => item.technologies)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    return [
      'Candidate name: ${profile.personalInfo.fullName}',
      'Target role: ${profile.personalInfo.desiredRole}',
      'Professional summary: ${profile.professionalSummary}',
      'Career objective: ${profile.careerObjective}',
      'Education count: ${profile.education.length}',
      'Experience count: ${profile.experiences.length}',
      'Skills: ${skills.join(', ')}',
      'Project technologies: ${projectTech.join(', ')}',
      'Template: ${profile.template.name}',
    ].join(' | ');
  }

  String _jobContext({String jobTitle = '', String jobPostText = ''}) {
    return 'Target job title: $jobTitle | Job post: $jobPostText';
  }
}

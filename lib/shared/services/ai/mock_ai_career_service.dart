import 'dart:async';
import 'dart:convert';

import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/ai_prompt_builder.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:careermatebd/shared/services/ai/direct_openai_ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/firebase_ai_career_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiPromptBuilderProvider = Provider<AiPromptBuilder>((ref) {
  return const AiPromptBuilder();
});

final aiResponseParserProvider = Provider<AiResponseParser>((ref) {
  return const AiResponseParser();
});

final mockAiCareerServiceProvider = Provider<MockAiCareerService>((ref) {
  return MockAiCareerService(
    promptBuilder: ref.watch(aiPromptBuilderProvider),
    responseParser: ref.watch(aiResponseParserProvider),
  );
});

final aiCareerServiceProvider = Provider<AiCareerService>((ref) {
  if (EnvConfig.useFirebaseAi) {
    return ref.watch(firebaseAiCareerServiceProvider);
  }

  if (EnvConfig.shouldUseDirectOpenAiService) {
    return ref.watch(directOpenAiCareerServiceProvider);
  }

  return ref.watch(mockAiCareerServiceProvider);
});

class MockAiCareerService implements AiCareerService {
  const MockAiCareerService({
    required this.promptBuilder,
    required this.responseParser,
  });

  final AiPromptBuilder promptBuilder;
  final AiResponseParser responseParser;

  @override
  Future<Result<AiTextSuggestion>> generateProfessionalSummary({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    final prompt = promptBuilder.generateProfessionalSummary(
      profile: profile,
      language: language,
      tone: tone,
      jobTitle: jobTitle,
      jobPostText: jobPostText,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseTextSuggestion,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final role = _resolveRole(profile, jobTitle: jobTitle);
        final skills = _collectProfileSkills(profile).take(3).toList();
        final strengths = profile.experiences.isNotEmpty
            ? _localized(
                language,
                english:
                    'hands-on delivery experience and a practical understanding of team workflows',
                bangla:
                    'প্র্যাকটিক্যাল কাজের অভিজ্ঞতা এবং টিম ওয়ার্কফ্লো সম্পর্কে পরিষ্কার ধারণা',
              )
            : _localized(
                language,
                english:
                    'project-based learning and a strong fresher-friendly foundation',
                bangla:
                    'প্রজেক্টভিত্তিক শেখা এবং ফ্রেশার-ফ্রেন্ডলি শক্ত ভিত্তি',
              );

        final suggestedText = _localized(
          language,
          english:
              '${_tonePrefix(tone, language)} $role with ${_joinOrFallback(skills, fallback: 'a growing technical toolkit')} and $strengths. Prepared to contribute structured problem solving, clear communication, and ATS-friendly documentation in a professional work environment.',
          bangla:
              '${_tonePrefix(tone, language)} $role হিসেবে কাজের জন্য প্রস্তুত একজন প্রার্থী, যার ${_joinOrFallback(skills, fallback: 'প্রাসঙ্গিক টেকনিক্যাল স্কিল')} এবং $strengths আছে। পেশাদার পরিবেশে স্ট্রাকচার্ড প্রবলেম সলভিং, পরিষ্কার কমিউনিকেশন, এবং ATS-friendly ডকুমেন্টেশন দিয়ে অবদান রাখতে প্রস্তুত।',
        );

        return jsonEncode({
          'title': _localized(
            language,
            english: 'Professional Summary',
            bangla: 'পেশাগত সারসংক্ষেপ',
          ),
          'originalText': profile.professionalSummary,
          'suggestedText': suggestedText,
          'guidancePoints': [
            _localized(
              language,
              english: 'Keep the summary to 2-3 focused lines.',
              bangla: 'সারসংক্ষেপ ২-৩টি ফোকাসড লাইনের মধ্যে রাখুন।',
            ),
            _localized(
              language,
              english: 'Align the first sentence with your target role.',
              bangla: 'প্রথম লাইনে আপনার টার্গেট রোল স্পষ্ট করুন।',
            ),
          ],
          'language': language.code,
        });
      },
    );
  }

  @override
  Future<Result<AiTextSuggestion>> generateCareerObjective({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
  }) {
    final prompt = promptBuilder.generateCareerObjective(
      profile: profile,
      language: language,
      tone: tone,
      jobTitle: jobTitle,
      jobPostText: jobPostText,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseTextSuggestion,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final role = _resolveRole(profile, jobTitle: jobTitle);
        final suggestedText = _localized(
          language,
          english:
              '${_toneObjectiveLead(tone, language)} as a $role by applying practical skills, learning from real projects, and contributing measurable value to a growth-focused team.',
          bangla:
              '${_toneObjectiveLead(tone, language)} $role হিসেবে, যেখানে প্র্যাকটিক্যাল স্কিল, বাস্তব প্রজেক্টের অভিজ্ঞতা, এবং ধারাবাহিক শেখার মাধ্যমে একটি গ্রোথ-ফোকাসড টিমে কার্যকর অবদান রাখতে পারি।',
        );

        return jsonEncode({
          'title': _localized(
            language,
            english: 'Career Objective',
            bangla: 'ক্যারিয়ার অবজেক্টিভ',
          ),
          'originalText': profile.careerObjective,
          'suggestedText': suggestedText,
          'guidancePoints': [
            _localized(
              language,
              english: 'Mention learning mindset without sounding generic.',
              bangla:
                  'লার্নিং মাইন্ডসেট উল্লেখ করুন, তবে যেন খুব জেনেরিক না শোনায়।',
            ),
            _localized(
              language,
              english: 'Keep the objective aligned with the target role.',
              bangla: 'অবজেক্টিভকে টার্গেট রোলের সাথে মিলিয়ে লিখুন।',
            ),
          ],
          'language': language.code,
        });
      },
    );
  }

  @override
  Future<Result<AiTextSuggestion>> improveExperienceBullet({
    required String bullet,
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String companyName = '',
    String jobTitle = '',
  }) {
    final trimmedBullet = bullet.trim();
    if (trimmedBullet.isEmpty) {
      return Future.value(
        const FailureResult(
          Failure(
            'AI generation failed. Please provide an experience bullet first.',
            code: 'ai_validation_error',
          ),
        ),
      );
    }

    final prompt = promptBuilder.improveExperienceBullet(
      bullet: trimmedBullet,
      profile: profile,
      language: language,
      tone: tone,
      companyName: companyName,
      jobTitle: jobTitle,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseTextSuggestion,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final rewrittenBase = _professionalizeStatement(trimmedBullet);
        final context = [
          if (jobTitle.trim().isNotEmpty) jobTitle.trim(),
          if (companyName.trim().isNotEmpty) companyName.trim(),
        ].join(' at ');

        final suggestedText = _localized(
          language,
          english:
              '$rewrittenBase${context.isEmpty ? '' : ' in the $context role'}, ${_toneExecutionSuffix(tone, language)}.',
          bangla:
              '$rewrittenBase${context.isEmpty ? '' : ' $context ভূমিকায়'}, ${_toneExecutionSuffix(tone, language)}।',
        );

        return jsonEncode({
          'title': _localized(
            language,
            english: 'Improved Experience Bullet',
            bangla: 'উন্নত এক্সপেরিয়েন্স বুলেট',
          ),
          'originalText': trimmedBullet,
          'suggestedText': suggestedText,
          'guidancePoints': [
            _localized(
              language,
              english: 'Start bullets with action-driven verbs.',
              bangla: 'বুলেটগুলো অ্যাকশন-ড্রিভেন ভার্ব দিয়ে শুরু করুন।',
            ),
            _localized(
              language,
              english: 'Add measurable impact later if you have exact numbers.',
              bangla: 'সঠিক সংখ্যা থাকলে পরে measurable impact যোগ করতে পারেন।',
            ),
          ],
          'language': language.code,
        });
      },
    );
  }

  @override
  Future<Result<AiTextSuggestion>> improveProjectDescription({
    required ProjectInfo project,
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
  }) {
    final prompt = promptBuilder.improveProjectDescription(
      project: project,
      profile: profile,
      language: language,
      tone: tone,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseTextSuggestion,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final techStack = _joinOrFallback(
          project.technologies,
          fallback: _localized(
            language,
            english: 'relevant tools',
            bangla: 'প্রাসঙ্গিক টুল',
          ),
        );
        final suggestedText = _localized(
          language,
          english:
              'Built ${project.title.isEmpty ? 'a practical project' : project.title} ${project.role.trim().isEmpty ? '' : 'as ${project.role.trim()} '}using $techStack. The project focused on ${_normalizeSentence(project.description, fallback: 'solving a practical user problem')} and demonstrates ${_toneProjectSuffix(tone, language)}.',
          bangla:
              '${project.title.isEmpty ? 'একটি ব্যবহারিক প্রজেক্ট' : project.title} ${project.role.trim().isEmpty ? '' : '${project.role.trim()} হিসেবে '} $techStack ব্যবহার করে তৈরি করেছি। এই প্রজেক্টে ${_normalizeSentence(project.description, fallback: 'একটি বাস্তব ব্যবহারকারীর সমস্যা সমাধানে ফোকাস করা হয়েছে')} এবং এটি ${_toneProjectSuffix(tone, language)} তুলে ধরে।',
        );

        return jsonEncode({
          'title': _localized(
            language,
            english: 'Improved Project Description',
            bangla: 'উন্নত প্রজেক্ট ডেসক্রিপশন',
          ),
          'originalText': project.description,
          'suggestedText': suggestedText,
          'guidancePoints': [
            _localized(
              language,
              english: 'Highlight the problem, your role, and the tools used.',
              bangla:
                  'প্রবলেম, আপনার ভূমিকা, এবং ব্যবহৃত টুলগুলো পরিষ্কারভাবে উল্লেখ করুন।',
            ),
            _localized(
              language,
              english: 'Keep project descriptions readable in 2-3 lines.',
              bangla: 'প্রজেক্ট ডেসক্রিপশন ২-৩টি পড়তে সহজ লাইনের মধ্যে রাখুন।',
            ),
          ],
          'language': language.code,
        });
      },
    );
  }

  @override
  Future<Result<List<SkillSuggestion>>> suggestSkills({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
    String jobTitle = '',
    String jobPostText = '',
    int maxSuggestions = 5,
  }) {
    final prompt = promptBuilder.suggestSkills(
      profile: profile,
      language: language,
      tone: tone,
      jobTitle: jobTitle,
      jobPostText: jobPostText,
      maxSuggestions: maxSuggestions,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseSkillSuggestions,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final currentSkills = _collectProfileSkills(
          profile,
        ).map((item) => item.toLowerCase()).toSet();
        final targetKeywords = _extractKeywords(
          jobPostText,
          roleHint: jobTitle,
        );
        final roleSuggestions = _roleBasedSuggestions(
          _resolveRole(profile, jobTitle: jobTitle),
        );
        final suggestions = <Map<String, String>>[];

        for (final skill in [...targetKeywords, ...roleSuggestions]) {
          if (suggestions.length >= maxSuggestions) {
            break;
          }

          if (_hasSkill(currentSkills, skill)) {
            continue;
          }

          suggestions.add({
            'name': skill,
            'reason': _localized(
              language,
              english:
                  'Relevant for ATS matching and ${_toneSkillReason(tone, language)}.',
              bangla:
                  'টার্গেট রোলের সাথে ${_toneSkillReason(tone, language)} এবং ATS matching-এর জন্য প্রাসঙ্গিক।',
            ),
          });
        }

        if (suggestions.isEmpty) {
          suggestions.add({
            'name': _localized(
              language,
              english: 'Communication',
              bangla: 'Communication',
            ),
            'reason': _localized(
              language,
              english:
                  'Useful as a supporting skill when the core technical stack is already covered.',
              bangla:
                  'মূল টেকনিক্যাল স্কিল কভার থাকলে এটি একটি সহায়ক স্কিল হিসেবে কার্যকর।',
            ),
          });
        }

        return jsonEncode(suggestions);
      },
    );
  }

  @override
  Future<Result<AiDocumentDraft>> generateCoverLetter({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
    bool isShortVersion = false,
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.formal,
  }) {
    final prompt = promptBuilder.generateCoverLetter(
      profile: profile,
      companyName: companyName,
      jobTitle: jobTitle,
      language: language,
      tone: tone,
      jobPostText: jobPostText,
      hiringManagerName: hiringManagerName,
      candidateSummary: candidateSummary,
      isShortVersion: isShortVersion,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseDocumentDraft,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final greeting = _documentGreeting(
          language: language,
          hiringManagerName: hiringManagerName,
        );
        final summary = _documentCandidateSummary(
          profile: profile,
          candidateSummary: candidateSummary,
          language: language,
        );
        final closing = _documentClosing(language);
        final body = _localized(
          language,
          english: isShortVersion
              ? '$greeting\n\nI am applying for the $jobTitle opportunity at $companyName. $summary I believe this background can help me contribute with clear communication, reliable execution, and a professional attitude from day one.\n\nI would welcome the opportunity to share more about my fit for the role.\n\n$closing\n${_safeName(profile)}'
              : '$greeting\n\nI am writing to apply for the $jobTitle position at $companyName. $summary My focus on practical execution, ATS-friendly communication, and steady learning makes me confident that I can contribute with professionalism.\n\nThrough my projects, coursework, and profile development, I have built experience in structured problem solving, clear documentation, and delivering user-focused work. I would welcome the opportunity to discuss how I can support your team and grow in this role.\n\n$closing\n${_safeName(profile)}',
          bangla: isShortVersion
              ? '$greeting\n\n$companyName-এ $jobTitle পদের জন্য আবেদন করছি। $summary আমি বিশ্বাস করি এই ব্যাকগ্রাউন্ড আমাকে পরিষ্কার কমিউনিকেশন, দায়িত্বশীল কাজের ধরণ, এবং পেশাদার মনোভাব নিয়ে অবদান রাখতে সহায়তা করবে।\n\nসুযোগ পেলে এই রোলের জন্য আমার উপযুক্ততা নিয়ে আরও শেয়ার করতে আগ্রহী।\n\n$closing\n${_safeName(profile)}'
              : '$greeting\n\n$companyName-এ $jobTitle পদের জন্য আবেদন করছি। $summary ব্যবহারিক এক্সিকিউশন, ATS-friendly কমিউনিকেশন, এবং ধারাবাহিক শেখার ওপর আমার ফোকাস আমাকে আত্মবিশ্বাস দেয় যে আমি পেশাদারভাবে অবদান রাখতে পারব।\n\nআমার প্রজেক্ট, coursework, এবং প্রোফাইল ডেভেলপমেন্টের মাধ্যমে structured problem solving, clear documentation, এবং user-focused কাজের অভিজ্ঞতা তৈরি হয়েছে। আপনার টিমকে কীভাবে সাপোর্ট করতে পারি এবং এই রোলে কীভাবে গ্রো করতে পারি, সে বিষয়ে আলোচনার সুযোগ পেলে ভালো লাগবে।\n\n$closing\n${_safeName(profile)}',
        );

        return jsonEncode({
          'title': _localized(
            language,
            english: isShortVersion
                ? 'Short Cover Letter Draft'
                : 'Cover Letter Draft',
            bangla: isShortVersion
                ? 'সংক্ষিপ্ত কভার লেটার ড্রাফট'
                : 'কভার লেটার ড্রাফট',
          ),
          'subjectLine': _localized(
            language,
            english: 'Application for $jobTitle',
            bangla: '$jobTitle পদের জন্য আবেদন',
          ),
          'body': body,
          'highlights': [
            _localized(
              language,
              english: 'Role-focused introduction',
              bangla: 'রোল-ফোকাসড পরিচিতি',
            ),
            _localized(
              language,
              english: 'Editable professional tone',
              bangla: 'এডিটযোগ্য পেশাদার টোন',
            ),
          ],
          'language': language.code,
          'tone': tone.code,
        });
      },
    );
  }

  @override
  Future<Result<AiDocumentDraft>> generateJobApplicationEmail({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.formal,
  }) {
    final prompt = promptBuilder.generateJobApplicationEmail(
      profile: profile,
      companyName: companyName,
      jobTitle: jobTitle,
      language: language,
      tone: tone,
      jobPostText: jobPostText,
      hiringManagerName: hiringManagerName,
      candidateSummary: candidateSummary,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseDocumentDraft,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final greeting = _documentGreeting(
          language: language,
          hiringManagerName: hiringManagerName,
          fallbackEnglish: 'Dear Hiring Team,',
          fallbackBangla: 'প্রিয় Hiring Team,',
        );
        final summary = _documentCandidateSummary(
          profile: profile,
          candidateSummary: candidateSummary,
          language: language,
        );
        final body = _localized(
          language,
          english:
              '$greeting\n\nPlease find my application for the $jobTitle role at $companyName. $summary I have attached my CV for review and would appreciate the opportunity to discuss how I can support your team.\n\nThank you for your time.\n\nBest regards,\n${_safeName(profile)}',
          bangla:
              '$greeting\n\n$companyName-এ $jobTitle পদের জন্য আমার আবেদন পাঠালাম। $summary আমার CV সংযুক্ত করা হয়েছে। আমি কীভাবে আপনার টিমকে সহায়তা করতে পারি, সে বিষয়ে আলোচনার সুযোগ পেলে কৃতজ্ঞ থাকব।\n\nধন্যবাদ।\n\nশুভেচ্ছান্তে,\n${_safeName(profile)}',
        );

        return jsonEncode({
          'title': _localized(
            language,
            english: 'Job Application Email',
            bangla: 'জব অ্যাপ্লিকেশন ইমেইল',
          ),
          'subjectLine': _localized(
            language,
            english: 'Application for $jobTitle - ${_safeName(profile)}',
            bangla: '$jobTitle পদের আবেদন - ${_safeName(profile)}',
          ),
          'body': body,
          'highlights': [
            _localized(
              language,
              english: 'Short and attachment-ready email format',
              bangla: 'ছোট এবং attachment-ready ইমেইল ফরম্যাট',
            ),
          ],
          'language': language.code,
          'tone': tone.code,
        });
      },
    );
  }

  @override
  Future<Result<AiDocumentDraft>> generateLinkedInMessage({
    required CvProfile profile,
    required String companyName,
    required String jobTitle,
    String jobPostText = '',
    String hiringManagerName = '',
    String candidateSummary = '',
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.confident,
  }) {
    final prompt = promptBuilder.generateLinkedInMessage(
      profile: profile,
      companyName: companyName,
      jobTitle: jobTitle,
      language: language,
      tone: tone,
      jobPostText: jobPostText,
      hiringManagerName: hiringManagerName,
      candidateSummary: candidateSummary,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseDocumentDraft,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final introName = hiringManagerName.trim();
        final summary = _documentCandidateSummary(
          profile: profile,
          candidateSummary: candidateSummary,
          language: language,
        );
        final body = _localized(
          language,
          english:
              '${introName.isEmpty ? 'Hello' : 'Hello $introName'}, I noticed the $jobTitle opportunity at $companyName and wanted to introduce myself briefly. $summary This role feels especially relevant to my background, and I would be glad to share my CV if helpful.',
          bangla:
              '${introName.isEmpty ? 'হ্যালো' : 'হ্যালো $introName'}, $companyName-এ $jobTitle সুযোগটি দেখে সংক্ষেপে নিজের পরিচয় দিতে চাচ্ছি। $summary এই রোলটি আমার ব্যাকগ্রাউন্ডের সঙ্গে ভালোভাবে মিলে যায়, এবং প্রয়োজন হলে আমি আমার CV শেয়ার করতে পারি।',
        );

        return jsonEncode({
          'title': _localized(
            language,
            english: 'LinkedIn Message Draft',
            bangla: 'LinkedIn মেসেজ ড্রাফট',
          ),
          'subjectLine': '',
          'body': body,
          'highlights': [
            _localized(
              language,
              english: 'Short networking-friendly message',
              bangla: 'সংক্ষিপ্ত networking-friendly মেসেজ',
            ),
          ],
          'language': language.code,
          'tone': tone.code,
        });
      },
    );
  }

  @override
  Future<Result<InterviewQuestionSet>> generateInterviewQuestions({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    String jobTitle = '',
    String companyName = '',
    String jobPostText = '',
    String interviewType = '',
    String answerStyle = '',
  }) {
    final prompt = promptBuilder.generateInterviewQuestions(
      profile: profile,
      language: language,
      jobTitle: jobTitle,
      companyName: companyName,
      jobPostText: jobPostText,
      interviewType: interviewType,
      answerStyle: answerStyle,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseInterviewQuestions,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final role = _resolveRole(profile, jobTitle: jobTitle);
        final company = companyName.trim();
        final projectTitle = profile.projects.isNotEmpty
            ? profile.projects.first.title
            : _localized(
                language,
                english: 'one of your recent projects',
                bangla: 'আপনার সাম্প্রতিক একটি প্রজেক্ট',
              );
        final primarySkill = _collectProfileSkills(profile).isNotEmpty
            ? _collectProfileSkills(profile).first
            : role;
        final answerDepth = switch (answerStyle.trim().toLowerCase()) {
          'short' => _localized(
            language,
            english: 'Keep the answer short and direct.',
            bangla: 'উত্তরটি ছোট, সরাসরি, এবং পরিষ্কার রাখুন।',
          ),
          'detailed' => _localized(
            language,
            english:
                'Add a little more context, a practical example, and a clear result.',
            bangla:
                'আরও একটু context, practical example, এবং একটি পরিষ্কার result যোগ করুন।',
          ),
          _ => _localized(
            language,
            english:
                'Keep the answer professional, practical, and easy to follow.',
            bangla: 'উত্তরটি পেশাদার, practical, এবং সহজবোধ্য রাখুন।',
          ),
        };
        final companyQuestionTarget = company.isEmpty
            ? _localized(language, english: 'this job', bangla: 'এই চাকরি')
            : company;

        return jsonEncode({
          'title': _localized(
            language,
            english: '$role Interview Preparation',
            bangla: '$role ইন্টারভিউ প্রস্তুতি',
          ),
          'language': language.code,
          'questions': [
            {
              'category': 'hr',
              'question': _localized(
                language,
                english: 'Tell me about yourself.',
                bangla: 'নিজের সম্পর্কে বলুন।',
              ),
              'whyItMatters': _localized(
                language,
                english:
                    'This tests how clearly you position your background for the role.',
                bangla:
                    'এই প্রশ্নে দেখা হয় আপনি রোলের জন্য নিজের ব্যাকগ্রাউন্ড কত পরিষ্কারভাবে উপস্থাপন করতে পারেন।',
              ),
              'answerTip': _localized(
                language,
                english:
                    'Start with your current focus, then mention skills and relevant projects.',
                bangla:
                    'প্রথমে আপনার বর্তমান ফোকাস বলুন, তারপর স্কিল ও প্রাসঙ্গিক প্রজেক্ট উল্লেখ করুন।',
              ),
              'sampleAnswer': _localized(
                language,
                english:
                    'I am building my career in $role with strong interest in practical execution, clear communication, and project-based problem solving.',
                bangla:
                    'আমি $role-এ আমার ক্যারিয়ার গড়ে তুলছি এবং practical execution, clear communication, ও project-based problem solving-এ আমার বিশেষ আগ্রহ আছে।',
              ),
            },
            {
              'category': 'company_based',
              'question': _localized(
                language,
                english: 'Why do you want $companyQuestionTarget?',
                bangla: '$companyQuestionTarget কেন চান?',
              ),
              'whyItMatters': _localized(
                language,
                english:
                    'The interviewer wants to see alignment between your goal and the employer or role.',
                bangla:
                    'ইন্টারভিউয়ার দেখতে চান আপনার লক্ষ্য employer বা role-এর সাথে কতটা সামঞ্জস্যপূর্ণ।',
              ),
              'answerTip': _localized(
                language,
                english:
                    'Connect the role to your skills, projects, learning direction, and what attracts you to the work.',
                bangla:
                    'রোলটিকে আপনার স্কিল, প্রজেক্ট, শেখার দিক, এবং কাজটির প্রতি আপনার আগ্রহের সাথে যুক্ত করুন।',
              ),
              'sampleAnswer': _localized(
                language,
                english:
                    'This role matches the type of work I have been preparing for through my skills and project experience, especially in ${_joinOrFallback(_collectProfileSkills(profile).take(2).toList(), fallback: role)}.',
                bangla:
                    'আমার স্কিল ও প্রজেক্ট অভিজ্ঞতার মাধ্যমে যে ধরনের কাজের জন্য প্রস্তুতি নিচ্ছি, এই রোলটি তার সঙ্গে ভালোভাবে মিলে যায়, বিশেষ করে ${_joinOrFallback(_collectProfileSkills(profile).take(2).toList(), fallback: role)}-এ।',
              ),
            },
            {
              'category': profile.projects.isNotEmpty
                  ? 'cv_based'
                  : 'behavioral',
              'question': _localized(
                language,
                english: 'Explain $projectTitle.',
                bangla: '$projectTitle সম্পর্কে ব্যাখ্যা করুন।',
              ),
              'whyItMatters': _localized(
                language,
                english:
                    'This checks how well you understand your own practical work.',
                bangla:
                    'এতে দেখা হয় আপনি নিজের practical কাজ কতটা ভালোভাবে বোঝেন।',
              ),
              'answerTip': _localized(
                language,
                english:
                    'Explain the problem, your role, tools used, and the outcome.',
                bangla:
                    'প্রবলেম, আপনার ভূমিকা, ব্যবহৃত টুল, এবং ফলাফল একসাথে ব্যাখ্যা করুন।',
              ),
              'sampleAnswer': _localized(
                language,
                english:
                    '$projectTitle helped me apply my technical skills in a practical workflow and improve how I plan, build, and refine user-facing solutions.',
                bangla:
                    '$projectTitle আমাকে practical workflow-এ আমার technical skills ব্যবহার করতে সাহায্য করেছে এবং user-facing solution plan, build, ও refine করার দক্ষতা বাড়িয়েছে।',
              ),
            },
            {
              'category': 'technical',
              'question': _localized(
                language,
                english:
                    'How would you explain your practical experience with $primarySkill?',
                bangla:
                    '$primarySkill নিয়ে আপনার practical experience কীভাবে ব্যাখ্যা করবেন?',
              ),
              'whyItMatters': _localized(
                language,
                english:
                    'The interviewer wants to see whether you can connect tools and skills to real work.',
                bangla:
                    'ইন্টারভিউয়ার দেখতে চান আপনি টুল ও স্কিলকে বাস্তব কাজের সাথে কতটা ভালোভাবে যুক্ত করতে পারেন।',
              ),
              'answerTip': _localized(
                language,
                english:
                    '$answerDepth Mention where you used the skill, what you handled, and what you learned.',
                bangla:
                    '$answerDepth কোথায় skill ব্যবহার করেছেন, কী handle করেছেন, এবং কী শিখেছেন তা বলুন।',
              ),
              'sampleAnswer': _localized(
                language,
                english:
                    'I have used $primarySkill through practical learning and project work, where I focused on implementation quality, problem solving, and steady improvement.',
                bangla:
                    'আমি $primarySkill practical learning এবং project work-এর মাধ্যমে ব্যবহার করেছি, যেখানে implementation quality, problem solving, এবং ধারাবাহিক উন্নতির দিকে ফোকাস করেছি।',
              ),
            },
            {
              'category': 'behavioral',
              'question': _localized(
                language,
                english: 'What is one strength you will bring to this role?',
                bangla: 'এই রোলে আপনি কোন একটি শক্তি নিয়ে আসবেন?',
              ),
              'whyItMatters': _localized(
                language,
                english:
                    'The employer wants evidence of self-awareness and job fit.',
                bangla: 'নিয়োগদাতা আপনার self-awareness এবং job fit বুঝতে চান।',
              ),
              'answerTip': _localized(
                language,
                english:
                    'Choose one clear strength and support it with a recent example.',
                bangla:
                    'একটি পরিষ্কার শক্তি বেছে নিন এবং সাম্প্রতিক উদাহরণ দিয়ে সমর্থন করুন।',
              ),
              'sampleAnswer': _localized(
                language,
                english:
                    'One strength I bring is structured follow-through. I try to complete work with clarity, documentation, and steady improvement.',
                bangla:
                    'আমার একটি বড় শক্তি হলো structured follow-through। আমি কাজ শেষ করতে চাই clarity, documentation, এবং ধারাবাহিক উন্নতির মাধ্যমে।',
              ),
            },
            {
              'category': profile.experiences.isEmpty ? 'general' : 'cv_based',
              'question': _localized(
                language,
                english: profile.experiences.isEmpty
                    ? 'As a fresher, how will you prove that you are ready to learn quickly?'
                    : 'Which experience on your CV best prepares you for this role?',
                bangla: profile.experiences.isEmpty
                    ? 'ফ্রেশার হিসেবে আপনি কীভাবে প্রমাণ করবেন যে দ্রুত শিখতে প্রস্তুত?'
                    : 'আপনার CV-এর কোন experience এই role-এর জন্য আপনাকে সবচেয়ে ভালোভাবে প্রস্তুত করেছে?',
              ),
              'whyItMatters': _localized(
                language,
                english:
                    'This tests self-awareness and how honestly you connect your background to the role.',
                bangla:
                    'এতে বোঝা যায় আপনি নিজের background-কে role-এর সাথে কতটা honest ও পরিষ্কারভাবে যুক্ত করতে পারেন।',
              ),
              'answerTip': _localized(
                language,
                english:
                    '$answerDepth Use one specific project, internship, course, or responsibility as proof.',
                bangla:
                    '$answerDepth একটি নির্দিষ্ট project, internship, course, বা responsibility উদাহরণ হিসেবে ব্যবহার করুন।',
              ),
              'sampleAnswer': _localized(
                language,
                english: profile.experiences.isEmpty
                    ? 'Even without full-time experience, I have built readiness through project work, consistent practice, and clear ownership of what I learn and deliver.'
                    : 'The strongest preparation on my CV is the work where I had to deliver practical results, communicate clearly, and improve based on feedback.',
                bangla: profile.experiences.isEmpty
                    ? 'ফুল-টাইম experience না থাকলেও project work, ধারাবাহিক practice, এবং শেখা ও delivery-র পরিষ্কার ownership-এর মাধ্যমে আমি প্রস্তুতি তৈরি করেছি।'
                    : 'আমার CV-তে সবচেয়ে শক্ত প্রস্তুতি হলো সেই কাজগুলো, যেখানে practical result দিতে হয়েছে, পরিষ্কার communication করতে হয়েছে, এবং feedback-এর ভিত্তিতে improve করতে হয়েছে।',
              ),
            },
          ],
        });
      },
    );
  }

  @override
  Future<Result<AtsSuggestionReport>> generateAtsSuggestions({
    required CvProfile profile,
    AiOutputLanguage language = AiOutputLanguage.english,
    String jobPostText = '',
  }) {
    final prompt = promptBuilder.generateAtsSuggestions(
      profile: profile,
      language: language,
      jobPostText: jobPostText,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseAtsSuggestions,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final strengths = <String>[
          if (profile.personalInfo.email.trim().isNotEmpty &&
              profile.personalInfo.phone.trim().isNotEmpty)
            _localized(
              language,
              english: 'Contact information is available.',
              bangla: 'কন্টাক্ট ইনফরমেশন দেওয়া আছে।',
            ),
          if (profile.skills.length >= 2)
            _localized(
              language,
              english: 'Core skills section is present.',
              bangla: 'কোর স্কিলস সেকশন আছে।',
            ),
          if (profile.projects.isNotEmpty)
            _localized(
              language,
              english: 'Projects help strengthen the CV for fresher roles.',
              bangla:
                  'প্রজেক্ট সেকশন ফ্রেশার রোলের জন্য CV-কে শক্তিশালী করেছে।',
            ),
        ];

        final suggestions = <Map<String, String>>[];

        if (profile.professionalSummary.trim().length < 40) {
          suggestions.add({
            'title': _localized(
              language,
              english: 'Strengthen the professional summary',
              bangla: 'প্রফেশনাল সামারি আরও শক্তিশালী করুন',
            ),
            'description': _localized(
              language,
              english:
                  'A sharper summary can improve first-scan readability for recruiters.',
              bangla:
                  'আরও শক্তিশালী সামারি recruiters-এর প্রথম স্ক্যানে CV-কে বেশি readable করবে।',
            ),
            'severity': AtsSuggestionSeverity.high.code,
          });
        }

        if (profile.skills.length < 4) {
          suggestions.add({
            'title': _localized(
              language,
              english: 'Expand relevant skills',
              bangla: 'প্রাসঙ্গিক স্কিলস বাড়ান',
            ),
            'description': _localized(
              language,
              english:
                  'Add more role-matching skills so the CV is easier to scan.',
              bangla: 'রোল-ম্যাচিং স্কিলস বাড়ালে CV স্ক্যান করা আরও সহজ হবে।',
            ),
            'severity': AtsSuggestionSeverity.medium.code,
          });
        }

        if (profile.experiences.isEmpty && profile.projects.isNotEmpty) {
          suggestions.add({
            'title': _localized(
              language,
              english: 'Use projects as proof of practical work',
              bangla:
                  'প্র্যাকটিক্যাল কাজের প্রমাণ হিসেবে প্রজেক্ট ব্যবহার করুন',
            ),
            'description': _localized(
              language,
              english:
                  'For fresher CVs, strong project descriptions can compensate for limited experience.',
              bangla:
                  'ফ্রেশার CV-তে সীমিত অভিজ্ঞতার জায়গায় শক্তিশালী প্রজেক্ট ডেসক্রিপশন সহায়তা করে।',
            ),
            'severity': AtsSuggestionSeverity.medium.code,
          });
        }

        final jobKeywords = _extractKeywords(jobPostText);
        final missingKeywords = jobKeywords
            .where(
              (keyword) => !_hasSkill(
                _collectProfileSkills(
                  profile,
                ).map((item) => item.toLowerCase()).toSet(),
                keyword,
              ),
            )
            .take(2)
            .toList();

        if (missingKeywords.isNotEmpty) {
          suggestions.add({
            'title': _localized(
              language,
              english: 'Review job-post keyword coverage',
              bangla: 'জব পোস্টের keyword coverage রিভিউ করুন',
            ),
            'description': _localized(
              language,
              english:
                  'Consider whether ${missingKeywords.join(', ')} should appear naturally in your CV.',
              bangla:
                  '${missingKeywords.join(', ')} স্বাভাবিকভাবে CV-তে যুক্ত করা যায় কি না, তা বিবেচনা করুন।',
            ),
            'severity': AtsSuggestionSeverity.low.code,
          });
        }

        return jsonEncode({
          'headline': _localized(
            language,
            english:
                'This CV has a solid base, with a few ATS-friendly improvements available.',
            bangla:
                'এই CV-এর একটি ভালো ভিত্তি আছে, তবে কিছু ATS-friendly উন্নতির সুযোগ রয়েছে।',
          ),
          'strengths': strengths,
          'suggestions': suggestions,
        });
      },
    );
  }

  @override
  Future<Result<JobPostAnalysis>> analyzeJobPost({
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    final prompt = promptBuilder.analyzeJobPost(
      jobPostText: jobPostText,
      language: language,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseJobPostAnalysis,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final payload = _buildJobPostAnalysisPayload(
          jobPostText: jobPostText,
          language: language,
        );
        return jsonEncode(payload);
      },
    );
  }

  @override
  Future<Result<CvJobMatchResult>> calculateCvJobMatch({
    required CvProfile profile,
    required String jobPostText,
    AiOutputLanguage language = AiOutputLanguage.english,
  }) {
    final prompt = promptBuilder.calculateCvJobMatch(
      profile: profile,
      jobPostText: jobPostText,
      language: language,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseCvJobMatch,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final analysis = _buildJobPostAnalysisPayload(
          jobPostText: jobPostText,
          language: language,
        );
        final profileSkills = _collectProfileSkills(profile);
        final profileSkillSet = profileSkills
            .map((item) => item.toLowerCase())
            .toSet();
        final requiredSkills = (analysis['requiredSkills'] as List<dynamic>)
            .map((item) => item.toString())
            .toList();

        final matchedSkills = requiredSkills.where((skill) {
          return _hasSkill(profileSkillSet, skill);
        }).toList();

        final missingSkills = requiredSkills.where((skill) {
          return !_hasSkill(profileSkillSet, skill);
        }).toList();

        var score = 40;
        score += matchedSkills.length * 10;
        if (profile.professionalSummary.trim().isNotEmpty) {
          score += 8;
        }
        if (profile.education.isNotEmpty) {
          score += 7;
        }
        if (profile.projects.isNotEmpty) {
          score += 8;
        }
        if (profile.experiences.isNotEmpty) {
          score += 10;
        }
        score -= missingSkills.length * 4;
        score = score.clamp(35, 92);

        final assessment = switch (score) {
          >= 80 => _localized(
            language,
            english: 'Strong fit with a few refinements needed before sending.',
            bangla: 'ভালো মিল আছে, তবে পাঠানোর আগে কিছু refinement দরকার।',
          ),
          >= 65 => _localized(
            language,
            english:
                'Moderate fit. Targeted edits can improve relevance quickly.',
            bangla:
                'মোটামুটি ভালো মিল আছে। টার্গেটেড এডিট করলে relevance দ্রুত বাড়তে পারে।',
          ),
          _ => _localized(
            language,
            english:
                'Early-stage fit. Strengthen the summary, keywords, and supporting sections.',
            bangla:
                'এখনও প্রাথমিক পর্যায়ের fit। সামারি, keywords, এবং supporting section শক্তিশালী করুন।',
          ),
        };

        final priorityActions = <String>[
          if (missingSkills.isNotEmpty)
            _localized(
              language,
              english:
                  'Review whether these skills can be reflected honestly: ${missingSkills.join(', ')}.',
              bangla:
                  'এই স্কিলগুলো সৎভাবে CV-তে যোগ করা যায় কি না রিভিউ করুন: ${missingSkills.join(', ')}।',
            ),
          if (profile.professionalSummary.trim().isEmpty)
            _localized(
              language,
              english: 'Add a role-matching professional summary.',
              bangla: 'রোল-ম্যাচিং প্রফেশনাল সামারি যুক্ত করুন।',
            ),
          if (profile.projects.isEmpty)
            _localized(
              language,
              english: 'Add at least one strong project entry.',
              bangla: 'কমপক্ষে একটি শক্তিশালী প্রজেক্ট এন্ট্রি যুক্ত করুন।',
            ),
        ];

        final roleTitle = analysis['roleTitle'].toString();
        final suggestedSummary = _localized(
          language,
          english:
              'Position the CV for $roleTitle by highlighting ${_joinOrFallback(matchedSkills.take(2).toList(), fallback: 'your most relevant strengths')} and practical project outcomes.',
          bangla:
              '$roleTitle রোলের জন্য CV-কে পজিশন করতে ${_joinOrFallback(matchedSkills.take(2).toList(), fallback: 'আপনার সবচেয়ে প্রাসঙ্গিক শক্তিগুলো')} এবং practical project outcome সামনে আনুন।',
        );

        return jsonEncode({
          'matchScore': score,
          'assessment': assessment,
          'matchedSkills': matchedSkills,
          'missingSkills': missingSkills,
          'suggestedSummary': suggestedSummary,
          'priorityActions': priorityActions.isEmpty
              ? [
                  _localized(
                    language,
                    english:
                        'Refine wording and keep the final CV ATS-friendly and concise.',
                    bangla:
                        'ভাষা আরও refine করুন এবং final CV-কে ATS-friendly ও concise রাখুন।',
                  ),
                ]
              : priorityActions,
        });
      },
    );
  }

  @override
  Future<Result<CvTailoringSuggestion>> tailorCvForJob({
    required CvProfile profile,
    required String jobPostText,
    String jobTitle = '',
    String companyName = '',
    List<String> targetKeywords = const [],
    AiOutputLanguage language = AiOutputLanguage.english,
    AiTone tone = AiTone.professional,
  }) {
    final prompt = promptBuilder.tailorCvForJob(
      profile: profile,
      language: language,
      tone: tone,
      jobTitle: jobTitle,
      companyName: companyName,
      jobPostText: jobPostText,
      targetKeywords: targetKeywords,
    );

    return _runRequest(
      prompt: prompt,
      parser: responseParser.parseCvTailoring,
      failureMessage: 'AI generation failed. Please try again.',
      rawResponseBuilder: () {
        final role = _resolveRole(profile, jobTitle: jobTitle);
        final keywords = targetKeywords.isNotEmpty
            ? targetKeywords
            : _extractKeywords(jobPostText, roleHint: jobTitle);
        final lowerKeywords = keywords
            .map((keyword) => keyword.toLowerCase())
            .toList();

        final existingSkills = _collectProfileSkills(profile);
        final matchingSkills = <String>[
          for (final skill in existingSkills)
            if (lowerKeywords.any(
              (keyword) =>
                  skill.toLowerCase().contains(keyword) ||
                  keyword.contains(skill.toLowerCase()),
            ))
              skill,
        ];
        final remainingSkills = <String>[
          for (final skill in existingSkills)
            if (!matchingSkills.contains(skill)) skill,
        ];
        final emphasizedSkills = <String>[...matchingSkills, ...remainingSkills];
        final resolvedSkills = emphasizedSkills.isEmpty
            ? keywords.take(5).toList()
            : emphasizedSkills;

        final rewrittenBullets = <Map<String, String>>[];
        for (final experience in profile.experiences) {
          for (final highlight in experience.highlights) {
            final trimmed = highlight.trim();
            if (trimmed.isEmpty) {
              continue;
            }

            final rewritten = _professionalizeStatement(trimmed);
            rewrittenBullets.add({
              'experienceId': experience.id,
              'original': trimmed,
              'suggested': _localized(
                language,
                english: '$rewritten, aligned with $role priorities.',
                bangla: '$rewritten, $role প্রায়োরিটির সাথে সামঞ্জস্যপূর্ণ।',
              ),
            });
          }
        }

        final tailoredSummary = _localized(
          language,
          english:
              '${_tonePrefix(tone, language)} $role focused on ${_joinOrFallback(resolvedSkills.take(3).toList(), fallback: 'role-relevant strengths')}. Tailored to reflect the priorities in the target job post while keeping every claim true to the existing CV.',
          bangla:
              '${_tonePrefix(tone, language)} $role, যার ফোকাস ${_joinOrFallback(resolvedSkills.take(3).toList(), fallback: 'রোল-প্রাসঙ্গিক শক্তি')}-এ। টার্গেট জব পোস্টের প্রায়োরিটি অনুযায়ী সাজানো হয়েছে, তবে CV-এর প্রতিটি তথ্য সত্য রাখা হয়েছে।',
        );

        return jsonEncode({
          'tailoredSummary': tailoredSummary,
          'emphasizedSkills': resolvedSkills,
          'rewrittenBullets': rewrittenBullets,
          'language': language.code,
        });
      },
    );
  }

  Future<Result<T>> _runRequest<T>({
    required String prompt,
    required T Function(String rawResponse) parser,
    required String failureMessage,
    required String Function() rawResponseBuilder,
  }) async {
    try {
      if (prompt.trim().isEmpty) {
        throw const AppException(
          'AI prompt could not be prepared.',
          code: 'ai_prompt_error',
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
      final rawResponse = rawResponseBuilder();
      final parsed = parser(rawResponse);
      return Success(parsed);
    } on AppException catch (error) {
      return FailureResult(
        Failure(error.message, code: error.code ?? 'ai_service_error'),
      );
    } catch (_) {
      return FailureResult(Failure(failureMessage, code: 'ai_service_error'));
    }
  }

  Map<String, Object> _buildJobPostAnalysisPayload({
    required String jobPostText,
    required AiOutputLanguage language,
  }) {
    final roleTitle = _detectRoleTitle(jobPostText);
    final companyName = _detectCompanyName(jobPostText);
    final keywords = _extractKeywords(jobPostText, roleHint: roleTitle);
    final requiredSkills = keywords.take(5).toList();
    final preferredSkills = keywords.skip(5).take(3).toList();

    return {
      'roleTitle': roleTitle,
      'companyName': companyName,
      'summary': _localized(
        language,
        english:
            'The job post emphasizes $roleTitle responsibilities with focus on ${_joinOrFallback(requiredSkills.take(3).toList(), fallback: 'role-matching delivery')} and clear professional execution.',
        bangla:
            'জব পোস্টটি $roleTitle দায়িত্বকে গুরুত্ব দিচ্ছে, বিশেষ করে ${_joinOrFallback(requiredSkills.take(3).toList(), fallback: 'রোল-ম্যাচিং কাজ')} এবং পরিষ্কার পেশাদার এক্সিকিউশনকে।',
      ),
      'requiredSkills': requiredSkills,
      'preferredSkills': preferredSkills,
      'keywords': keywords,
    };
  }

  String _resolveRole(CvProfile profile, {String jobTitle = ''}) {
    if (jobTitle.trim().isNotEmpty) {
      return jobTitle.trim();
    }

    if (profile.personalInfo.desiredRole.trim().isNotEmpty) {
      return profile.personalInfo.desiredRole.trim();
    }

    return 'Professional Candidate';
  }

  List<String> _collectProfileSkills(CvProfile profile) {
    final values = <String>[];

    for (final skill in profile.skills) {
      final name = skill.name.trim();
      if (name.isNotEmpty && !values.contains(name)) {
        values.add(name);
      }
    }

    for (final project in profile.projects) {
      for (final tech in project.technologies) {
        final value = tech.trim();
        if (value.isNotEmpty && !values.contains(value)) {
          values.add(value);
        }
      }
    }

    final role = profile.personalInfo.desiredRole.trim();
    if (role.toLowerCase().contains('flutter') && !values.contains('Flutter')) {
      values.add('Flutter');
    }

    return values;
  }

  List<String> _extractKeywords(String input, {String roleHint = ''}) {
    final lowerInput = '$roleHint $input'.toLowerCase();
    const curated = [
      'flutter',
      'dart',
      'firebase',
      'rest api',
      'api integration',
      'riverpod',
      'go_router',
      'git',
      'sql',
      'python',
      'java',
      'javascript',
      'react',
      'node',
      'html',
      'css',
      'figma',
      'ui',
      'ux',
      'testing',
      'problem solving',
      'communication',
      'teamwork',
      'leadership',
      'excel',
      'power bi',
      'data analysis',
      'customer support',
      'sales',
      'digital marketing',
    ];

    final found = <String>[];
    for (final keyword in curated) {
      if (lowerInput.contains(keyword)) {
        found.add(_displayKeyword(keyword));
      }
    }

    if (found.length >= 6) {
      return found;
    }

    final stopWords = {
      'with',
      'and',
      'from',
      'that',
      'this',
      'will',
      'have',
      'your',
      'their',
      'team',
      'role',
      'work',
      'must',
      'good',
      'strong',
      'able',
      'years',
      'year',
      'experience',
      'candidate',
      'looking',
      'required',
      'preferred',
    };

    final extra = lowerInput
        .split(RegExp(r'[^a-z0-9+#]+'))
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .map(_displayKeyword)
        .toSet()
        .toList();

    for (final keyword in extra) {
      if (!found.contains(keyword)) {
        found.add(keyword);
      }
      if (found.length >= 8) {
        break;
      }
    }

    return found.isEmpty
        ? [_displayKeyword(roleHint.ifEmpty('Communication'))]
        : found;
  }

  List<String> _roleBasedSuggestions(String role) {
    final lowerRole = role.toLowerCase();
    if (lowerRole.contains('flutter') || lowerRole.contains('mobile')) {
      return const [
        'REST API Integration',
        'Firebase',
        'State Management',
        'Git',
        'Testing',
      ];
    }

    if (lowerRole.contains('marketing')) {
      return const [
        'Campaign Reporting',
        'Content Writing',
        'Social Media Strategy',
        'Communication',
        'Excel',
      ];
    }

    return const [
      'Communication',
      'Problem Solving',
      'Documentation',
      'Time Management',
      'Teamwork',
    ];
  }

  bool _hasSkill(Set<String> profileSkills, String keyword) {
    final normalizedKeyword = keyword.toLowerCase();
    for (final skill in profileSkills) {
      if (skill.contains(normalizedKeyword) ||
          normalizedKeyword.contains(skill)) {
        return true;
      }
    }

    return false;
  }

  String _detectRoleTitle(String jobPostText) {
    final lowerInput = jobPostText.toLowerCase();
    const knownRoles = [
      'flutter developer',
      'software engineer',
      'mobile app developer',
      'frontend developer',
      'backend developer',
      'ui ux designer',
      'graphic designer',
      'data analyst',
      'marketing executive',
      'sales executive',
      'customer support executive',
    ];

    for (final role in knownRoles) {
      if (lowerInput.contains(role)) {
        return _displayKeyword(role);
      }
    }

    return 'Target Role';
  }

  String _detectCompanyName(String jobPostText) {
    final exactMatch = RegExp(
      r'(?:at|for)\s+([A-Z][A-Za-z0-9&.\- ]{2,})',
    ).firstMatch(jobPostText);
    if (exactMatch != null) {
      return exactMatch.group(1)?.trim() ?? 'Target Company';
    }

    final companyMatch = RegExp(
      r'company\s*[:\-]\s*([A-Za-z0-9&.\- ]+)',
      caseSensitive: false,
    ).firstMatch(jobPostText);
    if (companyMatch != null) {
      return companyMatch.group(1)?.trim() ?? 'Target Company';
    }

    return 'Target Company';
  }

  String _professionalizeStatement(String statement) {
    final cleaned = _normalizeSentence(
      statement,
      fallback: 'completed assigned responsibilities',
    );
    final lower = cleaned.toLowerCase();

    if (lower.startsWith('worked on ')) {
      return 'Contributed to ${cleaned.substring(10)}';
    }
    if (lower.startsWith('made ')) {
      return 'Built ${cleaned.substring(5)}';
    }
    if (lower.startsWith('did ')) {
      return 'Handled ${cleaned.substring(4)}';
    }
    if (lower.startsWith('helped ')) {
      return 'Supported ${cleaned.substring(7)}';
    }
    if (lower.startsWith('created ')) {
      return 'Created ${cleaned.substring(8)}';
    }

    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _normalizeSentence(String input, {required String fallback}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }

    final withoutTrailingPeriod = trimmed.replaceFirst(RegExp(r'[. ]+$'), '');
    if (withoutTrailingPeriod.isEmpty) {
      return fallback;
    }

    return withoutTrailingPeriod[0].toLowerCase() +
        withoutTrailingPeriod.substring(1);
  }

  String _joinOrFallback(List<String> items, {required String fallback}) {
    final cleaned = items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return fallback;
    }

    return cleaned.join(', ');
  }

  String _localized(
    AiOutputLanguage language, {
    required String english,
    required String bangla,
  }) {
    return switch (language) {
      AiOutputLanguage.english => english,
      AiOutputLanguage.bangla => bangla,
    };
  }

  String _tonePrefix(AiTone tone, AiOutputLanguage language) {
    return switch ((tone, language)) {
      (AiTone.simple, AiOutputLanguage.english) => 'Practical',
      (AiTone.confident, AiOutputLanguage.english) => 'Confident',
      (AiTone.formal, AiOutputLanguage.english) => 'Professional',
      (AiTone.professional, AiOutputLanguage.english) => 'Motivated',
      (AiTone.simple, AiOutputLanguage.bangla) => 'ব্যবহারিক',
      (AiTone.confident, AiOutputLanguage.bangla) => 'আত্মবিশ্বাসী',
      (AiTone.formal, AiOutputLanguage.bangla) => 'পেশাদার',
      (AiTone.professional, AiOutputLanguage.bangla) => 'মোটিভেটেড',
    };
  }

  String _toneObjectiveLead(AiTone tone, AiOutputLanguage language) {
    return switch ((tone, language)) {
      (AiTone.simple, AiOutputLanguage.english) => 'To contribute effectively',
      (AiTone.confident, AiOutputLanguage.english) =>
        'To build a high-impact career',
      (AiTone.formal, AiOutputLanguage.english) =>
        'To establish a professional career',
      (AiTone.professional, AiOutputLanguage.english) =>
        'To build a strong early career',
      (AiTone.simple, AiOutputLanguage.bangla) => 'কার্যকরভাবে অবদান রাখতে চাই',
      (AiTone.confident, AiOutputLanguage.bangla) =>
        'উচ্চ-প্রভাবসম্পন্ন ক্যারিয়ার গড়ে তুলতে চাই',
      (AiTone.formal, AiOutputLanguage.bangla) =>
        'একটি পেশাদার ক্যারিয়ার গড়ে তুলতে চাই',
      (AiTone.professional, AiOutputLanguage.bangla) =>
        'একটি শক্তিশালী ক্যারিয়ার শুরু করতে চাই',
    };
  }

  String _toneExecutionSuffix(AiTone tone, AiOutputLanguage language) {
    return switch ((tone, language)) {
      (AiTone.simple, AiOutputLanguage.english) =>
        'with clear ownership and practical follow-through',
      (AiTone.confident, AiOutputLanguage.english) =>
        'with strong ownership, quality focus, and dependable execution',
      (AiTone.formal, AiOutputLanguage.english) =>
        'with emphasis on quality, collaboration, and dependable execution',
      (AiTone.professional, AiOutputLanguage.english) =>
        'with focus on quality, collaboration, and dependable execution',
      (AiTone.simple, AiOutputLanguage.bangla) =>
        'যেখানে পরিষ্কার ownership এবং ব্যবহারিক follow-through ছিল',
      (AiTone.confident, AiOutputLanguage.bangla) =>
        'যেখানে strong ownership, quality focus, এবং dependable execution দেখা যায়',
      (AiTone.formal, AiOutputLanguage.bangla) =>
        'যেখানে quality, collaboration, এবং dependable execution-এ জোর দেওয়া হয়েছে',
      (AiTone.professional, AiOutputLanguage.bangla) =>
        'যেখানে quality, teamwork, এবং dependable execution-এ গুরুত্ব দেওয়া হয়েছে',
    };
  }

  String _toneProjectSuffix(AiTone tone, AiOutputLanguage language) {
    return switch ((tone, language)) {
      (AiTone.simple, AiOutputLanguage.english) =>
        'hands-on implementation and practical user-focused thinking',
      (AiTone.confident, AiOutputLanguage.english) =>
        'strong implementation ability, structured thinking, and user-focused execution',
      (AiTone.formal, AiOutputLanguage.english) =>
        'hands-on implementation, structured thinking, and user-focused execution',
      (AiTone.professional, AiOutputLanguage.english) =>
        'hands-on implementation, structured thinking, and user-focused execution',
      (AiTone.simple, AiOutputLanguage.bangla) =>
        'hands-on implementation এবং practical user-focused thinking',
      (AiTone.confident, AiOutputLanguage.bangla) =>
        'strong implementation ability, structured thinking, এবং user-focused execution',
      (AiTone.formal, AiOutputLanguage.bangla) =>
        'hands-on implementation, structured thinking, এবং user-focused execution',
      (AiTone.professional, AiOutputLanguage.bangla) =>
        'hands-on implementation, structured thinking, এবং user-focused execution',
    };
  }

  String _toneSkillReason(AiTone tone, AiOutputLanguage language) {
    return switch ((tone, language)) {
      (AiTone.simple, AiOutputLanguage.english) => 'practical role alignment',
      (AiTone.confident, AiOutputLanguage.english) => 'strong role alignment',
      (AiTone.formal, AiOutputLanguage.english) =>
        'professional role alignment',
      (AiTone.professional, AiOutputLanguage.english) =>
        'practical alignment with the target role',
      (AiTone.simple, AiOutputLanguage.bangla) => 'ব্যবহারিক role alignment',
      (AiTone.confident, AiOutputLanguage.bangla) => 'strong role alignment',
      (AiTone.formal, AiOutputLanguage.bangla) => 'professional role alignment',
      (AiTone.professional, AiOutputLanguage.bangla) =>
        'ব্যবহারিক role alignment',
    };
  }

  String _documentGreeting({
    required AiOutputLanguage language,
    required String hiringManagerName,
    String fallbackEnglish = 'Dear Hiring Manager,',
    String fallbackBangla = 'মাননীয় নিয়োগকর্তা,',
  }) {
    final name = hiringManagerName.trim();
    if (name.isEmpty) {
      return _localized(
        language,
        english: fallbackEnglish,
        bangla: fallbackBangla,
      );
    }

    return _localized(language, english: 'Dear $name,', bangla: 'প্রিয় $name,');
  }

  String _documentClosing(AiOutputLanguage language) {
    return _localized(language, english: 'Sincerely,', bangla: 'বিনীত,');
  }

  String _documentCandidateSummary({
    required CvProfile profile,
    required String candidateSummary,
    required AiOutputLanguage language,
  }) {
    final manualSummary = candidateSummary.trim();
    if (manualSummary.isNotEmpty) {
      return _normalizeSentence(
        manualSummary,
        fallback: _localized(
          language,
          english: 'a practical candidate profile',
          bangla: 'একটি ব্যবহারিক প্রার্থী প্রোফাইল',
        ),
      );
    }

    final skills = _collectProfileSkills(profile).take(3).toList();
    return _localized(
      language,
      english:
          'My background includes ${_joinOrFallback(skills, fallback: profile.displayRole)}. ',
      bangla:
          '${_joinOrFallback(skills, fallback: profile.displayRole)}-এ আমার ব্যাকগ্রাউন্ড রয়েছে। ',
    );
  }

  String _displayKeyword(String value) {
    return value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          if (lower == 'ui' || lower == 'ux' || lower == 'api') {
            return lower.toUpperCase();
          }
          if (lower == 'go_router') {
            return 'GoRouter';
          }
          if (lower == 'power') {
            return 'Power';
          }
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  String _safeName(CvProfile profile) {
    final name = profile.personalInfo.fullName.trim();
    return name.isEmpty ? 'Applicant' : name;
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

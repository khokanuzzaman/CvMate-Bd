import 'package:careermatebd/shared/models/ai/ai_models.dart';

/// A common interview question with a one-line answering tip.
class InterviewQuickPrompt {
  const InterviewQuickPrompt({required this.question, required this.tip});

  final String question;
  final String tip;
}

/// The built-in practice prompts, in English or Bangla.
List<InterviewQuickPrompt> interviewQuickPrompts(AiOutputLanguage language) {
  if (language == AiOutputLanguage.bangla) {
    return const [
      InterviewQuickPrompt(
        question: 'নিজের সম্পর্কে বলুন।',
        tip: 'বর্তমান ফোকাস, স্কিল, এবং প্রাসঙ্গিক প্রজেক্ট দিয়ে শুরু করুন।',
      ),
      InterviewQuickPrompt(
        question: 'আমরা আপনাকে কেন নিয়োগ দেব?',
        tip: 'একটি নির্দিষ্ট শক্তি এবং role-fit স্পষ্টভাবে বলুন।',
      ),
      InterviewQuickPrompt(
        question: 'আপনার strengths কী?',
        tip: 'একটি strength বেছে নিয়ে উদাহরণ দিন।',
      ),
      InterviewQuickPrompt(
        question: 'আপনার weaknesses কী?',
        tip: 'Honest থাকুন এবং improvement plan বলুন।',
      ),
      InterviewQuickPrompt(
        question: 'আপনি এই চাকরি কেন চান?',
        tip: 'Role, company, এবং শেখার লক্ষ্যকে যুক্ত করুন।',
      ),
      InterviewQuickPrompt(
        question: 'আপনার CV-এর একটি project ব্যাখ্যা করুন।',
        tip: 'Problem, role, tools, result format ব্যবহার করুন।',
      ),
      InterviewQuickPrompt(
        question: 'আপনার expected salary কী?',
        tip: 'Range দিলে context-সহ দিন, rigid না শোনায় এমনভাবে।',
      ),
      InterviewQuickPrompt(
        question: 'আপনার কি আমাদের জন্য কোনো প্রশ্ন আছে?',
        tip: 'Team, role expectations, বা success measure নিয়ে প্রশ্ন করুন।',
      ),
    ];
  }

  return const [
    InterviewQuickPrompt(
      question: 'Tell me about yourself.',
      tip:
          'Start with your current focus, skills, and one relevant project or responsibility.',
    ),
    InterviewQuickPrompt(
      question: 'Why should we hire you?',
      tip: 'Show one clear strength and how it fits the role.',
    ),
    InterviewQuickPrompt(
      question: 'What are your strengths?',
      tip: 'Choose one strength and support it with a practical example.',
    ),
    InterviewQuickPrompt(
      question: 'What are your weaknesses?',
      tip: 'Be honest and explain how you are improving it.',
    ),
    InterviewQuickPrompt(
      question: 'Why do you want this job?',
      tip: 'Connect the role to your skills, learning path, and motivation.',
    ),
    InterviewQuickPrompt(
      question: 'Explain one project from your CV.',
      tip: 'Use a simple problem, role, tools, result structure.',
    ),
    InterviewQuickPrompt(
      question: 'What is your expected salary?',
      tip: 'Give a realistic range if needed and stay flexible.',
    ),
    InterviewQuickPrompt(
      question: 'Do you have any questions for us?',
      tip: 'Ask about team expectations, success metrics, or growth.',
    ),
  ];
}

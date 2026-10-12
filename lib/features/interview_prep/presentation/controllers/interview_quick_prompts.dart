import 'package:careermatebd/shared/models/ai/ai_models.dart';

// Built-in practice content (English and Bangla), not UI chrome: it is shown as
// the user's own practice questions, so it lives here rather than in
// app_strings.dart.

class QuickPracticePrompt {
  const QuickPracticePrompt({required this.question, required this.tip});

  final String question;
  final String tip;
}

List<QuickPracticePrompt> quickPracticePrompts(AiOutputLanguage language) {
  if (language == AiOutputLanguage.bangla) {
    return const [
      QuickPracticePrompt(
        question: 'নিজের সম্পর্কে বলুন।',
        tip: 'বর্তমান ফোকাস, স্কিল, এবং প্রাসঙ্গিক প্রজেক্ট দিয়ে শুরু করুন।',
      ),
      QuickPracticePrompt(
        question: 'আমরা আপনাকে কেন নিয়োগ দেব?',
        tip: 'একটি নির্দিষ্ট শক্তি এবং role-fit স্পষ্টভাবে বলুন।',
      ),
      QuickPracticePrompt(
        question: 'আপনার strengths কী?',
        tip: 'একটি strength বেছে নিয়ে উদাহরণ দিন।',
      ),
      QuickPracticePrompt(
        question: 'আপনার weaknesses কী?',
        tip: 'Honest থাকুন এবং improvement plan বলুন।',
      ),
      QuickPracticePrompt(
        question: 'আপনি এই চাকরি কেন চান?',
        tip: 'Role, company, এবং শেখার লক্ষ্যকে যুক্ত করুন।',
      ),
      QuickPracticePrompt(
        question: 'আপনার CV-এর একটি project ব্যাখ্যা করুন।',
        tip: 'Problem, role, tools, result format ব্যবহার করুন।',
      ),
      QuickPracticePrompt(
        question: 'আপনার expected salary কী?',
        tip: 'Range দিলে context-সহ দিন, rigid না শোনায় এমনভাবে।',
      ),
      QuickPracticePrompt(
        question: 'আপনার কি আমাদের জন্য কোনো প্রশ্ন আছে?',
        tip: 'Team, role expectations, বা success measure নিয়ে প্রশ্ন করুন।',
      ),
    ];
  }

  return const [
    QuickPracticePrompt(
      question: 'Tell me about yourself.',
      tip:
          'Start with your current focus, skills, and one relevant project or responsibility.',
    ),
    QuickPracticePrompt(
      question: 'Why should we hire you?',
      tip: 'Show one clear strength and how it fits the role.',
    ),
    QuickPracticePrompt(
      question: 'What are your strengths?',
      tip: 'Choose one strength and support it with a practical example.',
    ),
    QuickPracticePrompt(
      question: 'What are your weaknesses?',
      tip: 'Be honest and explain how you are improving it.',
    ),
    QuickPracticePrompt(
      question: 'Why do you want this job?',
      tip: 'Connect the role to your skills, learning path, and motivation.',
    ),
    QuickPracticePrompt(
      question: 'Explain one project from your CV.',
      tip: 'Use a simple problem, role, tools, result structure.',
    ),
    QuickPracticePrompt(
      question: 'What is your expected salary?',
      tip: 'Give a realistic range if needed and stay flexible.',
    ),
    QuickPracticePrompt(
      question: 'Do you have any questions for us?',
      tip: 'Ask about team expectations, success metrics, or growth.',
    ),
  ];
}

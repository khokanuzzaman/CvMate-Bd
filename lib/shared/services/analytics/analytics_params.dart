/// Parameter values for analytics events.
///
/// Every value an event can carry is one of these enums (or a small int), so
/// no screen can pass free text such as CV content, names, emails or job
/// posts. The wire value is the snake_case form of the enum name.
library;

/// An enum whose [wire] value is safe to send to analytics.
abstract interface class AnalyticsValue {
  String get wire;
}

String _snake(String name) => name.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match[0]!.toLowerCase()}',
);

/// How the user signed up or logged in.
enum AuthMethod implements AnalyticsValue {
  email;

  @override
  String get wire => _snake(name);
}

/// What the user tapped on the onboarding screen.
enum OnboardingChoice implements AnalyticsValue {
  getStarted,
  skip,
  logIn;

  @override
  String get wire => _snake(name);
}

/// Which part of the ATS checker ran.
enum AtsCheckKind implements AnalyticsValue {
  cv,
  jobMatch;

  @override
  String get wire => _snake(name);
}

/// A 0–100 score, in coarse buckets.
enum ScoreBucket implements AnalyticsValue {
  s0to39,
  s40to59,
  s60to79,
  s80to100;

  static ScoreBucket of(int score) {
    if (score >= 80) {
      return s80to100;
    }
    if (score >= 60) {
      return s60to79;
    }
    return score >= 40 ? s40to59 : s0to39;
  }

  @override
  String get wire => switch (this) {
    s0to39 => '0_39',
    s40to59 => '40_59',
    s60to79 => '60_79',
    s80to100 => '80_100',
  };
}

/// The answer on the AI consent sheet.
enum ConsentResult implements AnalyticsValue {
  allowed,
  notNow;

  @override
  String get wire => _snake(name);
}

/// Every AI feature, one value per AI service method.
enum AiAction implements AnalyticsValue {
  professionalSummary,
  careerObjective,
  experienceBullet,
  projectDescription,
  suggestSkills,
  coverLetter,
  applicationEmail,
  linkedinMessage,
  interviewQuestions,
  atsSuggestions,
  analyzeJobPost,
  cvJobMatch,
  tailorCv;

  @override
  String get wire => _snake(name);
}

/// How an AI request ended.
enum AiResult implements AnalyticsValue {
  ok,
  quota,
  rateLimited,
  unavailable,
  tooLong,
  offline,
  error;

  @override
  String get wire => _snake(name);
}

/// How long something took, in coarse buckets.
enum LatencyBucket implements AnalyticsValue {
  under1s,
  s1to3,
  s3to10,
  s10to30,
  s30to60,
  over60s;

  static LatencyBucket of(Duration elapsed) {
    final ms = elapsed.inMilliseconds;
    if (ms < 1000) {
      return under1s;
    }
    if (ms < 3000) {
      return s1to3;
    }
    if (ms < 10000) {
      return s3to10;
    }
    if (ms < 30000) {
      return s10to30;
    }
    return ms < 60000 ? s30to60 : over60s;
  }

  @override
  String get wire => switch (this) {
    under1s => 'lt_1s',
    s1to3 => '1_3s',
    s3to10 => '3_10s',
    s10to30 => '10_30s',
    s30to60 => '30_60s',
    over60s => 'gt_60s',
  };
}

/// Where the paywall was opened from. Unknown values become [other], so a
/// hand-typed deep link can never put free text into analytics.
enum PaywallSource implements AnalyticsValue {
  cvPreview,
  cvPdfPreview,
  tailoring,
  profile,
  restore,
  aiQuota,
  other;

  static PaywallSource parse(String? raw) {
    for (final value in values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return other;
  }

  @override
  String get wire => _snake(name);
}

/// What the user is buying.
enum PurchasePackage implements AnalyticsValue {
  monthly,
  yearly,
  oneCv;

  @override
  String get wire => _snake(name);
}

/// How a purchase ended.
enum PurchaseResult implements AnalyticsValue {
  success,
  cancelled,
  pending,
  failed;

  @override
  String get wire => _snake(name);
}

/// How "Restore purchases" ended.
enum RestoreResult implements AnalyticsValue {
  restored,
  nothingToRestore,
  cancelled,
  failed;

  @override
  String get wire => _snake(name);
}

/// Where an export started.
enum ExportSource implements AnalyticsValue {
  cvPreview,
  cvPdfPreview,
  tailoring;

  @override
  String get wire => _snake(name);
}

/// How the PDF leaves the app.
enum ExportFormat implements AnalyticsValue {
  share,
  print;

  @override
  String get wire => _snake(name);
}

/// Which rule let the export through.
enum ExportGate implements AnalyticsValue {
  pro,
  unlock,
  free,
  purchased;

  @override
  String get wire => _snake(name);
}

/// How an export ended.
enum ExportResult implements AnalyticsValue {
  ok,
  paywallClosed,
  failed;

  @override
  String get wire => _snake(name);
}

/// The success moment that asked iOS for a rating.
enum ReviewTrigger implements AnalyticsValue {
  export,
  tailoring;

  @override
  String get wire => _snake(name);
}

/// The feedback form's category.
enum FeedbackCategory implements AnalyticsValue {
  bug,
  aiResult,
  payment,
  other;

  @override
  String get wire => _snake(name);
}

/// Whether something was included.
enum YesNo implements AnalyticsValue {
  yes,
  no;

  static YesNo of(bool value) => value ? yes : no;

  @override
  String get wire => name;
}

/// Which kind of account was deleted.
enum AccountKind implements AnalyticsValue {
  guest,
  signedIn;

  @override
  String get wire => _snake(name);
}

/// How account deletion ended.
enum DeleteResult implements AnalyticsValue {
  deleted,
  failed;

  @override
  String get wire => _snake(name);
}

/// The `plan` user property.
enum PlanProperty implements AnalyticsValue {
  free,
  pro;

  @override
  String get wire => name;
}

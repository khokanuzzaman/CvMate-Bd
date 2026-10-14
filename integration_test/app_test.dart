import 'flows/ats_flow.dart';
import 'flows/auth_flow.dart';
import 'flows/cover_letter_flow.dart';
import 'flows/cv_builder_flow.dart';
import 'flows/interview_flow.dart';
import 'flows/market_style_flow.dart';
import 'flows/profile_nav_flow.dart';
import 'flows/sections_flow.dart';
import 'flows/stress_flow.dart';
import 'flows/tailoring_flow.dart';
import 'flows/tracker_flow.dart';
import 'support/qa_harness.dart';

/// Taps through the real app on a simulator against the Firebase Auth
/// emulator. See docs/QA_REPORT.md for how to run it.
void main() => registerQaSuite(() {
  registerAuthFlow();
  registerCvBuilderFlow();
  registerSectionsFlow();
  registerMarketStyleFlow();
  registerTailoringFlow();
  registerCoverLetterFlow();
  registerAtsFlow();
  registerInterviewFlow();
  registerTrackerFlow();
  registerProfileNavFlow();
  registerStressFlow();
});

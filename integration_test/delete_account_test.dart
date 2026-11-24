import 'flows/delete_account_flow.dart';
import 'support/qa_harness.dart';

/// Only the Settings > Delete account cases (docs/TESTFLIGHT_QA.md section 7).
void main() => registerQaSuite(registerDeleteAccountFlow);

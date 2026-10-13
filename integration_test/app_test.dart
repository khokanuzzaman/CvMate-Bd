import 'flows/smoke_flow.dart';
import 'support/qa_harness.dart';

void main() => registerQaSuite(() {
  registerSmokeFlow();
});

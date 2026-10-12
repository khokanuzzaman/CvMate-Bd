import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _printingChannel = MethodChannel('net.nfet.printing');

/// Replaces the `printing` plugin's native side so `Printing.sharePdf` succeeds
/// without a platform. Returns the calls it receives.
List<MethodCall> mockSharePlugin(WidgetTester tester) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _printingChannel,
    (call) async {
      calls.add(call);
      return 1;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _printingChannel,
      null,
    ),
  );
  return calls;
}

/// Lets real async work (PDF generation) finish, then settles the UI.
Future<void> letRealAsyncRun(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 800)),
  );
  await tester.pumpAndSettle();
}

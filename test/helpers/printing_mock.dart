import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _printingChannel = MethodChannel('net.nfet.printing');

/// Replaces the `printing` plugin's native side so `Printing.sharePdf` succeeds
/// without a platform. Returns the calls it receives. `rasterPdf` (the CV
/// preview's pages) still goes to the real plugin, so on a simulator the
/// preview renders as usual.
List<MethodCall> mockSharePlugin(WidgetTester tester) {
  const codec = StandardMethodCodec();
  final messenger = tester.binding.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  messenger.setMockMessageHandler(_printingChannel.name, (message) async {
    final call = codec.decodeMethodCall(message);
    if (call.method == 'rasterPdf') {
      return messenger.delegate.send(_printingChannel.name, message);
    }
    calls.add(call);
    return codec.encodeSuccessEnvelope(1);
  });
  addTearDown(
    () => messenger.setMockMessageHandler(_printingChannel.name, null),
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

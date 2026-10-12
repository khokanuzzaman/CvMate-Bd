import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/theme/cv_mate_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// `assetManifest` is the package's documented @visibleForTesting hook.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;

/// Screenshot size in logical pixels (the design's 390×844 baseline).
const Size screenshotSize = Size(390, 844);

/// Device pixel ratio; 2× gives 780×1688 PNGs, matching the design exports.
const double screenshotScale = 2;

/// Where screenshots are written (inside the gitignored `build/` directory).
const String screenshotDir = 'build/screenshots';

const List<String> _fontFiles = [
  'Sora-SemiBold.ttf',
  'Sora-Bold.ttf',
  'PlusJakartaSans-Regular.ttf',
  'PlusJakartaSans-Medium.ttf',
  'PlusJakartaSans-SemiBold.ttf',
  'PlusJakartaSans-Bold.ttf',
];

const String _fontDir = 'test/fonts';

class _TestFontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [for (final f in _fontFiles) '$_fontDir/$f'];

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

/// Makes `google_fonts` use the fonts in `test/fonts/` and never the network:
/// runtime fetching is turned off, the fonts are served to it as if they were
/// bundled assets, and every text style is warmed up so all weights are
/// registered before the first frame.
///
/// Call once from `setUpAll`.
Future<void> loadTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;
  google_fonts_base.assetManifest = _TestFontManifest();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        if (message == null) {
          return null;
        }
        final key = utf8.decode(
          message.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        final file = File(key);
        if (!key.startsWith('$_fontDir/') || !file.existsSync()) {
          return null;
        }
        return ByteData.sublistView(file.readAsBytesSync());
      });

  // Touch every style the app uses so each weight starts loading.
  <TextStyle>[
    AppTextStyles.display,
    AppTextStyles.h1,
    AppTextStyles.h2,
    AppTextStyles.title,
    AppTextStyles.appBar,
    AppTextStyles.numeric,
    AppTextStyles.body,
    AppTextStyles.bodySm,
    AppTextStyles.caption,
    AppTextStyles.hint,
    AppTextStyles.label,
    AppTextStyles.fieldLabel,
    AppTextStyles.button,
    AppTextStyles.tileLabel,
    AppTextStyles.itemTitle,
  ];
  await GoogleFonts.pendingFonts();
  await _loadMaterialIcons();
  await _loadBengaliFallback();
}

/// Registers the bundled Noto Sans Bengali (`assets/fonts/`) — the fallback the
/// app's text styles name — so ৳ and Bangla text render instead of boxes.
Future<void> _loadBengaliFallback() async {
  final loader = FontLoader(AppTextStyles.bengaliFontFamily);
  for (final name in const ['Regular', 'Bold']) {
    final file = File('assets/fonts/NotoSansBengali-$name.ttf');
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

/// Registers the Material icon font from the Flutter SDK (the test engine
/// otherwise draws icons as empty boxes). Skipped when the SDK copy is not
/// found, which only makes the screenshots less pretty, never fail.
Future<void> _loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    return;
  }
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) {
    return;
  }
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

/// Sizes the test surface to a 390×844 phone at [screenshotScale]×.
void useScreenshotSurface(WidgetTester tester) {
  tester.view.physicalSize = screenshotSize * screenshotScale;
  tester.view.devicePixelRatio = screenshotScale;
  addTearDown(tester.view.reset);
}

/// Pumps [screen] in the real app theme, inside a [RepaintBoundary] keyed by
/// [boundaryKey] so [saveScreenshot] can capture it. Pass either [overrides]
/// or an existing [container].
Future<void> pumpScreenshotScreen(
  WidgetTester tester,
  GlobalKey boundaryKey,
  Widget screen, {
  List<Override> overrides = const [],
  ProviderContainer? container,
}) async {
  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: CvMateTheme.light,
    home: RepaintBoundary(key: boundaryKey, child: screen),
  );

  await tester.pumpWidget(
    container == null
        ? ProviderScope(overrides: overrides, child: app)
        : UncontrolledProviderScope(container: container, child: app),
  );
  await tester.pump();
  await tester.runAsync(GoogleFonts.pendingFonts);
  await tester.pumpAndSettle();
}

/// Renders the boundary to `build/screenshots/<name>.png` and returns the file.
Future<File> saveScreenshot(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  final file = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: screenshotScale);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final out = File('$screenshotDir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
    return out;
  });
  return file!;
}

/// Width and height read from a PNG's IHDR header.
({int width, int height}) pngSize(File file) {
  final bytes = file.readAsBytesSync();
  final header = ByteData.sublistView(bytes, 16, 24);
  return (width: header.getUint32(0), height: header.getUint32(4));
}

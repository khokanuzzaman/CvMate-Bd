import 'dart:io';
import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_preview_pages_provider.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_pdf_pages_view.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_rasterizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'poppler.dart';

/// Rasterizes with poppler's `pdftoppm`, standing in for the platform
/// renderer, which does not exist in widget tests.
class PopplerPdfRasterizer implements CvPdfRasterizer {
  const PopplerPdfRasterizer();

  @override
  Future<List<Uint8List>> rasterize(Uint8List pdf, {required double dpi}) {
    final dir = Directory.systemTemp.createTempSync('cv_preview');
    try {
      final file = File('${dir.path}/cv.pdf')..writeAsBytesSync(pdf);
      return Future.value(Poppler.raster(file, dpi: dpi));
    } finally {
      dir.deleteSync(recursive: true);
    }
  }
}

/// One small white page per PDF, when poppler is not installed.
class BlankPdfRasterizer implements CvPdfRasterizer {
  const BlankPdfRasterizer();

  @override
  Future<List<Uint8List>> rasterize(Uint8List pdf, {required double dpi}) =>
      Future.value([
        img.encodePng(
          img.Image(width: 60, height: 85)..clear(img.ColorRgb8(255, 255, 255)),
        ),
      ]);
}

/// The rasterizer widget tests use for the preview.
CvPdfRasterizer testPdfRasterizer() => Poppler.canRaster
    ? const PopplerPdfRasterizer()
    : const BlankPdfRasterizer();

/// Lets the preview build its PDF and pages (real async work), until the
/// pages for the current draft are on screen.
Future<CvPreviewPages> waitForPreviewPages(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    final state = container.read(cvPreviewPagesProvider);
    if (state.hasValue && !state.isLoading) {
      await tester.pump();
      return state.requireValue;
    }
    if (state.hasError && !state.isLoading) {
      throw StateError('preview failed: ${state.error}');
    }
  }
  throw StateError('preview pages did not arrive');
}

/// The PNG bytes of every page the preview shows, top to bottom.
List<Uint8List> shownPreviewPages(WidgetTester tester) {
  final pages = <Uint8List>[];
  for (var i = 0; ; i++) {
    final page = find.byKey(CvPdfPagesView.pageKey(i));
    if (page.evaluate().isEmpty) {
      return pages;
    }
    final image = tester.widget<Image>(
      find.descendant(of: page, matching: find.byType(Image)),
    );
    pages.add((image.image as MemoryImage).bytes);
  }
}

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Turns a PDF into one PNG per page. The CV preview shows these pages, so
/// what the user sees is the exported PDF itself, not a separate layout.
abstract interface class CvPdfRasterizer {
  Future<List<Uint8List>> rasterize(Uint8List pdf, {required double dpi});
}

/// Uses the platform PDF renderer through the `printing` plugin (PDFKit on
/// iOS, PdfRenderer on Android).
class PrintingPdfRasterizer implements CvPdfRasterizer {
  const PrintingPdfRasterizer();

  @override
  Future<List<Uint8List>> rasterize(
    Uint8List pdf, {
    required double dpi,
  }) async {
    final pages = <Uint8List>[];
    await for (final page in Printing.raster(pdf, dpi: dpi)) {
      pages.add(await page.toPng());
    }
    return pages;
  }
}

final cvPdfRasterizerProvider = Provider<CvPdfRasterizer>(
  (ref) => const PrintingPdfRasterizer(),
);

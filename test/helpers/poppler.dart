import 'dart:io';
import 'dart:typed_data';

/// Thin wrappers over the poppler command-line tools (`pdftotext`, `pdffonts`,
/// `pdfinfo`), so tests read a PDF the way a viewer or an ATS does. Tests that
/// use them skip when poppler is not installed (`brew install poppler`,
/// `apt-get install poppler-utils`).
abstract final class Poppler {
  static final bool available = _has('pdftotext') && _has('pdffonts');

  /// Whether `pdftoppm` (page rasterizing) is installed too.
  static final bool canRaster = available && _has('pdftoppm');

  static bool _has(String tool) {
    try {
      return Process.runSync('which', [tool]).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  static String _run(String tool, List<String> args) {
    final result = Process.runSync(tool, args);
    if (result.exitCode != 0) {
      throw StateError('$tool ${args.join(' ')} failed: ${result.stderr}');
    }
    return result.stdout as String;
  }

  /// The selectable text, with all whitespace (line and page breaks included)
  /// collapsed to single spaces, so a sentence wrapped over two lines or two
  /// pages still matches.
  static String text(File pdf) =>
      collapse(_run('pdftotext', ['-enc', 'UTF-8', pdf.path, '-']));

  /// One row per font: its name and whether it is embedded.
  static List<({String name, bool embedded})> fonts(File pdf) {
    final lines = _run('pdffonts', [pdf.path]).split('\n');
    // Columns: name type encoding emb sub uni object ID — emb is the 5th
    // field from the right of the "yes/no yes/no yes/no N 0" tail.
    return [
      for (final line in lines.skip(2))
        if (line.trim().isNotEmpty)
          () {
            final parts = line.trim().split(RegExp(r'\s+'));
            return (
              name: parts.first,
              embedded: parts[parts.length - 5] == 'yes',
            );
          }(),
    ];
  }

  /// Page count and the first page's size name ("A4", "letter").
  static ({int pages, String size}) info(File pdf) {
    final out = _run('pdfinfo', [pdf.path]);
    return (
      pages: int.parse(RegExp(r'Pages:\s+(\d+)').firstMatch(out)!.group(1)!),
      size: RegExp(r'Page size:.*\((\w+)\)').firstMatch(out)?.group(1) ?? '',
    );
  }

  /// Every page of [pdf] as a PNG at [dpi], in page order.
  static List<Uint8List> raster(File pdf, {required double dpi}) {
    final dir = Directory.systemTemp.createTempSync('cv_raster');
    try {
      _run('pdftoppm', ['-r', '$dpi', '-png', pdf.path, '${dir.path}/p']);
      int page(File f) =>
          int.parse(RegExp(r'-(\d+)\.png$').firstMatch(f.path)!.group(1)!);
      final files = dir.listSync().whereType<File>().toList()
        ..sort((a, b) => page(a).compareTo(page(b)));
      return [for (final f in files) f.readAsBytesSync()];
    } finally {
      dir.deleteSync(recursive: true);
    }
  }

  /// The text of one page (1-based), whitespace collapsed.
  static String pageText(File pdf, int page) => collapse(
    _run('pdftotext', [
      '-enc',
      'UTF-8',
      '-f',
      '$page',
      '-l',
      '$page',
      pdf.path,
      '-',
    ]),
  );

  /// Width of page 1 in points.
  static double pageWidth(File pdf) => double.parse(
    RegExp(
      r'Page size:\s+([\d.]+)',
    ).firstMatch(_run('pdfinfo', [pdf.path]))!.group(1)!,
  );

  static String collapse(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

import 'dart:typed_data';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:image/image.dart' as img;

/// What makes each template look like itself, read from the pixels of a
/// rendered page 1 (the preview image or a rasterized PDF page). All five are
/// single column, Helvetica (Noto Sans Bengali for Bangla), greyscale, with
/// the photo top right when there is one. See docs/qa/templates/IDENTITY.md.
///
/// | template     | header                         | section titles            |
/// |--------------|--------------------------------|---------------------------|
/// | classic      | name left, black 1.1pt rule    | UPPERCASE, grey700 rule   |
/// | modern       | dark band, white name, box     | dark bar, white text      |
/// | minimal      | name centred, grey700 0.9 rule | UPPERCASE, no rule        |
/// | professional | name left, grey900 1.6pt rule  | UPPERCASE, grey900 1pt    |
/// | fresher      | name left, grey600 0.9 rule    | UPPERCASE, grey500 rule   |
///
/// Fresher also puts Education and Projects before Experience; that order is
/// checked on the PDF text, not here.
class TemplateLook {
  const TemplateLook({
    required this.bars,
    required this.rules,
    required this.nameLeft,
    required this.hasPhoto,
  });

  /// Solid dark bars at least 8pt tall and 40pt wide (Modern's header band
  /// and section-title bars), top to bottom.
  final List<Band> bars;

  /// Thin lines (at most 3pt) across most of the column, top to bottom.
  final List<Band> rules;

  /// Where the first line of ink starts, in pt from the left margin.
  final double nameLeft;

  /// A photo-coloured block in the top-right corner.
  final bool hasPhoto;

  /// The template these features match, or null when they match none.
  CvTemplate? get template {
    if (bars.isNotEmpty) {
      return CvTemplate.modern;
    }
    if (rules.isEmpty) {
      return null;
    }
    final header = rules.first.darkest;
    final section = rules.length > 1 ? rules[1].darkest : null;
    bool within(int? value, int low, int high) =>
        value != null && value >= low && value <= high;

    if (nameLeft > 40) {
      // Centred name: only Minimal, whose titles have no rule.
      return section == null && within(header, 70, 125)
          ? CvTemplate.minimal
          : null;
    }
    if (within(header, 0, 15) && within(section, 70, 125)) {
      return CvTemplate.classic;
    }
    if (within(header, 20, 60) && within(section, 20, 60)) {
      return CvTemplate.professional;
    }
    if (within(header, 100, 135) && within(section, 140, 175)) {
      return CvTemplate.fresher;
    }
    return null;
  }

  @override
  String toString() =>
      'TemplateLook(bars: $bars, rules: $rules, nameLeft: '
      '${nameLeft.toStringAsFixed(1)}, photo: $hasPhoto)';
}

/// A horizontal band of rows: where it starts, how thick, how dark (0 =
/// black, 255 = white). Units are pt.
class Band {
  const Band(this.top, this.thickness, this.darkest);

  final double top;
  final double thickness;
  final int darkest;

  @override
  String toString() =>
      '${top.toStringAsFixed(1)}+${thickness.toStringAsFixed(1)}@$darkest';
}

/// Page margins of every template (CvPdfTemplateBuilders: 30 left/right,
/// 28 top/bottom) and the photo box (CvPdfMarketBlocks: 64 x 82).
const double _marginX = 30;
const double _marginTop = 28;
const double _photoWidth = 64;
const double _photoHeight = 82;

/// Reads [png] (a whole page whose width is [pageWidthPt] points).
TemplateLook lookOf(Uint8List png, {required double pageWidthPt}) {
  final page = decodePage(png);
  final scale = page.width / pageWidthPt;
  final x0 = (_marginX * scale).round();
  final x1 = page.width - x0;
  final minRun = ((x1 - x0) * 0.6).round();

  int lum(int x, int y) => page.getPixel(x, y).luminance.toInt();

  // Longest run of pixels darker than [limit] in row y, and its darkest pixel.
  (int, int) run(int y, int limit) {
    var best = 0;
    var current = 0;
    var darkest = 255;
    for (var x = x0; x < x1; x++) {
      final l = lum(x, y);
      if (l < limit) {
        current++;
        if (current > best) {
          best = current;
        }
        if (l < darkest) {
          darkest = l;
        }
      } else {
        current = 0;
      }
    }
    return (best, darkest);
  }

  // Thin lines across most of the column.
  final rules = <Band>[];
  int? start;
  var darkest = 255;
  for (var y = 0; y <= page.height; y++) {
    final (length, rowDarkest) = y < page.height ? run(y, 215) : (0, 255);
    if (length >= minRun) {
      start ??= y;
      darkest = rowDarkest < darkest ? rowDarkest : darkest;
      continue;
    }
    if (start != null && (y - start) / scale <= 3) {
      rules.add(Band(start / scale, (y - start) / scale, darkest));
    }
    start = null;
    darkest = 255;
  }

  // Solid dark bars: rows with a 40pt run of near-black, at least 8pt tall.
  final bars = <Band>[];
  final minBar = (40 * scale).round();
  start = null;
  for (var y = 0; y <= page.height; y++) {
    final (length, _) = y < page.height ? run(y, 80) : (0, 255);
    if (length >= minBar) {
      start ??= y;
      continue;
    }
    if (start != null && (y - start) / scale >= 8) {
      bars.add(Band(start / scale, (y - start) / scale, 0));
    }
    start = null;
  }

  // Left edge of the first line of ink below the top margin (the name), over
  // the whole line: its first row may be only an ascender or an apex.
  // Stop short of the photo and its border (14pt gap, 0.6pt border).
  final textRight = x1 - ((_photoWidth + 7) * scale).round();
  int? inkLeft(int y) {
    for (var x = x0; x < textRight; x++) {
      if (lum(x, y) < 128) {
        return x;
      }
    }
    return null;
  }

  var nameLeft = 0.0;
  var y = (_marginTop * scale).round();
  while (y < page.height && inkLeft(y) == null) {
    y++;
  }
  int? left;
  for (; y < page.height; y++) {
    final x = inkLeft(y);
    if (x == null) {
      break;
    }
    left = left == null || x < left ? x : left;
  }
  if (left != null) {
    nameLeft = (left - x0) / scale;
  }

  // Middle of the photo box: the fixture photo is solid grey 120.
  final px0 = x1 - ((_photoWidth - 16) * scale).round();
  final px1 = x1 - (16 * scale).round();
  final py0 = ((_marginTop + 20) * scale).round();
  final py1 = ((_marginTop + _photoHeight - 20) * scale).round();
  var sum = 0;
  var count = 0;
  for (var y = py0; y < py1; y++) {
    for (var x = px0; x < px1; x++) {
      sum += lum(x, y);
      count++;
    }
  }
  final mean = sum / count;

  return TemplateLook(
    bars: bars,
    rules: rules,
    nameLeft: nameLeft,
    hasPhoto: mean > 90 && mean < 150,
  );
}

/// Decodes a page PNG with any transparency drawn over white, the way the
/// preview shows it on its white sheet. (The iOS renderer leaves the paper
/// transparent; poppler and Quick Look paint it white.)
img.Image decodePage(Uint8List png) {
  final page = img.decodePng(png)!;
  if (!page.hasAlpha) {
    return page;
  }
  final white = img.Image(width: page.width, height: page.height)
    ..clear(img.ColorRgb8(255, 255, 255));
  return img.compositeImage(white, page);
}

/// Share of pixels whose colour differs by more than a little, over the area
/// both pages cover. Anti-aliasing and sub-pixel placement are allowed: a
/// pixel matches when one within 1 px of it in the other page has about the
/// same colour. Renderers may round the page height differently by a pixel or
/// two; anything more counts as a different page size, and the pages differ
/// completely.
double differingPixels(Uint8List pngA, Uint8List pngB) {
  final a = decodePage(pngA);
  final b = decodePage(pngB);
  if ((a.width - b.width).abs() > 2 || (a.height - b.height).abs() > 2) {
    return 1;
  }
  final width = a.width < b.width ? a.width : b.width;
  final height = a.height < b.height ? a.height : b.height;
  bool close(img.Pixel p, img.Pixel q) =>
      (p.r - q.r).abs() <= 32 &&
      (p.g - q.g).abs() <= 32 &&
      (p.b - q.b).abs() <= 32;
  bool matches(img.Image from, img.Image to, int x, int y) {
    final p = from.getPixel(x, y);
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 &&
            ny >= 0 &&
            nx < width &&
            ny < height &&
            close(p, to.getPixel(nx, ny))) {
          return true;
        }
      }
    }
    return false;
  }

  var differing = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (!matches(a, b, x, y) || !matches(b, a, x, y)) {
        differing++;
      }
    }
  }
  return differing / (width * height);
}

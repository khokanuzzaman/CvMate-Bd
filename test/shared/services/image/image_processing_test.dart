import 'package:careermatebd/shared/services/image/image_processing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('the photo is cropped to the frame and stored at 350x450', () {
    // A 400x300 photo shown to just cover a 70x90 frame (fit = 0.3), centred.
    const frame = Size(70, 90);
    const fit = 0.3;
    final centred = Matrix4.identity()
      ..setTranslationRaw(-(400 * fit - 70) / 2, -(300 * fit - 90) / 2, 0);
    final crop = CropFraction.fromViewport(
      matrix: centred,
      frame: frame,
      imageWidth: 400,
      imageHeight: 300,
      fit: fit,
    );
    // The frame covers the whole height and 70 of the 120 shown pixels across.
    expect(crop.height, closeTo(1.0, 1e-9));
    expect(crop.width, closeTo(70 / (400 * fit), 1e-9));
    expect(crop.left, closeTo((1 - crop.width) / 2, 1e-9));

    // Zoomed 2x, the frame shows half as much.
    final zoomed = Matrix4.identity()..scaleByDouble(2, 2, 1, 1);
    final half = CropFraction.fromViewport(
      matrix: zoomed,
      frame: frame,
      imageWidth: 400,
      imageHeight: 300,
      fit: fit,
    );
    expect(half.width, closeTo(crop.width / 2, 1e-9));

    final source = img.encodeJpg(img.Image(width: 400, height: 300));
    final out = img.decodeJpg(ImageProcessing.cropPhoto(source, crop))!;
    expect((out.width, out.height), (350, 450));
  });
}

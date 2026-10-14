import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Matrix4, Size;
import 'package:image/image.dart' as img;

/// A picked photo made ready for cropping: upright (EXIF applied), at most
/// [ImageProcessing.workingSide] px on the long side, with its size.
class PreparedImage {
  const PreparedImage(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

/// A crop as fractions of the image (0-1), so it does not depend on the size
/// the image was shown at.
class CropFraction {
  const CropFraction({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// The part of an image that shows through a frame. The image is laid out at
  /// [fit] screen pixels per image pixel, then moved and zoomed by [matrix]
  /// (translation and uniform scale, as an `InteractiveViewer` keeps it).
  factory CropFraction.fromViewport({
    required Matrix4 matrix,
    required Size frame,
    required int imageWidth,
    required int imageHeight,
    required double fit,
  }) {
    final scale = matrix.getMaxScaleOnAxis();
    final childWidth = imageWidth * fit;
    final childHeight = imageHeight * fit;
    return CropFraction(
      left: ((-matrix.storage[12] / scale) / childWidth).clamp(0.0, 1.0),
      top: ((-matrix.storage[13] / scale) / childHeight).clamp(0.0, 1.0),
      width: ((frame.width / scale) / childWidth).clamp(0.0, 1.0),
      height: ((frame.height / scale) / childHeight).clamp(0.0, 1.0),
    );
  }
}

Uint8List _cropEntry((Uint8List, CropFraction) args) =>
    ImageProcessing.cropPhoto(args.$1, args.$2);

/// Pure-Dart image work for the CV photo and signature. Heavy, so call the
/// `*Async` variants (they run in an isolate).
abstract final class ImageProcessing {
  /// Passport ratio 35x45, stored at 350x450 (about 40 KB as JPEG).
  static const int photoWidth = 350;
  static const int photoHeight = 450;
  static const int workingSide = 1600;
  static const int signatureMaxWidth = 600;

  static Future<PreparedImage> prepareForCropAsync(Uint8List source) =>
      compute(prepareForCrop, source);

  static Future<Uint8List> cropPhotoAsync(
    Uint8List source,
    CropFraction crop,
  ) => compute(_cropEntry, (source, crop));

  static Future<Uint8List> prepareSignatureAsync(Uint8List source) =>
      compute(prepareSignature, source);

  /// Throws [FormatException] for something that is not an image.
  static PreparedImage prepareForCrop(Uint8List source) {
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      throw const FormatException('Not an image');
    }
    var image = img.bakeOrientation(decoded);
    final longSide = image.width > image.height ? image.width : image.height;
    if (longSide > workingSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: workingSide)
          : img.copyResize(image, height: workingSide);
    }
    return PreparedImage(
      Uint8List.fromList(img.encodeJpg(image, quality: 92)),
      image.width,
      image.height,
    );
  }

  static Uint8List cropPhoto(Uint8List source, CropFraction crop) {
    final image = img.decodeImage(source);
    if (image == null) {
      throw const FormatException('Not an image');
    }
    final x = (crop.left * image.width).round().clamp(0, image.width - 1);
    final y = (crop.top * image.height).round().clamp(0, image.height - 1);
    final w = (crop.width * image.width).round().clamp(1, image.width - x);
    final h = (crop.height * image.height).round().clamp(1, image.height - y);
    final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
    final sized = img.copyResize(
      cropped,
      width: photoWidth,
      height: photoHeight,
      interpolation: img.Interpolation.average,
    );
    return Uint8List.fromList(img.encodeJpg(sized, quality: 85));
  }

  /// An uploaded signature scaled down to a sensible size, as PNG (keeps
  /// transparency).
  static Uint8List prepareSignature(Uint8List source) {
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      throw const FormatException('Not an image');
    }
    var image = img.bakeOrientation(decoded);
    if (image.width > signatureMaxWidth) {
      image = img.copyResize(image, width: signatureMaxWidth);
    }
    return Uint8List.fromList(img.encodePng(image));
  }
}

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Takes or picks an image and returns its bytes (null when cancelled). Behind
/// an interface so tests can supply an image without a camera or gallery.
abstract interface class PhotoPicker {
  Future<Uint8List?> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  const ImagePickerPhotoPicker();

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
    return file?.readAsBytes();
  }
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => const ImagePickerPhotoPicker(),
);

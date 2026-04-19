import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageProcessingController extends ChangeNotifier {
  String? currentImagePath;
  bool isProcessing = false;

  /// Load the initial image path
  void setImage(String path) {
    currentImagePath = path;
    notifyListeners();
  }

  /// 1. GRAYSCALE (Luminance Conversion)
  Future<void> applyGrayscale() async {
    await _processImage((image) => img.grayscale(image));
  }

  /// 2. GAUSSIAN BLUR (Smoothening)
  Future<void> applyGaussianBlur() async {
    await _processImage((image) => img.gaussianBlur(image, radius: 5));
  }

  /// 3. MEDIAN FILTER (Noise Reduction)
  /// Real median filter: replaces each pixel with the median of its 3x3 neighbourhood
  Future<void> applyMedianFilter() async {
    await _processImage((image) {
      // 1. Create a deep clone to read from
      final src = image.clone();
      final width = image.width;
      final height = image.height;

      // 2. Reuse buffers instead of recreating them inside loops
      final List<int> r = List.filled(9, 0);
      final List<int> g = List.filled(9, 0);
      final List<int> b = List.filled(9, 0);

      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          int count = 0;

          // Collect 3x3 neighborhood
          for (int ky = -1; ky <= 1; ky++) {
            for (int kx = -1; kx <= 1; kx++) {
              final pixel = src.getPixel(x + kx, y + ky);
              r[count] = pixel.r
                  .toInt(); // Use .r, .g, .b for newer package versions
              g[count] = pixel.g.toInt();
              b[count] = pixel.b.toInt();
              count++;
            }
          }

          // 3. Sort the fixed-size buffers
          r.sort();
          g.sort();
          b.sort();

          // 4. Update the output image (the median is index 4)
          image.setPixelRgb(x, y, r[4], g[4], b[4]);
        }
      }
      return image;
    });
  }

  /// 4. BRIGHTNESS ADJUSTMENT (Arithmetic operation)
  Future<void> applyBrightness(num amount) async {
    await _processImage((image) => img.adjustColor(image, brightness: amount));
  }

  /// 5. INVERSE / NOT (Boolean logic)
  Future<void> applyInverse() async {
    await _processImage((image) => img.invert(image));
  }

  /// 6. SHARPEN (Convolution with high-pass kernel)
  Future<void> applySharpen() async {
    await _processImage(
      (image) => img.convolution(
        image,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
        offset: 0,
      ),
    );
  }

  /// 7. CONTRAST ADJUSTMENT
  Future<void> applyContrast() async {
    await _processImage((image) => img.adjustColor(image, contrast: 1.5));
  }

  /// Core Engine: Decodes, applies function, saves new file
  Future<void> _processImage(img.Image Function(img.Image) operation) async {
    if (currentImagePath == null) return;

    isProcessing = true;
    notifyListeners();

    try {
      final bytes = await File(currentImagePath!).readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception("Gagal membaca gambar");

      final processed = operation(decoded);

      final newPath = currentImagePath!.replaceFirst(
        RegExp(r'\.jpg$'),
        '_mod_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(newPath).writeAsBytes(img.encodeJpg(processed, quality: 90));

      currentImagePath = newPath;
    } catch (e) {
      debugPrint("PCD Processing Error: $e");
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}

import 'dart:io';
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
    await _processImage((originalImage) {
      return img.grayscale(originalImage);
    });
  }

  /// 2. ARITMATIKA (Brightness Adjustment)
  Future<void> applyBrightness(num amount) async {
    await _processImage((originalImage) {
      // Menambahkan nilai pada piksel untuk meningkatkan brightness
      return img.adjustColor(originalImage, brightness: amount);
    });
  }

  /// 3. BOOLEAN LOGIC (Inverse / NOT)
  Future<void> applyInverse() async {
    await _processImage((originalImage) {
      return img.invert(originalImage);
    });
  }

  /// 4. CONVOLUTION (Sharpening / High-Pass Filter)
  Future<void> applySharpen() async {
    await _processImage((originalImage) {
      // Applying a 3x3 kernel matrix to sharpen the edges of road damage
      return img.convolution(
        originalImage,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
        offset: 0,
      );
    });
  }

  /// 5. CONTRAST ADJUSTMENT
  Future<void> applyContrast() async {
    await _processImage((originalImage) {
      // Enhancing contrast to simulate basic histogram stretching
      return img.adjustColor(originalImage, contrast: 1.5);
    });
  }

  /// Core Engine: Decodes, applies function, and saves a new file
  Future<void> _processImage(img.Image Function(img.Image) operation) async {
    if (currentImagePath == null) return;

    isProcessing = true;
    notifyListeners();

    try {
      // 1. Read file bytes
      final bytes = await File(currentImagePath!).readAsBytes();

      // 2. Decode to Image object
      img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) throw Exception("Gagal membaca gambar");

      // 3. Apply PCD Operation
      img.Image processedImage = operation(decodedImage);

      // 4. Save to a new temporary file
      final newPath = currentImagePath!.replaceFirst(
        '.jpg',
        '_mod_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final modifiedFile = File(newPath);
      await modifiedFile.writeAsBytes(
        img.encodeJpg(processedImage, quality: 85),
      );

      // 5. Update State
      currentImagePath = newPath;
    } catch (e) {
      debugPrint("PCD Processing Error: $e");
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}

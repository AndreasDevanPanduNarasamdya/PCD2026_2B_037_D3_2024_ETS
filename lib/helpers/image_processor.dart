import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessor {
  // 1. Salt and Pepper Noise
  static Uint8List addSaltAndPepper(Uint8List imageBytes, double noiseLevel) {
    img.Image? decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) return imageBytes;

    var rand = Random();
    for (var p in decodedImage) {
      if (rand.nextDouble() < noiseLevel) {
        // Randomly set pixel to black (0) or white (255)
        num val = rand.nextBool() ? 255 : 0;
        p.r = val;
        p.g = val;
        p.b = val;
      }
    }
    return img.encodeJpg(decodedImage);
  }

  // 2. Image Sharpening (Convolution Matrix)
  static Uint8List sharpenImage(Uint8List imageBytes) {
    img.Image? decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) return imageBytes;

    // Standard sharpen kernel equivalent to the Python: [[0,-1,0], [-1,5,-1], [0,-1,0]]
    const filter = [0, -1, 0, -1, 5, -1, 0, -1, 0];

    img.Image sharpened = img.convolution(
      decodedImage,
      filter: filter,
      div: 1,
      offset: 0,
    );
    return img.encodeJpg(sharpened);
  }

  // 3. Denoising (Gaussian Blur approximation for Median)
  static Uint8List denoiseImage(Uint8List imageBytes) {
    img.Image? decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) return imageBytes;

    // Applies a smoothing filter to reduce salt and pepper noise
    img.Image smoothed = img.gaussianBlur(decodedImage, radius: 2);
    return img.encodeJpg(smoothed);
  }
}

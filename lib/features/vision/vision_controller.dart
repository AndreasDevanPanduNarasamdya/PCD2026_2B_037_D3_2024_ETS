import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';

/// VisionController manages the camera lifecycle and REAL face detection logic.
class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  // Camera controller instance
  CameraController? controller;

  // State tracking
  bool isInitialized = false;
  String? errorMessage;

  // Real face detection
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableClassification: false,
    ),
  );
  bool _isDetecting = false;
  List<DetectionResult> currentDetections = [];
  Size? imageSize;

  // UX toggles
  bool isFlashlightOn = false;
  bool isOverlayVisible = true;
  bool isFaceDetectionEnabled = true;

  // Active image filter
  ActiveFilter currentFilter = ActiveFilter.none;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  CameraLensDirection currentLensDirection = CameraLensDirection.back;

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      imageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Determine rotation based on lens direction
      final rotation = currentLensDirection == CameraLensDirection.front
          ? InputImageRotation.rotation270deg
          : InputImageRotation.rotation90deg;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize!,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Initialize camera and start image stream for face detection
  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device.";
        notifyListeners();
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == currentLensDirection,
        orElse: () => cameras[0],
      );

      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
      notifyListeners();

      // Start real-time face detection stream
      if (isFaceDetectionEnabled) {
        _startImageStream();
      }
    } catch (e) {
      errorMessage = "Failed to initialize camera: $e";
      notifyListeners();
    }
  }

  /// Start image stream and run face detection on each frame
  void _startImageStream() {
    if (controller == null || !controller!.value.isInitialized) return;

    controller!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) {
          _isDetecting = false;
          return;
        }

        final faces = await _faceDetector.processImage(inputImage);

        currentDetections = faces.map((face) {
          // Normalize bounding box to 0.0-1.0 range
          final iw = imageSize!.width;
          final ih = imageSize!.height;
          return DetectionResult(
            box: Rect.fromLTRB(
              face.boundingBox.left / iw,
              face.boundingBox.top / ih,
              face.boundingBox.right / iw,
              face.boundingBox.bottom / ih,
            ),
            label: 'Face',
            score: face.headEulerAngleY != null ? 0.99 : 0.90,
          );
        }).toList();

        notifyListeners();
      } catch (e) {
        debugPrint('Face detection error: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Stop image stream
  void _stopImageStream() {
    if (controller != null && controller!.value.isStreamingImages) {
      controller!.stopImageStream();
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    _stopImageStream();
    await controller?.dispose();
    isInitialized = false;
    currentDetections = [];
    notifyListeners();

    currentLensDirection = (currentLensDirection == CameraLensDirection.back)
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await initCamera();
  }

  /// Toggle face detection on/off
  void toggleFaceDetection() {
    isFaceDetectionEnabled = !isFaceDetectionEnabled;

    if (isFaceDetectionEnabled) {
      _startImageStream();
    } else {
      _stopImageStream();
      currentDetections = [];
    }
    notifyListeners();
  }

  /// Set active filter for camera preview
  void setFilter(ActiveFilter filter) {
    // If same filter tapped again, turn it off
    currentFilter = (currentFilter == filter) ? ActiveFilter.none : filter;
    notifyListeners();
  }

  /// Capture photo from camera
  Future<XFile?> takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return null;

    try {
      _stopImageStream();
      await Future.delayed(const Duration(milliseconds: 100));
      final image = await controller!.takePicture();

      // Restart stream after capture
      if (isFaceDetectionEnabled) {
        _startImageStream();
      }

      return image;
    } catch (e) {
      errorMessage = "Failed to capture photo: $e";
      notifyListeners();
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopImageStream();
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  /// Toggle flashlight
  Future<void> toggleFlashlight() async {
    if (controller == null || !controller!.value.isInitialized) return;

    isFlashlightOn = !isFlashlightOn;
    try {
      await controller!.setFlashMode(
        isFlashlightOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      errorMessage = "Failed to toggle flashlight: $e";
    }
    notifyListeners();
  }

  /// Toggle overlay visibility
  void toggleOverlay() {
    isOverlayVisible = !isOverlayVisible;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopImageStream();
    _faceDetector.close();
    controller?.dispose();
    super.dispose();
  }
}

/// Active filter enum
enum ActiveFilter { none, grayscale, blur, sharpen, contrast, inverse }

/// DTO for detection results
class DetectionResult {
  final Rect box;
  final String label;
  final double score;

  DetectionResult({
    required this.box,
    required this.label,
    required this.score,
  });
}

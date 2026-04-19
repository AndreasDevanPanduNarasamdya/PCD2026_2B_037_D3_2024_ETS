import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';

class VisionView extends StatefulWidget {
  final bool returnImagePath;

  const VisionView({super.key, this.returnImagePath = false});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;
  String? _lastCapturedPath;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    final image = await _visionController.takePhoto();
    if (image == null) return;

    // Apply active filter to the saved file
    final savedPath = await _applyFilterToFile(
      image.path,
      _visionController.currentFilter,
    );

    if (widget.returnImagePath) {
      if (context.mounted) Navigator.pop(context, savedPath);
    } else {
      setState(() => _lastCapturedPath = savedPath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto tersimpan: $savedPath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Bake the active filter into the captured image file
  Future<String> _applyFilterToFile(String path, ActiveFilter filter) async {
    if (filter == ActiveFilter.none) return path;
    try {
      final bytes = await File(path).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return path;

      img.Image processed;
      switch (filter) {
        case ActiveFilter.grayscale:
          processed = img.grayscale(image);
          break;
        case ActiveFilter.blur:
          processed = img.gaussianBlur(image, radius: 5);
          break;
        case ActiveFilter.sharpen:
          processed = img.convolution(
            image,
            filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
            div: 1,
            offset: 0,
          );
          break;
        case ActiveFilter.contrast:
          processed = img.adjustColor(image, contrast: 1.5);
          break;
        case ActiveFilter.inverse:
          processed = img.invert(image);
          break;
        default:
          return path;
      }

      final newPath = path.replaceFirst('.jpg', '_filtered.jpg');
      await File(newPath).writeAsBytes(img.encodeJpg(processed, quality: 90));
      return newPath;
    } catch (e) {
      debugPrint('Filter apply error: $e');
      return path;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.returnImagePath
              ? "Ambil Foto untuk Catatan"
              : "Smart-Patrol Vision",
        ),
        actions: [
          // Switch camera
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) => IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: _visionController.switchCamera,
              tooltip: 'Ganti Kamera',
            ),
          ),
          // Flashlight
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) => IconButton(
              icon: Icon(
                _visionController.isFlashlightOn
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
              onPressed: _visionController.toggleFlashlight,
              tooltip: 'Toggle Flash',
            ),
          ),
          // Overlay
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) => IconButton(
              icon: Icon(
                _visionController.isOverlayVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: _visionController.toggleOverlay,
              tooltip: 'Toggle Overlay',
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.isInitialized) {
            return _buildLoadingState();
          }
          return Column(
            children: [
              Expanded(child: _buildCameraPreview()),
              _buildFilterBar(),
              _buildBottomControls(),
            ],
          );
        },
      ),
    );
  }

  /// Camera preview that fills width without squashing aspect ratio
  Widget _buildCameraPreview() {
    final cam = _visionController.controller!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Camera — correct aspect ratio, fills width
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: SizedBox(
                width: screenWidth,
                height: screenWidth / cam.value.aspectRatio,
                child: CameraPreview(cam),
              ),
            ),
          ),
        ),

        // Layer 2: Detection overlay boxes
        if (_visionController.isOverlayVisible &&
            _visionController.currentDetections.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(_visionController.currentDetections),
            ),
          ),

        // Layer 3: Active filter label
        if (_visionController.currentFilter != ActiveFilter.none)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Filter: ${_filterLabel(_visionController.currentFilter)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

        // Layer 4: Picker hint banner
        if (widget.returnImagePath)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Tekan ✓ untuk menggunakan foto ini",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),

        // Layer 5: Last captured thumbnail (standalone mode)
        if (!widget.returnImagePath && _lastCapturedPath != null)
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _showImagePreview(_lastCapturedPath!),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(_lastCapturedPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Scrollable filter chip bar
  Widget _buildFilterBar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListenableBuilder(
        listenable: _visionController,
        builder: (context, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(ActiveFilter.none, 'Original', Icons.image),
              _filterChip(
                ActiveFilter.grayscale,
                'Grayscale',
                Icons.filter_b_and_w,
              ),
              _filterChip(ActiveFilter.blur, 'Blur', Icons.blur_on),
              _filterChip(ActiveFilter.sharpen, 'Sharpen', Icons.auto_fix_high),
              _filterChip(ActiveFilter.contrast, 'Contrast', Icons.contrast),
              _filterChip(ActiveFilter.inverse, 'Inverse', Icons.invert_colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(ActiveFilter filter, String label, IconData icon) {
    final isActive = _visionController.currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _visionController.setFilter(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.blue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom bar: face detection toggle | capture button | detection count
  Widget _buildBottomControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: ListenableBuilder(
        listenable: _visionController,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Face detection toggle
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _visionController.toggleFaceDetection,
                  icon: Icon(
                    Icons.face,
                    color: _visionController.isFaceDetectionEnabled
                        ? Colors.greenAccent
                        : Colors.grey,
                    size: 28,
                  ),
                  tooltip: 'Toggle Face Detection',
                ),
                Text(
                  _visionController.isFaceDetectionEnabled
                      ? 'Detection ON'
                      : 'Detection OFF',
                  style: TextStyle(
                    color: _visionController.isFaceDetectionEnabled
                        ? Colors.greenAccent
                        : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            // Capture button
            GestureDetector(
              onTap: _handleCapture,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: widget.returnImagePath
                      ? Colors.greenAccent
                      : Colors.white,
                ),
                child: Icon(
                  widget.returnImagePath ? Icons.check : Icons.camera_alt,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),

            // Detection count
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.track_changes,
                  color: _visionController.currentDetections.isNotEmpty
                      ? Colors.orangeAccent
                      : Colors.grey,
                  size: 28,
                ),
                Text(
                  '${_visionController.currentDetections.length} detected',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(ActiveFilter filter) {
    switch (filter) {
      case ActiveFilter.grayscale:
        return 'Grayscale';
      case ActiveFilter.blur:
        return 'Gaussian Blur';
      case ActiveFilter.sharpen:
        return 'Sharpen';
      case ActiveFilter.contrast:
        return 'Contrast';
      case ActiveFilter.inverse:
        return 'Inverse';
      default:
        return 'None';
    }
  }

  void _showImagePreview(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "Preview Foto",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(child: Image.file(File(path))),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            "Menghubungkan ke Kamera...",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          if (_visionController.errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _visionController.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text("Buka Pengaturan"),
            ),
          ],
        ],
      ),
    );
  }
}

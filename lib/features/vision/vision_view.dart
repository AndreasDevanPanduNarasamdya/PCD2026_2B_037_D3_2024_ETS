import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';

/// VisionView dapat digunakan dalam dua mode:
/// 1. Mode standalone (dari LogView FAB) - hanya buka kamera biasa
/// 2. Mode picker (dari LogEditorView) - setelah capture, kembali dengan path foto
///
/// Mode ditentukan oleh [returnImagePath]:
/// - false (default): mode standalone
/// - true: mode picker, Navigator.pop(context, imagePath)
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
    _visionController.startMockDetection();
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  /// Capture foto dan handle sesuai mode
  Future<void> _handleCapture() async {
    final image = await _visionController.takePhoto();
    if (image == null) return;

    if (widget.returnImagePath) {
      // Mode picker: langsung kembalikan path ke editor
      if (context.mounted) {
        Navigator.pop(context, image.path);
      }
    } else {
      // Mode standalone: tampilkan snackbar dengan preview
      setState(() {
        _lastCapturedPath = image.path;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto tersimpan: ${image.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.returnImagePath
              ? "Ambil Foto untuk Catatan"
              : "Smart-Patrol Vision",
        ),
        actions: [
          // Flashlight toggle
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) => IconButton(
              icon: Icon(
                _visionController.isFlashlightOn
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
              onPressed: _visionController.toggleFlashlight,
              tooltip: 'Toggle Flashlight',
            ),
          ),
          // Overlay toggle
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
          return _buildVisionStack();
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tombol capture
          FloatingActionButton(
            heroTag: 'capture_fab',
            onPressed: _handleCapture,
            tooltip: widget.returnImagePath ? 'Pakai Foto Ini' : 'Ambil Foto',
            child: Icon(widget.returnImagePath ? Icons.check : Icons.camera),
          ),

          // Jika mode standalone dan ada foto terakhir, tampilkan preview kecil
          if (!widget.returnImagePath && _lastCapturedPath != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
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
          ],
        ],
      ),
    );
  }

  /// Preview foto terakhir fullscreen
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
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            "Menghubungkan ke Kamera...",
            style: TextStyle(fontSize: 16),
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

  Widget _buildVisionStack() {
    final cameraController = _visionController.controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Kamera
        Center(
          child: AspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController.value.previewSize!.width,
                  height: cameraController.value.previewSize!.height,
                  child: CameraPreview(cameraController),
                ),
              ),
            ),
          ),
        ),

        // Layer 2: Overlay deteksi
        if (_visionController.isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(_visionController.currentDetections),
            ),
          ),

        // Layer 3: Banner petunjuk jika mode picker
        if (widget.returnImagePath)
          Positioned(
            bottom: 100,
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
      ],
    );
  }
}

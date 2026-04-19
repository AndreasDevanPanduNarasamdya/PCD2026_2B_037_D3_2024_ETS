import 'dart:io';
import 'package:flutter/material.dart';
import 'image_processing_controller.dart';

class ImageProcessingView extends StatefulWidget {
  final String initialImagePath;

  const ImageProcessingView({super.key, required this.initialImagePath});

  @override
  State<ImageProcessingView> createState() => _ImageProcessingViewState();
}

class _ImageProcessingViewState extends State<ImageProcessingView> {
  late ImageProcessingController _controller;
  String? _activeOperation; // tracks which button is highlighted

  @override
  void initState() {
    super.initState();
    _controller = ImageProcessingController();
    _controller.setImage(widget.initialImagePath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply(String label, Future<void> Function() operation) async {
    setState(() => _activeOperation = label);
    await operation();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Manipulasi PCD"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            tooltip: "Gunakan Gambar Ini",
            onPressed: () {
              Navigator.pop(context, _controller.currentImagePath);
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return Column(
            children: [
              // Image preview — takes all available space
              Expanded(
                child: _controller.isProcessing
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              "Memproses Matriks Piksel...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.black,
                        padding: const EdgeInsets.all(12),
                        child: Image.file(
                          File(_controller.currentImagePath!),
                          fit: BoxFit.contain,
                          // force rebuild when path changes
                          key: ValueKey(_controller.currentImagePath),
                        ),
                      ),
              ),

              // Operations panel — same style as camera filter bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const Text(
                      "Operasi Pengolahan Citra Digital",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scrollable filter chips — same style as camera view
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _opChip(
                            label: 'Grayscale',
                            icon: Icons.filter_b_and_w,
                            onTap: () =>
                                _apply('Grayscale', _controller.applyGrayscale),
                          ),
                          _opChip(
                            label: 'Gaussian Blur',
                            icon: Icons.blur_on,
                            onTap: () => _apply(
                              'Gaussian Blur',
                              _controller.applyGaussianBlur,
                            ),
                          ),
                          _opChip(
                            label: 'Median Filter',
                            icon: Icons.grain,
                            onTap: () => _apply(
                              'Median Filter',
                              _controller.applyMedianFilter,
                            ),
                          ),
                          _opChip(
                            label: 'Sharpen',
                            icon: Icons.auto_fix_high,
                            onTap: () =>
                                _apply('Sharpen', _controller.applySharpen),
                          ),
                          _opChip(
                            label: 'Brightness',
                            icon: Icons.brightness_6,
                            onTap: () => _apply(
                              'Brightness',
                              () => _controller.applyBrightness(50),
                            ),
                          ),
                          _opChip(
                            label: 'Contrast',
                            icon: Icons.contrast,
                            onTap: () =>
                                _apply('Contrast', _controller.applyContrast),
                          ),
                          _opChip(
                            label: 'Inverse',
                            icon: Icons.invert_colors,
                            onTap: () =>
                                _apply('Inverse', _controller.applyInverse),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Active operation label
                    if (_activeOperation != null)
                      Center(
                        child: Text(
                          'Terakhir: $_activeOperation',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Reset button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _controller.setImage(widget.initialImagePath);
                          setState(() => _activeOperation = null);
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Reset ke Foto Asli',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _opChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isActive = _activeOperation == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

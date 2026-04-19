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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manipulasi PCD"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Gunakan Gambar Ini",
            onPressed: () {
              // Return the modified image path back to the LogEditor
              Navigator.pop(context, _controller.currentImagePath);
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isProcessing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memproses Matriks Piksel..."),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Image Preview
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Image.file(
                    File(_controller.currentImagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // PCD Tools Panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Operasi Pengolahan Citra Digital:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _controller.applyGrayscale(),
                          icon: const Icon(Icons.gradient),
                          label: const Text("Grayscale"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _controller.applyBrightness(50),
                          icon: const Icon(Icons.brightness_6),
                          label: const Text("Brightness (+50)"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _controller.applyInverse(),
                          icon: const Icon(Icons.invert_colors),
                          label: const Text("Inverse (NOT)"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

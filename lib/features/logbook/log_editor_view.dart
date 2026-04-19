import 'dart:io';
import 'package:flutter/material.dart';
import 'models/log_model.dart';
import '../auth/user_model.dart';
import '../vision/vision_view.dart';
import '../vision/image_processing_view.dart';

class LogEditorView extends StatefulWidget {
  final UserModel currentUser;
  final LogModel? existingLog;
  final Function(LogModel) onSave;

  const LogEditorView({
    super.key,
    required this.currentUser,
    this.existingLog,
    required this.onSave,
  });

  @override
  State<LogEditorView> createState() => _LogEditorViewState();
}

class _LogEditorViewState extends State<LogEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory;

  // Path foto yang diambil dari kamera
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingLog?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingLog?.description ?? '',
    );
    _selectedCategory = widget.existingLog?.category ?? 'Pribadi';
    _capturedImagePath = widget.existingLog?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Buka VisionView dalam mode picker, tunggu hasil path foto
  Future<void> _openCamera() async {
    // 1. Ambil foto dari kamera (mode picker: returnImagePath = true)
    final String? rawImagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const VisionView(returnImagePath: true),
      ),
    );

    // 2. Jika foto berhasil diambil, arahkan ke halaman Manipulasi PCD
    if (rawImagePath != null && context.mounted) {
      final String? processedImagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ImageProcessingView(initialImagePath: rawImagePath),
        ),
      );

      // 3. Simpan hasil gambar yang sudah diproses ke form
      if (processedImagePath != null) {
        setState(() {
          _capturedImagePath = processedImagePath;
        });
      }
    }
  }

  /// Hapus foto yang sudah diambil
  void _removePhoto() {
    setState(() {
      _capturedImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingLog == null ? "Tambah Catatan Baru" : "Edit Catatan",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Judul ---
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Judul",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Isi / Deskripsi ---
            Expanded(
              child: TextField(
                controller: _descController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: "Isi (Mendukung Format Markdown)",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Section Foto Kamera ---
            _buildCameraSection(),
            const SizedBox(height: 16),

            // --- Dropdown Kategori ---
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(),
              ),
              items: ['Pekerjaan', 'Pribadi', 'Urgent'].map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),

            // --- Tombol Simpan ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveLog,
                child: const Text(
                  "Simpan Catatan",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget section kamera: tombol ambil foto + preview hasil
  Widget _buildCameraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Foto Pendukung",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),

        if (_capturedImagePath == null)
          // Belum ada foto: tampilkan tombol kamera
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Ambil Foto dari Kamera"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else
          // Sudah ada foto: tampilkan preview + tombol ganti/hapus
          Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_capturedImagePath!),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Tombol hapus di pojok kanan atas
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removePhoto,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tombol ganti foto
              TextButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.refresh),
                label: const Text("Ganti Foto"),
              ),
            ],
          ),
      ],
    );
  }

  void _saveLog() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul tidak boleh kosong!")),
      );
      return;
    }

    final newLog = LogModel(
      id:
          widget.existingLog?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text,
      category: _selectedCategory,
      date: DateTime.now().toString(),
      isSynced: true,
      authorId: widget.existingLog?.authorId ?? widget.currentUser.username,
      teamId: widget.currentUser.teamId,
      imagePath: _capturedImagePath,
    );

    widget.onSave(newLog);
    Navigator.pop(context);
  }
}

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'models/log_model.dart';
import '../auth/user_model.dart';

class LogEditorView extends StatefulWidget {
  final UserModel currentUser;
  final LogModel?
  existingLog; // Jika null berarti Tambah Baru, jika ada isinya berarti Edit
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

  @override
  void initState() {
    super.initState();
    // Isi field jika sedang mode Edit
    _titleController = TextEditingController(
      text: widget.existingLog?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingLog?.description ?? '',
    );
    _selectedCategory = widget.existingLog?.category ?? 'Pribadi';
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
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Judul",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _descController,
                maxLines: null, // Memungkinkan teks panjang untuk Markdown
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final newLog = LogModel(
                    id: widget.existingLog?.id ?? ObjectId().toHexString(),
                    title: _titleController.text,
                    description: _descController.text,
                    category: _selectedCategory,
                    date: DateTime.now().toString(),
                    isSynced: false,
                    authorId:
                        widget.existingLog?.authorId ??
                        widget.currentUser.username, // Pertahankan pemilik lama
                    teamId: widget.currentUser.teamId,
                  );
                  widget.onSave(newLog);
                  Navigator.pop(context);
                },
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
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'log_controller.dart';
import './models/log_model.dart';
import '../auth/user_model.dart';
import 'log_editor_view.dart';
import '../auth/login_view.dart';
import '../vision/vision_view.dart';

class LogView extends StatefulWidget {
  final UserModel currentUser;
  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  final TextEditingController contentSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadFromDisk();
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Colors.blue.shade100;
      case 'Urgent':
        return Colors.red.shade100;
      default:
        return Colors.green.shade100;
    }
  }

  void _confirmDelete(LogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan?"),
        content: const Text("Data tidak bisa dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _controller.removeLog(log); // Gunakan objek, bukan index
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openEditor({int? index, LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorView(
          currentUser: widget.currentUser,
          existingLog: log,
          onSave: (newLog) {
            if (index == null) {
              _controller.addLog(newLog);
            } else {
              _controller.updateLog(index, newLog);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Collab LogBook", style: TextStyle(fontSize: 18)),
            Text(
              "User: ${widget.currentUser.username} | Role: ${widget.currentUser.role}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Ya, Keluar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: contentSearch,
              decoration: const InputDecoration(
                hintText: "Cari catatan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _controller.searchLog(value),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, currentLogs, child) {
                if (currentLogs.isEmpty) {
                  final isDatabaseEmpty =
                      _controller.logsNotifier.value.isEmpty;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          isDatabaseEmpty
                              ? 'lib/assets/contentsmissing.png'
                              : 'lib/assets/contentsnotfound.png',
                          width: isDatabaseEmpty ? 80 : 200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isDatabaseEmpty
                              ? "Belum ada catatan nih."
                              : "Catatan tidak ditemukan.",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];

                    // --- BUG FIX: Cari index di logsNotifier (bukan filteredLogs) ---
                    // Ini penting saat user sedang search/filter
                    final actualIndex = _controller.logsNotifier.value.indexOf(
                      log,
                    );

                    DateTime parsedDate = DateTime.parse(log.date);
                    String formattedDate = DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(parsedDate);

                    bool canModify =
                        (widget.currentUser.role == 'Ketua') ||
                        (log.authorId == widget.currentUser.username);

                    return Card(
                      color: _getCategoryColor(log.category),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.save, color: Colors.green),
                        title: Text(
                          log.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Oleh: ${log.authorId} | $formattedDate",
                        ),
                        children: [
                          // Tampilkan foto jika ada
                          if (log.imagePath != null &&
                              log.imagePath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(log.imagePath!),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        "Foto tidak dapat ditampilkan",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Deskripsi markdown
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: MarkdownBody(data: log.description),
                          ),

                          // Tombol edit/hapus
                          if (canModify)
                            ButtonBar(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _openEditor(
                                    index:
                                        actualIndex, // pakai index yang benar
                                    log: log,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(log), // pakai objek
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tombol buka kamera standalone (PCD Scanner)
          FloatingActionButton(
            heroTag: 'pcd_scanner_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisionView()),
              );
            },
            backgroundColor: Colors.blueAccent,
            tooltip: "Buka Kamera PCD",
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Tombol tambah catatan baru
          FloatingActionButton(
            heroTag: 'add_log_fab',
            onPressed: () => _openEditor(),
            tooltip: "Tambah Catatan",
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

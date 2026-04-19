import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // FR-06: Markdown Support
import 'package:intl/intl.dart';
import 'log_controller.dart';
import './models/log_model.dart';
import '../auth/user_model.dart';
import 'log_editor_view.dart';
import '../auth/login_view.dart';

class LogView extends StatefulWidget {
  final UserModel currentUser; // FR-04: Menerima Data User Lengkap
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
    // Panggil data cloud sesaat setelah tampilan dirender, berdasarkan Team ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchLogs(widget.currentUser.teamId);
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

  void _confirmDelete(int index) {
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
              await _controller.removeLog(index);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FR-02: Navigasi ke Halaman Editor ---
  void _openEditor({int? index, LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorView(
          currentUser: widget.currentUser,
          existingLog: log,
          onSave: (newLog) {
            if (index == null) {
              _controller.addLog(newLog); // Tambah Baru
            } else {
              _controller.updateLog(index, newLog); // Edit
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
              "User: ${widget.currentUser.username} | Role: ${widget.currentUser.role} | Tim: ${widget.currentUser.teamId}",
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
              // Tampilkan Pop-up Konfirmasi Logout
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text(
                    "Apakah Anda yakin ingin keluar dari akun ini?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context), // Batal, tutup dialog
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog dulu

                        // Hapus semua riwayat navigasi dan kembali ke halaman Login
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                          (route) =>
                              false, // Ini yang membuat user tidak bisa menekan tombol "Back" ke logbook
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
          ValueListenableBuilder<bool>(
            valueListenable: _controller.isOffline,
            builder: (context, isOffline, child) {
              if (!isOffline) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  "Mode offline, Mencari jaringan internet",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: contentSearch,
              decoration: const InputDecoration(hintText: "Search for Notes"),
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

                return RefreshIndicator(
                  onRefresh: () async =>
                      await _controller.fetchLogs(widget.currentUser.teamId),
                  child: ListView.builder(
                    itemCount: currentLogs.length,
                    itemBuilder: (context, index) {
                      final log = currentLogs[index];
                      DateTime parsedDate = DateTime.parse(log.date);
                      String formattedDate = DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(parsedDate);

                      // --- FR-04: GATEKEEPER POLICY ---
                      // Apakah user ini boleh mengedit/menghapus catatan ini?
                      bool canModify =
                          (widget.currentUser.role == 'Ketua') ||
                          (log.authorId == widget.currentUser.username);

                      return Card(
                        color: _getCategoryColor(log.category),
                        child: ExpansionTile(
                          // Menggunakan ExpansionTile agar Markdown panjang bisa ditutup/buka
                          leading: Icon(
                            log.isSynced ? Icons.cloud_done : Icons.cloud_off,
                            color: log.isSynced ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            log.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Oleh: ${log.authorId} | $formattedDate",
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              // --- FR-06: TAMPILKAN SEBAGAI MARKDOWN ---
                              child: MarkdownBody(data: log.description),
                            ),
                            if (canModify) // Tombol hanya muncul jika Gatekeeper mengizinkan
                              ButtonBar(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _openEditor(index: index, log: log),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmDelete(index),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(), // Buka editor kosong
        child: const Icon(Icons.add),
      ),
    );
  }
}

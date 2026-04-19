import '../../services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import './models/log_model.dart';
import '../auth/user_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final ValueNotifier<bool> isOffline = ValueNotifier(false);

  // Ambil kotak Hive yang sudah dibuka di main.dart
  final Box<LogModel> _logBox = Hive.box<LogModel>('logbookBox');

  LogController() {
    loadFromDisk().then((_) {});

    InternetConnectionChecker.instance.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected ||
          status == InternetConnectionStatus.slow) {
        if (isOffline.value == true) {
          isOffline.value = false;
          print("Internet kembali! Memulai auto-sync...");
          syncOfflineLogs();
        }
      } else {
        isOffline.value = true;
        print("Koneksi internet terputus.");
      }
    });
  }

  // --- FR-01: Load data dari Hive ---
  Future<void> loadFromDisk() async {
    final List<LogModel> localData = _logBox.values.toList();
    logsNotifier.value = localData;
    filteredLogs.value = localData;
  }

  // --- FR-01: Simpan data ke Hive ---
  Future<void> saveToDisk() async {
    await _logBox.clear(); // Bersihkan data lama
    await _logBox.addAll(logsNotifier.value); // Simpan semua data baru
  }

  Future<void> fetchLogs(String teamId) async {
    try {
      await syncOfflineLogs();
      final cloudLogs = await MongoService().getLogs(
        teamId,
      ); // Tarik sesuai tim

      logsNotifier.value = cloudLogs;
      filteredLogs.value = cloudLogs;
      isOffline.value = false;
      await saveToDisk();
    } catch (e) {
      isOffline.value = true;
      print("Gagal mengambil data dari database: $e");
    }
  }

  Future<void> addLog(LogModel newLog) async {
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;
    await saveToDisk();
    await syncOfflineLogs();
  }

  Future<void> updateLog(int index, LogModel updatedLog) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = updatedLog;

    logsNotifier.value = currentLogs;
    filteredLogs.value = currentLogs;
    await saveToDisk();

    try {
      await MongoService().updateLog(updatedLog);
      updatedLog.isSynced = true;

      logsNotifier.value = List.from(currentLogs);
      filteredLogs.value = List.from(currentLogs);
      await saveToDisk();
      isOffline.value = false;
    } catch (e) {
      isOffline.value = true;
    }
  }

  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final logToDelete = currentLogs[index];

    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    filteredLogs.value = currentLogs;
    await saveToDisk();

    if (logToDelete.id != null) {
      try {
        // --- UBAH BARIS INI: Konversi String kembali ke ObjectId ---
        await MongoService().deleteLog(ObjectId.fromHexString(logToDelete.id!));

        isOffline.value = false;
      } catch (e) {
        isOffline.value = true;
      }
    }
  }

  Future<void> syncOfflineLogs() async {
    final unsyncedLogs = logsNotifier.value
        .where((log) => log.isSynced == false)
        .toList();
    if (unsyncedLogs.isEmpty) return;

    try {
      for (var log in unsyncedLogs) {
        log.isSynced = true;
        await MongoService().insertLog(log);
        log.save();
      }
      await saveToDisk();
      isOffline.value = false;
      logsNotifier.value = List.from(logsNotifier.value);
      filteredLogs.value = List.from(filteredLogs.value);
      print("Berhasil sinkronisasi data offline ke Cloud!");
    } catch (e) {
      for (var log in unsyncedLogs) {
        log.isSynced = false;
        try {
          log.save();
        } catch (_) {} // Aman untuk Hive
      }
      isOffline.value = true;

      // --- TAMBAHKAN 2 BARIS INI: Paksa UI refresh jadi abu-abu ---
      logsNotifier.value = List.from(logsNotifier.value);
      filteredLogs.value = List.from(filteredLogs.value);

      print("Masih offline, sinkronisasi tertunda.");
    }
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}

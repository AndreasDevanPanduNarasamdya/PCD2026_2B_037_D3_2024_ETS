import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  final Box<LogModel> _logBox = Hive.box<LogModel>('logbookBox');

  LogController() {
    loadFromDisk();
  }

  // --- Load semua data dari Hive ---
  Future<void> loadFromDisk() async {
    final List<LogModel> localData = _logBox.values.toList();
    logsNotifier.value = localData;
    filteredLogs.value = localData;
  }

  // --- Simpan semua data ke Hive ---
  Future<void> saveToDisk() async {
    await _logBox.clear();
    await _logBox.addAll(logsNotifier.value);
  }

  Future<void> addLog(LogModel newLog) async {
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;
    await saveToDisk();
  }

  Future<void> updateLog(int index, LogModel updatedLog) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = updatedLog;
    logsNotifier.value = currentLogs;
    filteredLogs.value = currentLogs;
    await saveToDisk();
  }

  Future<void> removeLog(LogModel logToDelete) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.remove(logToDelete);
    logsNotifier.value = currentLogs;
    filteredLogs.value = currentLogs;
    await saveToDisk();
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

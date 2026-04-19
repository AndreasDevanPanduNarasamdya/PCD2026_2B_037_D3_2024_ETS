import 'dart:developer' as dev;
import 'package:intl/intl.dart'; // Tetap kita gunakan untuk presisi waktu
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      String timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
      String dateStr = DateFormat(
        'dd-MM-yyyy',
      ).format(DateTime.now()); // TASK 4: Format Nama File
      String label = _getLabel(level);
      String color = _getColor(level);

      String logText = '[$timeStr][$label][$source] -> $message';

      // 1. Output ke Debug Console
      dev.log(message, name: source, time: DateTime.now(), level: level * 100);
      print('$color$logText\x1B[0m');

      // 2. TASK 4: Tulis ke File Fisik di folder /logs
      final directory = Directory('logs');
      if (!await directory.exists()) {
        await directory.create();
      }

      final file = File('logs/$dateStr.log');
      await file.writeAsString('$logText\n', mode: FileMode.append);
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m';
      case 2:
        return '\x1B[32m';
      case 3:
        return '\x1B[34m';
      default:
        return '\x1B[0m';
    }
  }
}

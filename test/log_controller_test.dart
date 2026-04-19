import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:plssssgithub/features/logbook/log_controller.dart'; 
import 'package:plssssgithub/features/logbook/models/log_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // This runs ONCE before any tests start to prep the fake environment
  setUpAll(() async {
    // 1. Create a temporary folder for Hive to use during the test
    final path = Directory.current.path + '/test/hive_temp';
    Hive.init(path);

    // 2. Register your LogModel adapter (Crucial for custom models!)
    // NOTE: If your adapter has a different name, change it here.
    Hive.registerAdapter(LogModelAdapter()); 

    // 3. Open the box so LogController can find it without crashing
    await Hive.openBox<LogModel>('logbookBox');
  });

  // This cleans up the fake database after all tests are done
  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('LogController Tests', () {
    
    test('updateLog should throw RangeError if index is out of bounds', () async {
      final controller = LogController(); 
      
      final dummyLog = LogModel(
        title: "Test Error",
        description: "This should fail",
        date: DateTime.now().toIso8601String(),
        authorId: "user123",
        teamId: "TEAM_A",
      );

      // We expect the code to crash with a RangeError
      expect(
        () async => await controller.updateLog(99, dummyLog), 
        throwsA(isA<RangeError>()), 
        reason: 'Expected a RangeError because index 99 does not exist'
      );
    });

  });
}
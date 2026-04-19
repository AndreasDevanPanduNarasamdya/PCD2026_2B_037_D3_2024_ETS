import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './features/onboarding/onboarding_view.dart';
import './features/logbook/models/log_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI HIVE (offline storage) ---
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('logbookBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OnBoardingView(),
    );
  }
}

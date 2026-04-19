import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel extends HiveObject {
  @HiveField(0)
  String? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String date;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String category;
  @HiveField(5)
  bool isSynced;
  @HiveField(6)
  final String authorId;
  @HiveField(7)
  final String teamId;
  @HiveField(8)
  final String? imagePath; // Path foto dari kamera (opsional)

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    this.category = 'Pribadi',
    this.isSynced = true,
    required this.authorId,
    required this.teamId,
    this.imagePath,
  });
}

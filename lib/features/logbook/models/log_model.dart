import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

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

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    this.category = 'Pribadi',
    this.isSynced = true,
    required this.authorId,
    required this.teamId,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    var rawId = map['_id'];
    String? parsedId;

    if (rawId is ObjectId) {
      parsedId = rawId.toHexString();
    } else if (rawId is String) {
      parsedId = rawId;
    }

    return LogModel(
      id: parsedId,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pribadi',
      isSynced: true,
      authorId: map['authorId'] ?? 'Unknown',
      teamId: map['teamId'] ?? 'NoTeam',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'title': title,
      'date': date,
      'description': description,
      'category': category,
      'isSynced': isSynced,
      'authorId': authorId,
      'teamId': teamId,
    };
  }
}

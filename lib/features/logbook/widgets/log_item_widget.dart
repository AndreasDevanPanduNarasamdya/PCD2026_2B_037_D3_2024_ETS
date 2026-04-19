// Superclass yang stabil
abstract class BaseLog {
  String get title;
}

// Subclass yang menggantikan tanpa merusak fungsi
class LectureLog extends BaseLog {
  @override
  String get title => "Log Kuliah";
}

// UI tetap bisa menampilkan keduanya tanpa tahu tipe spesifiknya
void displayLog(BaseLog log) {
  print(log.title); 
}

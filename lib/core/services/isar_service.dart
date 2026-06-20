import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/habits/data/models/habit_log_model.dart';
import '../../features/reading_list/data/models/book_model.dart';

class IsarService {
  static Isar? _instance;

  static Isar get instance {
    if (_instance == null) {
      throw StateError('Isar not initialized. Call IsarService.init() first.');
    }
    return _instance!;
  }

  static Future<void> init() async {
    if (_instance != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [HabitSchema, HabitLogSchema, BookSchema],
      directory: dir.path,
    );
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}

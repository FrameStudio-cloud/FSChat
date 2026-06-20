import 'package:isar/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';

class HabitLocalSource {
  Isar get _isar => IsarService.instance;

  Stream<List<Habit>> watchHabits(String userId) {
    return _isar.habits
        .where()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true)
        .map((list) => list.where((h) => !h.archived).toList());
  }

  Future<List<Habit>> getAllHabits(String userId) async {
    return _isar.habits
        .where()
        .userIdEqualTo(userId)
        .filter()
        .archivedEqualTo(false)
        .findAll();
  }

  Future<Habit?> getByFirestoreId(String firestoreId) async {
    return _isar.habits.where().firestoreIdEqualTo(firestoreId).findFirst();
  }

  Future<void> putHabit(Habit habit) async {
    await _isar.writeTxn(() async {
      await _isar.habits.put(habit);
    });
  }

  Future<void> deleteHabit(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.habits.delete(id);
    });
  }

  Future<void> deleteLogsForHabit(String habitFirestoreId) async {
    await _isar.writeTxn(() async {
      await _isar.habitLogs
          .where()
          .habitFirestoreIdEqualTo(habitFirestoreId)
          .deleteAll();
    });
  }

  Future<void> updateStreak(
      String firestoreId, int current, int longest) async {
    final habit = await getByFirestoreId(firestoreId);
    if (habit != null) {
      await _isar.writeTxn(() async {
        habit.currentStreak = current;
        habit.longestStreak = longest;
        await _isar.habits.put(habit);
      });
    }
  }

  Stream<List<HabitLog>> watchLogs(String habitFirestoreId) {
    return _isar.habitLogs
        .where()
        .habitFirestoreIdEqualTo(habitFirestoreId)
        .watch(fireImmediately: true);
  }

  Future<List<HabitLog>> getLogsForDate(String dateString) async {
    return _isar.habitLogs.where().dateStringEqualTo(dateString).findAll();
  }

  Future<HabitLog?> getLog(String habitFirestoreId, String dateString) async {
    return _isar.habitLogs
        .where()
        .habitFirestoreIdEqualTo(habitFirestoreId)
        .filter()
        .dateStringEqualTo(dateString)
        .findFirst();
  }

  Future<HabitLog?> getLogByFirestoreId(String firestoreId) async {
    return _isar.habitLogs.where().firestoreIdEqualTo(firestoreId).findFirst();
  }

  Future<void> putLog(HabitLog log) async {
    await _isar.writeTxn(() async {
      await _isar.habitLogs.put(log);
    });
  }

  Future<void> deleteLog(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.habitLogs.delete(id);
    });
  }

  Future<void> deleteLogByFirestoreId(String firestoreId) async {
    final log = await getLogByFirestoreId(firestoreId);
    if (log != null) {
      await _isar.writeTxn(() async {
        await _isar.habitLogs.delete(log.id);
      });
    }
  }

  Future<List<HabitLog>> getLogsForHabit(String habitFirestoreId) async {
    return _isar.habitLogs
        .where()
        .habitFirestoreIdEqualTo(habitFirestoreId)
        .findAll();
  }

  Future<int> calculateStreak(String habitFirestoreId) async {
    final logs = await getLogsForHabit(habitFirestoreId);
    final loggedDates = logs
        .where((l) => l.status == 'completed')
        .map((l) => l.dateString)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (loggedDates.isEmpty) return 0;

    final today = _todayString();
    int streak = 0;
    for (int i = 0; i < loggedDates.length; i++) {
      final expected = _subtractDays(today, i);
      if (loggedDates[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<Map<String, int>> calculateAllStreaks(String userId) async {
    final habits = await getAllHabits(userId);
    final result = <String, int>{};
    for (final habit in habits) {
      result[habit.firestoreId] = await calculateStreak(habit.firestoreId);
    }
    return result;
  }

  Future<Set<String>> getAllLoggedDateStrings(String userId) async {
    final habits = await getAllHabits(userId);
    final firestoreIds = habits.map((h) => h.firestoreId).toList();
    final allLogs = <HabitLog>[];
    for (final fid in firestoreIds) {
      final logs = await getLogsForHabit(fid);
      allLogs.addAll(logs);
    }
    return allLogs
        .where((l) => l.status == 'completed')
        .map((l) => l.dateString)
        .toSet();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _subtractDays(String date, int days) {
    final parts = date.split('-');
    final dt =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final sub = dt.subtract(Duration(days: days));
    return '${sub.year}-${sub.month.toString().padLeft(2, '0')}-${sub.day.toString().padLeft(2, '0')}';
  }
}

import 'package:uuid/uuid.dart';
import '../datasources/habit_local_source.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';

class HabitRepository {
  final HabitLocalSource _local;
  final Uuid _uuid = Uuid();

  HabitRepository() : _local = HabitLocalSource();

  Stream<List<Habit>> watchHabits(String userId) => _local.watchHabits(userId);

  Future<List<Habit>> getAllHabits(String userId) =>
      _local.getAllHabits(userId);

  Future<Habit?> getByFirestoreId(String firestoreId) =>
      _local.getByFirestoreId(firestoreId);

  Future<String> createHabit({
    required String userId,
    required String name,
    required String colorHex,
    required String frequency,
    List<String> customDays = const [],
    bool reminderEnabled = false,
    int reminderHour = 9,
    int reminderMinute = 0,
    String category = 'General',
    String habitType = 'boolean',
    double targetCount = 1,
    String unit = '',
  }) async {
    final firestoreId = _uuid.v4();
    final habit = Habit()
      ..firestoreId = firestoreId
      ..userId = userId
      ..name = name
      ..colorHex = colorHex
      ..frequency = frequency
      ..customDays = customDays
      ..createdAt = DateTime.now()
      ..reminderEnabled = reminderEnabled
      ..reminderHour = reminderHour
      ..reminderMinute = reminderMinute
      ..category = category
      ..habitType = habitType
      ..targetCount = targetCount
      ..unit = unit;
    await _local.putHabit(habit);
    return firestoreId;
  }

  Future<void> updateHabit(
    String firestoreId, {
    String? name,
    String? colorHex,
    String? frequency,
    List<String>? customDays,
    bool? archived,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? category,
    String? habitType,
    double? targetCount,
    String? unit,
  }) async {
    final existing = await _local.getByFirestoreId(firestoreId);
    if (existing == null) return;
    final updated = existing.copyWith(
      name: name,
      colorHex: colorHex,
      frequency: frequency,
      customDays: customDays,
      archived: archived,
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      category: category,
      habitType: habitType,
      targetCount: targetCount,
      unit: unit,
    );
    await _local.putHabit(updated);
  }

  Future<void> deleteHabit(String firestoreId) async {
    final existing = await _local.getByFirestoreId(firestoreId);
    if (existing != null) {
      await _local.deleteLogsForHabit(firestoreId);
      await _local.deleteHabit(existing.id);
    }
  }

  Stream<List<HabitLog>> watchLogs(String habitFirestoreId) =>
      _local.watchLogs(habitFirestoreId);

  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final dateString = _dateString(date);
    return _local.getLogsForDate(dateString);
  }

  Future<void> toggleLog(String habitFirestoreId, String dateString,
      {double count = 0}) async {
    final existing = await _local.getLog(habitFirestoreId, dateString);
    if (existing != null) {
      await _local.deleteLog(existing.id);
    }
    if (existing == null || count > 0) {
      final firestoreId = _uuid.v4();
      final log = HabitLog()
        ..firestoreId = firestoreId
        ..habitFirestoreId = habitFirestoreId
        ..dateString = dateString
        ..status = 'completed'
        ..count = count
        ..createdAt = DateTime.now();
      await _local.putLog(log);
    }
    await _recalcStreak(habitFirestoreId);
  }

  Future<void> updateLogCount(
      String habitFirestoreId, String dateString, double count) async {
    final existing = await _local.getLog(habitFirestoreId, dateString);
    if (existing != null) {
      existing.count = count;
      existing.status = count > 0 ? 'completed' : 'skipped';
      await _local.putLog(existing);
    }
    await _recalcStreak(habitFirestoreId);
  }

  Future<HabitLog?> getLog(String habitFirestoreId, String dateString) =>
      _local.getLog(habitFirestoreId, dateString);

  Future<void> skipHabit(String habitFirestoreId, String dateString) async {
    final existing = await _local.getLog(habitFirestoreId, dateString);
    if (existing != null) {
      await _local.deleteLog(existing.id);
    }
    final firestoreId = _uuid.v4();
    final log = HabitLog()
      ..firestoreId = firestoreId
      ..habitFirestoreId = habitFirestoreId
      ..dateString = dateString
      ..status = 'skipped'
      ..createdAt = DateTime.now();
    await _local.putLog(log);
    await _recalcStreak(habitFirestoreId);
  }

  Future<void> updateNote(
      String habitFirestoreId, String dateString, String note) async {
    final existing = await _local.getLog(habitFirestoreId, dateString);
    if (existing != null) {
      existing.note = note;
      await _local.putLog(existing);
    }
  }

  Future<void> updateLogStatus(String firestoreId, String status) async {
    final log = await _local.getLogByFirestoreId(firestoreId);
    if (log != null) {
      log.status = status;
      await _local.putLog(log);
    }
  }

  Future<int> calculateStreak(String habitFirestoreId) =>
      _local.calculateStreak(habitFirestoreId);

  Future<Map<String, int>> calculateAllStreaks(String userId) =>
      _local.calculateAllStreaks(userId);

  Future<Set<String>> getAllLoggedDateStrings(String userId) =>
      _local.getAllLoggedDateStrings(userId);

  Future<void> _recalcStreak(String habitFirestoreId) async {
    final streak = await _local.calculateStreak(habitFirestoreId);
    final habit = await _local.getByFirestoreId(habitFirestoreId);
    if (habit != null) {
      final longest =
          habit.longestStreak > streak ? habit.longestStreak : streak;
      habit.currentStreak = streak;
      habit.longestStreak = longest;
      await _local.putHabit(habit);
    }
  }

  String _dateString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

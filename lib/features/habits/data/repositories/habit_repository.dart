import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../datasources/habit_local_source.dart';
import '../datasources/habit_remote_source.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';

class HabitRepository {
  final HabitLocalSource _local;
  final HabitRemoteSource _remote;
  final Uuid _uuid = Uuid();

  HabitRepository(FirebaseFirestore firestore)
      : _local = HabitLocalSource(),
        _remote = HabitRemoteSource(firestore);

  Stream<List<Habit>> watchHabits(String userId) => _local.watchHabits(userId);

  Future<List<Habit>> getAllHabits(String userId) =>
      _local.getAllHabits(userId);

  Future<void> createHabit({
    required String userId,
    required String name,
    required String colorHex,
    required String frequency,
    List<String> customDays = const [],
  }) async {
    final firestoreId = _uuid.v4();
    final habit = Habit()
      ..firestoreId = firestoreId
      ..userId = userId
      ..name = name
      ..colorHex = colorHex
      ..frequency = frequency
      ..customDays = customDays
      ..createdAt = DateTime.now();
    await _local.putHabit(habit);
    await _remote.syncHabit(habit);
  }

  Future<void> updateHabit(
    String firestoreId, {
    String? name,
    String? colorHex,
    String? frequency,
    List<String>? customDays,
    bool? archived,
  }) async {
    final existing = await _local.getByFirestoreId(firestoreId);
    if (existing == null) return;
    final updated = existing.copyWith(
      name: name,
      colorHex: colorHex,
      frequency: frequency,
      customDays: customDays,
      archived: archived,
    );
    await _local.putHabit(updated);
    await _remote.syncHabit(updated);
  }

  Future<void> deleteHabit(String firestoreId) async {
    final existing = await _local.getByFirestoreId(firestoreId);
    if (existing != null) {
      await _local.deleteLogsForHabit(firestoreId);
      await _local.deleteHabit(existing.id);
    }
    await _remote.deleteHabit(firestoreId);
  }

  Stream<List<HabitLog>> watchLogs(String habitFirestoreId) =>
      _local.watchLogs(habitFirestoreId);

  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final dateString = _dateString(date);
    return _local.getLogsForDate(dateString);
  }

  Future<void> toggleLog(String habitFirestoreId, String dateString) async {
    final existing = await _local.getLog(habitFirestoreId, dateString);
    if (existing != null) {
      await _local.deleteLog(existing.id);
      await _remote.deleteLog(existing.firestoreId);
    } else {
      final firestoreId = _uuid.v4();
      final log = HabitLog()
        ..firestoreId = firestoreId
        ..habitFirestoreId = habitFirestoreId
        ..dateString = dateString
        ..status = 'completed'
        ..createdAt = DateTime.now();
      await _local.putLog(log);
      await _remote.syncLog(log);
    }
    await _recalcStreak(habitFirestoreId);
  }

  Future<void> skipHabit(String habitFirestoreId, String dateString) async {
    final existing = await _local.getLog(habitFirestoreId, dateString);
    if (existing != null) {
      await _local.deleteLog(existing.id);
      if (existing.firestoreId.isNotEmpty) {
        await _remote.deleteLog(existing.firestoreId);
      }
    }
    final firestoreId = _uuid.v4();
    final log = HabitLog()
      ..firestoreId = firestoreId
      ..habitFirestoreId = habitFirestoreId
      ..dateString = dateString
      ..status = 'skipped'
      ..createdAt = DateTime.now();
    await _local.putLog(log);
    await _remote.syncLog(log);
    await _recalcStreak(habitFirestoreId);
  }

  Future<void> updateNote(
      String habitFirestoreId, String dateString, String note) async {
    final existing = await _local.getLog(habitFirestoreId, dateString);
    if (existing != null) {
      existing.note = note;
      await _local.putLog(existing);
      await _remote.syncLog(existing);
    }
  }

  Future<void> updateLogStatus(String firestoreId, String status) async {
    final log = await _local.getLogByFirestoreId(firestoreId);
    if (log != null) {
      log.status = status;
      await _local.putLog(log);
      await _remote.syncLog(log);
    }
  }

  Future<int> calculateStreak(String habitFirestoreId) =>
      _local.calculateStreak(habitFirestoreId);

  Future<Map<String, int>> calculateAllStreaks(String userId) =>
      _local.calculateAllStreaks(userId);

  Future<Set<String>> getAllLoggedDateStrings(String userId) =>
      _local.getAllLoggedDateStrings(userId);

  Future<void> seedFromRemote(String userId) async {
    final existing = await _local.getAllHabits(userId);
    if (existing.isNotEmpty) return;
    final remoteHabits = await _remote.fetchAllHabits(userId);
    for (final habit in remoteHabits) {
      await _local.putHabit(habit);
      final logs = await _remote.fetchLogsForHabit(habit.firestoreId);
      for (final log in logs) {
        await _local.putLog(log);
      }
    }
  }

  Future<void> _recalcStreak(String habitFirestoreId) async {
    final streak = await _local.calculateStreak(habitFirestoreId);
    final habit = await _local.getByFirestoreId(habitFirestoreId);
    if (habit != null) {
      final longest =
          habit.longestStreak > streak ? habit.longestStreak : streak;
      habit.currentStreak = streak;
      habit.longestStreak = longest;
      await _local.putHabit(habit);
      await _remote.syncHabit(habit);
    }
  }

  String _dateString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

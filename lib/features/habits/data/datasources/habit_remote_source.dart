import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart' as local;
import '../models/habit_log_model.dart' as local_log;

class HabitRemoteSource {
  final FirebaseFirestore _firestore;

  HabitRemoteSource(this._firestore);

  CollectionReference get _habits => _firestore.collection('habits');
  CollectionReference get _habitLogs => _firestore.collection('habit_logs');

  Future<List<local.Habit>> fetchAllHabits(String userId) async {
    final snap = await _habits.where('userId', isEqualTo: userId).get();
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _docToHabit(doc.id, data);
    }).toList();
  }

  Stream<List<local.Habit>> watchHabits(String userId) {
    return _habits.where('userId', isEqualTo: userId).snapshots().map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _docToHabit(doc.id, data);
          }).toList(),
        );
  }

  Future<void> syncHabit(local.Habit habit) async {
    await _habits.doc(habit.firestoreId).set({
      'userId': habit.userId,
      'name': habit.name,
      'colorHex': habit.colorHex,
      'frequency': habit.frequency,
      'customDays': habit.customDays,
      'currentStreak': habit.currentStreak,
      'longestStreak': habit.longestStreak,
      'createdAt': habit.createdAt,
      'archived': habit.archived,
    });
  }

  Future<void> deleteHabit(String firestoreId) async {
    await _habits.doc(firestoreId).delete();
    final logs =
        await _habitLogs.where('habitId', isEqualTo: firestoreId).get();
    final batch = _firestore.batch();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<local_log.HabitLog>> fetchLogsForHabit(
      String habitFirestoreId) async {
    final snap =
        await _habitLogs.where('habitId', isEqualTo: habitFirestoreId).get();
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _docToLog(doc.id, data);
    }).toList();
  }

  Future<void> syncLog(local_log.HabitLog log) async {
    await _habitLogs.doc(log.firestoreId).set({
      'habitId': log.habitFirestoreId,
      'dateString': log.dateString,
      'date': DateTime.now(),
      'status': log.status,
      'note': log.note,
      'progress': log.progress,
      'createdAt': log.createdAt,
    });
  }

  Future<void> deleteLog(String firestoreId) async {
    await _habitLogs.doc(firestoreId).delete();
  }

  local.Habit _docToHabit(String docId, Map<String, dynamic> data) {
    final habit = local.Habit()
      ..firestoreId = docId
      ..userId = data['userId'] as String? ?? ''
      ..name = data['name'] as String? ?? ''
      ..colorHex = data['colorHex'] as String? ?? '#075E54'
      ..frequency = data['frequency'] as String? ?? 'daily'
      ..customDays = List<String>.from(data['customDays'] ?? [])
      ..currentStreak = data['currentStreak'] as int? ?? 0
      ..longestStreak = data['longestStreak'] as int? ?? 0
      ..createdAt = (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now()
      ..archived = data['archived'] as bool? ?? false;
    return habit;
  }

  local_log.HabitLog _docToLog(String docId, Map<String, dynamic> data) {
    final log = local_log.HabitLog()
      ..firestoreId = docId
      ..habitFirestoreId = data['habitId'] as String? ?? ''
      ..dateString = data['dateString'] as String? ?? ''
      ..status = data['status'] as String? ?? 'completed'
      ..note = data['note'] as String? ?? ''
      ..progress = (data['progress'] as num?)?.toDouble() ?? 0.0
      ..createdAt = (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
    return log;
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/habit_repository.dart';
import '../data/models/habit_model.dart';
import '../data/models/habit_log_model.dart';

class HabitNotifier extends ChangeNotifier {
  final HabitRepository _repository;

  HabitNotifier(this._repository);

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;

  Map<String, bool> _loggedToday = {};
  Map<String, bool> get loggedToday => _loggedToday;

  Map<String, int> _streaks = {};
  Map<String, int> get streaks => _streaks;

  Set<String> _allLoggedDates = {};
  Set<String> get allLoggedDates => _allLoggedDates;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _habitSub;
  String? _currentUserId;

  Future<void> init(String userId) async {
    _currentUserId = userId;
    _loading = true;
    notifyListeners();

    await _repository.seedFromRemote(userId);

    _habitSub = _repository.watchHabits(userId).listen((habits) {
      _habits = habits;
      _loading = false;
      notifyListeners();
      _refreshLogData(userId);
    });
  }

  void _refreshLogData(String userId) {
    _repository.calculateAllStreaks(userId).then((streaks) {
      _streaks = streaks;
      notifyListeners();
    });
    _repository.getAllLoggedDateStrings(userId).then((dates) {
      _allLoggedDates = dates;
      notifyListeners();
    });
    _refreshTodayStatus(userId);
  }

  void _refreshTodayStatus(String userId) {
    final today = _todayString();
    final logged = <String, bool>{};
    for (final habit in _habits) {
      _repository.getLogsForDate(_parseDate(today)).then((logs) {
        logged[habit.firestoreId] = logs.any(
          (l) =>
              l.habitFirestoreId == habit.firestoreId &&
              l.status == 'completed',
        );
        _loggedToday = logged;
        notifyListeners();
      });
    }
  }

  Future<void> toggleHabit(Habit habit) async {
    final today = _todayString();
    final isLogged = _loggedToday[habit.firestoreId] ?? false;

    _loggedToday[habit.firestoreId] = !isLogged;
    notifyListeners();

    try {
      await _repository.toggleLog(habit.firestoreId, today);
      await _refreshForHabit(habit);
    } catch (e) {
      _loggedToday[habit.firestoreId] = isLogged;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> skipHabit(Habit habit) async {
    final today = _todayString();
    _loggedToday[habit.firestoreId] = false;
    notifyListeners();
    try {
      await _repository.skipHabit(habit.firestoreId, today);
      await _refreshForHabit(habit);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateNote(Habit habit, String note) async {
    final today = _todayString();
    await _repository.updateNote(habit.firestoreId, today, note);
  }

  Future<void> createHabit({
    required String userId,
    required String name,
    required String colorHex,
    required String frequency,
    List<String> customDays = const [],
  }) async {
    await _repository.createHabit(
      userId: userId,
      name: name,
      colorHex: colorHex,
      frequency: frequency,
      customDays: customDays,
    );
  }

  Future<void> updateHabit(
    String firestoreId, {
    String? name,
    String? colorHex,
    String? frequency,
    List<String>? customDays,
    bool? archived,
  }) async {
    await _repository.updateHabit(
      firestoreId,
      name: name,
      colorHex: colorHex,
      frequency: frequency,
      customDays: customDays,
      archived: archived,
    );
  }

  Future<void> deleteHabit(String firestoreId) async {
    await _repository.deleteHabit(firestoreId);
  }

  Future<void> archiveHabit(String firestoreId) async {
    await _repository.updateHabit(firestoreId, archived: true);
  }

  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    return _repository.getLogsForDate(date);
  }

  Future<void> _refreshForHabit(Habit habit) async {
    if (_currentUserId == null) return;
    final streak = await _repository.calculateStreak(habit.firestoreId);
    _streaks[habit.firestoreId] = streak;
    final dates = await _repository.getAllLoggedDateStrings(_currentUserId!);
    _allLoggedDates = dates;
    notifyListeners();
  }

  @override
  void dispose() {
    _habitSub?.cancel();
    super.dispose();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

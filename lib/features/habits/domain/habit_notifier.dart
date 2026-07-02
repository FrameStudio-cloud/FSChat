import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
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

  Map<String, double> _loggedTodayCount = {};
  Map<String, double> get loggedTodayCount => _loggedTodayCount;

  Map<String, int> _streaks = {};
  Map<String, int> get streaks => _streaks;

  Set<String> _allLoggedDates = {};
  Set<String> get allLoggedDates => _allLoggedDates;

  int get loggedTodayCountNum => _loggedToday.values.where((v) => v).length;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;
  set selectedCategory(String? val) {
    _selectedCategory = val;
    notifyListeners();
  }

  List<String> get categories {
    final cats = _habits.map((h) => h.category).toSet().toList()..sort();
    return cats;
  }

  List<Habit> get filteredHabits {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return _habits;
    }
    return _habits.where((h) => h.category == _selectedCategory).toList();
  }

  Map<String, List<Habit>> get groupedHabits {
    final map = <String, List<Habit>>{};
    for (final h in filteredHabits) {
      map.putIfAbsent(h.category, () => []).add(h);
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return {for (final e in sorted) e.key: e.value};
  }

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
    _repository.getLogsForDate(_parseDate(today)).then((logs) {
      final logged = <String, bool>{};
      final counts = <String, double>{};
      for (final h in _habits) {
        final habitLogs =
            logs.where((l) => l.habitFirestoreId == h.firestoreId);
        logged[h.firestoreId] = habitLogs.any((l) => l.status == 'completed');
        counts[h.firestoreId] = habitLogs.fold<double>(
            0, (sum, l) => sum + (l.status == 'completed' ? l.count : 0));
      }
      _loggedToday = logged;
      _loggedTodayCount = counts;
      notifyListeners();
    });
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

  Future<void> incrementCount(Habit habit) async {
    if (_currentUserId == null) return;
    final today = _todayString();
    final current = _loggedTodayCount[habit.firestoreId] ?? 0;
    final newCount = current + 1;
    if (newCount >= habit.targetCount) {
      if (!(_loggedToday[habit.firestoreId] ?? false)) {
        await _repository.toggleLog(habit.firestoreId, today, count: newCount);
        _loggedToday[habit.firestoreId] = true;
        _loggedTodayCount[habit.firestoreId] = newCount;
        notifyListeners();
        await _refreshForHabit(habit);
      } else {
        await _repository.updateLogCount(habit.firestoreId, today, newCount);
        _loggedTodayCount[habit.firestoreId] = newCount;
        notifyListeners();
      }
    } else {
      if (!(_loggedToday[habit.firestoreId] ?? false)) {
        await _repository.toggleLog(habit.firestoreId, today, count: newCount);
        _loggedToday[habit.firestoreId] = true;
        _loggedTodayCount[habit.firestoreId] = newCount;
        notifyListeners();
      } else {
        await _repository.updateLogCount(habit.firestoreId, today, newCount);
        _loggedTodayCount[habit.firestoreId] = newCount;
        notifyListeners();
      }
    }
  }

  Future<void> decrementCount(Habit habit) async {
    if (_currentUserId == null) return;
    final today = _todayString();
    final current = _loggedTodayCount[habit.firestoreId] ?? 0;
    final newCount = (current - 1).clamp(0, habit.targetCount).toDouble();
    if (newCount <= 0) {
      await _repository.toggleLog(habit.firestoreId, today);
      _loggedToday[habit.firestoreId] = false;
      _loggedTodayCount[habit.firestoreId] = 0;
      notifyListeners();
      await _refreshForHabit(habit);
    } else {
      await _repository.updateLogCount(habit.firestoreId, today, newCount);
      _loggedTodayCount[habit.firestoreId] = newCount;
      notifyListeners();
    }
  }

  Future<void> createHabit({
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
    final habitId = await _repository.createHabit(
      userId: userId,
      name: name,
      colorHex: colorHex,
      frequency: frequency,
      customDays: customDays,
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      category: category,
      habitType: habitType,
      targetCount: targetCount,
      unit: unit,
    );
    if (reminderEnabled) {
      await NotificationService.scheduleHabitReminder(
        habitId: habitId,
        habitName: name,
        hour: reminderHour,
        minute: reminderMinute,
      );
    }
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
    await _repository.updateHabit(
      firestoreId,
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
    final saved = await _repository.getByFirestoreId(firestoreId);
    if (saved != null) {
      if (saved.reminderEnabled) {
        await NotificationService.scheduleHabitReminder(
          habitId: firestoreId,
          habitName: saved.name,
          hour: saved.reminderHour,
          minute: saved.reminderMinute,
        );
      } else {
        await NotificationService.cancelHabitReminder(firestoreId);
      }
    }
  }

  Future<void> deleteHabit(String firestoreId) async {
    await NotificationService.cancelHabitReminder(firestoreId);
    await _repository.deleteHabit(firestoreId);
  }

  Future<void> archiveHabit(String firestoreId) async {
    await NotificationService.cancelHabitReminder(firestoreId);
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

    _checkStreakMilestone(habit, streak);
  }

  Future<void> _checkStreakMilestone(Habit habit, int streak) async {
    if (streak == 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'streak_milestone_${habit.firestoreId}';
    final lastNotified = prefs.getInt(key) ?? 0;
    final milestones = [3, 7, 14, 21, 30];
    for (final ms in milestones) {
      if (streak >= ms && lastNotified < ms) {
        await NotificationService.showStreakMilestone(
          habitName: habit.name,
          streak: ms,
          habitId: habit.firestoreId,
        );
        await prefs.setInt(key, ms);
        break;
      }
    }
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

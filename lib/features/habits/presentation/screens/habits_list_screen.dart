import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_notifier.dart';
import '../widgets/habit_tile.dart';
import '../widgets/streak_calendar.dart';
import '../widgets/daily_note_dialog.dart';
import 'habit_editor_screen.dart';

class HabitsListScreen extends StatefulWidget {
  const HabitsListScreen({super.key});

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends State<HabitsListScreen> {
  HabitNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null && _notifier == null) {
      final repo = HabitRepository(FirebaseFirestore.instance);
      _notifier = HabitNotifier(repo);
      _notifier!.init(uid);
    }
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to track habits'));
    }

    final notifier = _notifier;
    if (notifier == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        if (notifier.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = notifier.habits;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Habits'),
            centerTitle: false,
          ),
          body: habits.isEmpty
              ? _buildEmptyState(context)
              : _buildContent(context, notifier, habits, uid),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openEditor(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No habits yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          Text('Create your first habit to start tracking',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Habit'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HabitNotifier notifier,
    List<dynamic> habits,
    String uid,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todayLogged = habits
        .where(
          (h) => notifier.loggedToday[h.firestoreId] == true,
        )
        .length;
    final totalToday = habits.length;
    final bestStreak = notifier.streaks.values.isEmpty
        ? 0
        : notifier.streaks.values.reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: () => notifier.init(uid),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        children: [
          StreakCalendar(
            loggedDateStrings: notifier.allLoggedDates,
            currentStreak: bestStreak,
            totalLoggedDays: notifier.allLoggedDates.length,
            longestStreak: habits.isEmpty
                ? 0
                : habits
                    .map(
                      (h) => h.longestStreak as int,
                    )
                    .fold(0, (a, b) => a > b ? a : b),
            habits: habits.cast(),
            onDayTap: (date) => _showDayDetail(context, notifier, date),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Today',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '$todayLogged/$totalToday',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ...habits.map((habit) => HabitTile(
                habit: habit,
                isLoggedToday: notifier.loggedToday[habit.firestoreId] ?? false,
                streak: notifier.streaks[habit.firestoreId] ?? 0,
                onToggle: () {
                  HapticFeedback.lightImpact();
                  notifier.toggleHabit(habit);
                },
                onSkip: () {
                  HapticFeedback.mediumImpact();
                  notifier.skipHabit(habit);
                },
                onTap: () => _openEditor(context, habit: habit),
              )),
        ],
      ),
    );
  }

  void _showDayDetail(
      BuildContext context, HabitNotifier notifier, DateTime date) async {
    final logs = await notifier.getLogsForDate(date);
    if (logs.isEmpty) return;
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DailyNoteDialog(
        date: date,
        logs: logs,
        habits: notifier.habits,
        onSaveNote: (habitFirestoreId, note) async {
          final habit = notifier.habits.firstWhere(
            (h) => h.firestoreId == habitFirestoreId,
            orElse: () => notifier.habits.first,
          );
          await notifier.updateNote(habit, note);
        },
      ),
    );
  }

  void _openEditor(BuildContext context, {dynamic habit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitEditorScreen(existingHabit: habit),
      ),
    );
  }
}

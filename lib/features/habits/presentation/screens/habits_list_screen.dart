import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/models/habit_model.dart';
import '../../domain/habit_notifier.dart';
import '../widgets/habit_tile.dart';
import 'habit_editor_screen.dart';

class HabitsListScreen extends StatefulWidget {
  const HabitsListScreen({super.key});

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends State<HabitsListScreen>
    with SingleTickerProviderStateMixin {
  HabitNotifier? _notifier;
  late TabController _tabController;
  DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null && _notifier == null) {
      final repo = HabitNotifier(HabitRepository(FirebaseFirestore.instance));
      _notifier = repo;
      repo.init(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notifier?.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openEditor({Habit? existing}) async {
    if (_notifier == null) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitEditorScreen(
          existingHabit: existing,
          notifier: _notifier!,
          userId: uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = _notifier;
    if (notifier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habits')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        if (notifier.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habits')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final habits = notifier.habits;
        final grouped = notifier.groupedHabits;
        final categories = notifier.categories;
        final selectedCat = notifier.selectedCategory;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Habits'),
            centerTitle: false,
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _TodayTab(
                      notifier: notifier,
                      habits: habits,
                      grouped: grouped,
                      categories: categories,
                      selectedCat: selectedCat,
                      onSelectCategory: (c) => notifier.selectedCategory = c,
                      onOpenEditor: _openEditor,
                    ),
                    _CalendarTab(
                      notifier: notifier,
                      habits: habits,
                      calendarMonth: _calendarMonth,
                      onMonthChanged: (d) => setState(() => _calendarMonth = d),
                    ),
                    _InsightsTab(
                      notifier: notifier,
                      habits: habits,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withAlpha(150),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.checklist_rtl), text: 'Today'),
                    Tab(
                        icon: Icon(Icons.calendar_month_outlined),
                        text: 'Calendar'),
                    Tab(icon: Icon(Icons.insights_outlined), text: 'Insights'),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 56),
            child: FloatingActionButton(
              onPressed: () => _openEditor(),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}

// ── Today Tab ──
class _TodayTab extends StatelessWidget {
  final HabitNotifier notifier;
  final List<Habit> habits;
  final Map<String, List<Habit>> grouped;
  final List<String> categories;
  final String? selectedCat;
  final void Function(String?) onSelectCategory;
  final Future<void> Function({Habit? existing}) onOpenEditor;

  const _TodayTab({
    required this.notifier,
    required this.habits,
    required this.grouped,
    required this.categories,
    required this.selectedCat,
    required this.onSelectCategory,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final done = notifier.loggedTodayCountNum;
    final total = habits.length;
    final topStreak = notifier.streaks.values.isEmpty
        ? 0
        : notifier.streaks.values.reduce((a, b) => a > b ? a : b);

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rtl,
                size: 64, color: colorScheme.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 16),
            Text('No habits yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => onOpenEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Create Habit'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          _ProgressCard(
            done: done,
            total: total,
            topStreak: topStreak,
            onFire: notifier.streaks.values.where((s) => s >= 7).length,
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CatChip(
                    label: 'All',
                    active: selectedCat == null || selectedCat == 'All',
                    onTap: () => onSelectCategory(null),
                  ),
                  const SizedBox(width: 6),
                  ...categories.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _CatChip(
                          label: c,
                          active: selectedCat == c,
                          onTap: () => onSelectCategory(c),
                        ),
                      )),
                ],
              ),
            ),
          ],
          ...grouped.entries.map((entry) => _CategoryGroup(
                category: entry.key,
                habits: entry.value,
                notifier: notifier,
              )),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done, total, topStreak, onFire;
  const _ProgressCard(
      {required this.done,
      required this.total,
      required this.topStreak,
      required this.onFire});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(20),
            colorScheme.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$done',
                        style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('/ $total',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
                Text('done today',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          _StatMini(
              value: topStreak > 0 ? '\u{1F525} $topStreak' : '—',
              label: 'best streak'),
          const SizedBox(width: 16),
          _StatMini(value: '$onFire', label: 'on fire'),
          const SizedBox(width: 16),
          _StatMini(value: '$total', label: 'habits'),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String value, label;
  const _StatMini({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CatChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : null)),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<Habit> habits;
  final HabitNotifier notifier;
  const _CategoryGroup(
      {required this.category, required this.habits, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(category.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5)),
        ),
        ...habits.map((h) {
          final logged = notifier.loggedToday[h.firestoreId] ?? false;
          final count = notifier.loggedTodayCount[h.firestoreId] ?? 0;
          final streak = notifier.streaks[h.firestoreId] ?? 0;
          return HabitTile(
            habit: h,
            isLoggedToday: logged,
            todayCount: count,
            streak: streak,
            onToggle: () => notifier.toggleHabit(h),
            onIncrement: () => notifier.incrementCount(h),
            onDecrement: () => notifier.decrementCount(h),
            onSkip: () => notifier.skipHabit(h),
            onTap: () => onTapEdit(context, h),
            onArchive: () => notifier.archiveHabit(h.firestoreId),
          );
        }),
      ],
    );
  }

  void onTapEdit(BuildContext context, Habit h) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitEditorScreen(
          existingHabit: h,
          notifier: notifier,
          userId: h.userId,
        ),
      ),
    );
  }
}

// ── Calendar Tab ──
class _CalendarTab extends StatelessWidget {
  final HabitNotifier notifier;
  final List<Habit> habits;
  final DateTime calendarMonth;
  final void Function(DateTime) onMonthChanged;

  const _CalendarTab({
    required this.notifier,
    required this.habits,
    required this.calendarMonth,
    required this.onMonthChanged,
  });

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final daysInMonth =
        DateTime(calendarMonth.year, calendarMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(calendarMonth.year, calendarMonth.month, 1).weekday % 7;
    final today = DateTime.now();

    final allDates = notifier.allLoggedDates;
    final totalHabits = habits.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              _CalStat(
                value: allDates.isNotEmpty
                    ? '${(allDates.length / daysInMonth * 100).toStringAsFixed(0)}%'
                    : '—',
                label: 'this month',
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _CalStat(
                value: notifier.streaks.values.isEmpty
                    ? '—'
                    : '${notifier.streaks.values.reduce((a, b) => a > b ? a : b)}',
                label: 'best streak',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _CalStat(
                value: '${allDates.length}',
                label: 'logged days',
                color: colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => onMonthChanged(DateTime(
                          calendarMonth.year, calendarMonth.month - 1, 1)),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(calendarMonth),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => onMonthChanged(DateTime(
                          calendarMonth.year, calendarMonth.month + 1, 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: 'S M T W T F S'
                      .split(' ')
                      .map((d) => SizedBox(
                            width: 32,
                            child: Text(d,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    for (int i = 0; i < firstWeekday; i++)
                      const SizedBox(width: 40, height: 36),
                    for (int day = 1; day <= daysInMonth; day++) ...[
                      _buildDayCell(
                        day: day,
                        today: today,
                        calendarMonth: calendarMonth,
                        allDates: allDates,
                        totalHabits: totalHabits,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Legend
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF25D366), label: 'completed'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: colorScheme.surfaceContainerHighest, label: 'none'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime today,
    required DateTime calendarMonth,
    required Set<String> allDates,
    required int totalHabits,
    required ColorScheme colorScheme,
  }) {
    final date = DateTime(calendarMonth.year, calendarMonth.month, day);
    final key = _dateKey(date);
    final hasLog = allDates.contains(key);
    final isToday = day == today.day &&
        calendarMonth.month == today.month &&
        calendarMonth.year == today.year;

    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasLog ? const Color(0xFF25D366).withAlpha(35) : null,
        border:
            isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                )),
            if (hasLog)
              const Positioned(
                bottom: -2,
                child: Text('●',
                    style: TextStyle(fontSize: 8, color: Color(0xFF25D366))),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _CalStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ── Insights Tab ──
class _InsightsTab extends StatelessWidget {
  final HabitNotifier notifier;
  final List<Habit> habits;
  const _InsightsTab({required this.notifier, required this.habits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (habits.isEmpty) {
      return Center(
        child: Icon(Icons.insights_outlined,
            size: 64, color: colorScheme.onSurfaceVariant.withAlpha(80)),
      );
    }

    final allDates = notifier.allLoggedDates;
    final weekDays =
        List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        children: [
          _buildWeeklyTrend(theme, colorScheme, weekDays, allDates, habits),
          const SizedBox(height: 16),
          _buildBestStreaks(theme, colorScheme),
          const SizedBox(height: 16),
          _buildCategoryBreakdown(theme, colorScheme, allDates, weekDays),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend(ThemeData theme, ColorScheme colorScheme,
      List<DateTime> weekDays, Set<String> allDates, List<Habit> habits) {
    final dayScores = weekDays.map((day) {
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (allDates.contains(key)) {
        return 1.0;
      }
      return 0.0;
    }).toList();

    final weekAvg = dayScores.isEmpty
        ? 0.0
        : dayScores.reduce((a, b) => a + b) / dayScores.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Trend',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('${(weekAvg * 100).toStringAsFixed(0)}% avg',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final score = dayScores[i];
                final day = weekDays[i];
                final pct = habits.isEmpty ? 0.0 : score;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(pct * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                          height: (pct * 80).clamp(4, 80),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                pct > 0.5
                                    ? const Color(0xFF25D366)
                                    : const Color(0xFFFF9800),
                                pct > 0.5
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFB74D),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('E').format(day).substring(0, 2),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestStreaks(ThemeData theme, ColorScheme colorScheme) {
    final streaks = notifier.streaks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = streaks.take(4).toList();
    if (top.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Best Streaks',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...top.map((entry) {
            final habit =
                habits.where((h) => h.firestoreId == entry.key).firstOrNull;
            if (habit == null) return const SizedBox();
            final habitColor =
                Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: habitColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        entry.value >= 7 ? '\u{1F525}' : '\u{1F4AA}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text('\u{1F525} ${entry.value} day streak',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme, ColorScheme colorScheme,
      Set<String> allDates, List<DateTime> weekDays) {
    final categories = notifier.categories;
    if (categories.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Category',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...categories.map((cat) {
            final catHabits = habits.where((h) => h.category == cat).toList();
            if (catHabits.isEmpty) return const SizedBox();
            final done = catHabits.where((h) {
              return allDates.contains(
                  '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}');
            }).length;
            final pct = catHabits.isEmpty ? 0.0 : done / catHabits.length;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(cat,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: colorScheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text('${(pct * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

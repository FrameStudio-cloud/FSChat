import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/mood_entry.dart';
import 'mood_editor_screen.dart';
import 'mood_insights_screen.dart';

const _lowMoodEmojis = {'😔', '😢', '😠', '😰', '🤒'};

const _moodScores = {
  '😁': 10,
  '😊': 8,
  '😐': 6,
  '😔': 4,
  '😢': 3,
  '😠': 2,
  '😰': 3,
  '💪': 9,
  '🧘': 9,
  '🤒': 2,
};

class MoodListScreen extends StatefulWidget {
  const MoodListScreen({super.key});

  @override
  State<MoodListScreen> createState() => _MoodListScreenState();
}

class _MoodListScreenState extends State<MoodListScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabController;
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, MoodEntry> _moodMap = {};
  bool _moodReminderEnabled = false;
  int _moodReminderHour = 20;
  int _moodReminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReminderPrefs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moodReminderEnabled = prefs.getBool('mood_reminder_enabled') ?? false;
      _moodReminderHour = prefs.getInt('mood_reminder_hour') ?? 20;
      _moodReminderMinute = prefs.getInt('mood_reminder_minute') ?? 0;
    });
  }

  Future<void> _saveReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mood_reminder_enabled', _moodReminderEnabled);
    await prefs.setInt('mood_reminder_hour', _moodReminderHour);
    await prefs.setInt('mood_reminder_minute', _moodReminderMinute);
    if (_moodReminderEnabled) {
      await NotificationService.scheduleMoodReminder(
        hour: _moodReminderHour,
        minute: _moodReminderMinute,
      );
    } else {
      await NotificationService.cancelMoodReminder();
    }
  }

  void _checkLowMoodPattern(List<MoodEntry> moods) async {
    final sorted = List<MoodEntry>.from(moods)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.length < 3) return;
    final lastThree = sorted.take(3).toList();
    final allLow = lastThree.every((m) => _lowMoodEmojis.contains(m.emoji));
    if (!allLow) return;
    final prefs = await SharedPreferences.getInstance();
    final lastAlerted = prefs.getString('mood_pattern_alerted');
    if (lastAlerted != null) {
      final lastDate = DateTime.parse(lastAlerted);
      if (DateTime.now().difference(lastDate).inDays < 7) return;
    }
    await NotificationService.showMoodPatternAlert();
    await prefs.setString(
        'mood_pattern_alerted', DateTime.now().toIso8601String());
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double _averageScore(List<MoodEntry> moods) {
    if (moods.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (final m in moods) {
      if (m.date.month == _currentMonth.month &&
          m.date.year == _currentMonth.year) {
        total += _moodScores[m.emoji] ?? 5;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  int _entriesThisMonth(List<MoodEntry> moods) {
    return moods
        .where((m) =>
            m.date.month == _currentMonth.month &&
            m.date.year == _currentMonth.year)
        .length;
  }

  int _currentStreak(List<MoodEntry> moods) {
    final sorted = List<MoodEntry>.from(moods)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.isEmpty) return 0;
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < sorted.length; i++) {
      final expected = today.subtract(Duration(days: i));
      if (sorted[i].date.day == expected.day &&
          sorted[i].date.month == expected.month &&
          sorted[i].date.year == expected.year) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _moodReminderEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
            ),
            onPressed: _showReminderSettings,
          ),
        ],
      ),
      body: StreamBuilder<List<MoodEntry>>(
        stream: _db.userMoodsStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final moods = snapshot.data!;
          _moodMap = {};
          for (final m in moods) {
            _moodMap[_dateKey(m.date)] = m;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkLowMoodPattern(moods);
          });

          final todayKey = _dateKey(DateTime.now());
          final todayMood = _moodMap[todayKey];
          final avg = _averageScore(moods);
          final streak = _currentStreak(moods);
          final entriesCount = _entriesThisMonth(moods);

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CalendarTab(
                      currentMonth: _currentMonth,
                      moodMap: _moodMap,
                      todayMood: todayMood,
                      avg: avg,
                      streak: streak,
                      entriesCount: entriesCount,
                      onMonthChanged: (d) => setState(() => _currentMonth = d),
                      onDayTap: (date) => _openEditor(context, date: date),
                      onFabTap: () => _openEditor(context),
                    ),
                    MoodInsightsScreen(moods: moods),
                    _StreaksTab(
                      streak: streak,
                      moods: moods,
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
                    Tab(
                        icon: Icon(Icons.calendar_month_outlined),
                        text: 'Calendar'),
                    Tab(icon: Icon(Icons.insights_outlined), text: 'Insights'),
                    Tab(
                        icon: Icon(Icons.local_fire_department_outlined),
                        text: 'Streaks'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton(
          onPressed: () => _openEditor(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, {DateTime? date}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodEditorScreen(initialDate: date ?? DateTime.now()),
      ),
    );
  }

  void _showReminderSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Mood Reminder',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Get a gentle nudge to check in each day.',
                  style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable reminder'),
                value: _moodReminderEnabled,
                onChanged: (val) {
                  setSheetState(() => _moodReminderEnabled = val);
                },
              ),
              if (_moodReminderEnabled) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(
                          hour: _moodReminderHour,
                          minute: _moodReminderMinute,
                        ),
                      );
                      if (time != null) {
                        setSheetState(() {
                          _moodReminderHour = time.hour;
                          _moodReminderMinute = time.minute;
                        });
                      }
                    },
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(
                      '${_moodReminderHour.toString().padLeft(2, '0')}:${_moodReminderMinute.toString().padLeft(2, '0')}',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _saveReminderPrefs();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Calendar Tab ──
class _CalendarTab extends StatelessWidget {
  final DateTime currentMonth;
  final Map<String, MoodEntry> moodMap;
  final MoodEntry? todayMood;
  final double avg;
  final int streak;
  final int entriesCount;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDayTap;
  final VoidCallback onFabTap;

  const _CalendarTab({
    required this.currentMonth,
    required this.moodMap,
    required this.todayMood,
    required this.avg,
    required this.streak,
    required this.entriesCount,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // Today's Mood
          if (todayMood != null)
            _TodayMoodCard(
                mood: todayMood!, theme: theme, colorScheme: colorScheme)
          else
            _EmptyTodayCard(theme: theme, onTap: onFabTap),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatCard(
                  value: avg > 0 ? avg.toStringAsFixed(1) : '—',
                  label: 'Avg mood',
                  color: Color.lerp(
                          Colors.red, Colors.green, (avg / 10).clamp(0, 1)) ??
                      Colors.grey,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  value: streak > 0 ? '🔥 $streak' : '—',
                  label: 'Streak',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  value: '$entriesCount',
                  label: 'Entries',
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Calendar
          _CalendarCard(
            currentMonth: currentMonth,
            moodMap: moodMap,
            theme: theme,
            colorScheme: colorScheme,
            onMonthChanged: onMonthChanged,
            onDayTap: onDayTap,
          ),

          // Recent
          _RecentSection(moodMap: moodMap, theme: theme, onDayTap: onDayTap),
        ],
      ),
    );
  }
}

class _TodayMoodCard extends StatelessWidget {
  final MoodEntry mood;
  final ThemeData theme;
  final ColorScheme colorScheme;
  const _TodayMoodCard(
      {required this.mood, required this.theme, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final option = MoodEntry.moods.firstWhere(
      (m) => m.emoji == mood.emoji,
      orElse: () => MoodEntry.moods[2],
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(option.color).withAlpha(25),
            colorScheme.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(option.color).withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(option.color).withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
                child: Text(mood.emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Color(option.color),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                Text(mood.label,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (mood.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(mood.note,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTodayCard extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onTap;
  const _EmptyTodayCard({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: theme.colorScheme.surfaceContainerHighest),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mood_rounded,
                    size: 28, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text('How are you feeling?',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
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
                    fontSize: 20, fontWeight: FontWeight.w700, color: color)),
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

class _CalendarCard extends StatelessWidget {
  final DateTime currentMonth;
  final Map<String, MoodEntry> moodMap;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDayTap;

  const _CalendarCard({
    required this.currentMonth,
    required this.moodMap,
    required this.theme,
    required this.colorScheme,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday % 7;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                onPressed: () => onMonthChanged(
                    DateTime(currentMonth.year, currentMonth.month - 1, 1)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(currentMonth),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(
                    DateTime(currentMonth.year, currentMonth.month + 1, 1)),
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
                GestureDetector(
                  onTap: () => onDayTap(
                      DateTime(currentMonth.year, currentMonth.month, day)),
                  child: _buildDayCell(day, today, context),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, DateTime today, BuildContext context) {
    final date = DateTime(currentMonth.year, currentMonth.month, day);
    final key = _dateKey(date);
    final entry = moodMap[key];
    final isToday = day == today.day &&
        currentMonth.month == today.month &&
        currentMonth.year == today.year;

    Color? bgColor;
    if (entry != null) {
      final option = MoodEntry.moods.firstWhere(
        (m) => m.emoji == entry.emoji,
        orElse: () => MoodEntry.moods[2],
      );
      bgColor = Color(option.color).withAlpha(35);
    }

    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: entry != null ? Colors.white : null,
              ),
            ),
            if (entry != null)
              Positioned(
                bottom: -2,
                child: Text(entry.emoji, style: const TextStyle(fontSize: 8)),
              ),
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _RecentSection extends StatelessWidget {
  final Map<String, MoodEntry> moodMap;
  final ThemeData theme;
  final void Function(DateTime) onDayTap;
  const _RecentSection(
      {required this.moodMap, required this.theme, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final entries = moodMap.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = entries.take(7).toList();
    if (recent.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Recent Entries',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        ...recent.map((m) => InkWell(
              onTap: () => onDayTap(m.date),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.label,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          Text(DateFormat('MMM d, yyyy').format(m.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (m.note.isNotEmpty)
                      Icon(Icons.notes_rounded,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ── Streaks Tab ──
class _StreaksTab extends StatelessWidget {
  final int streak;
  final List<MoodEntry> moods;
  const _StreaksTab({required this.streak, required this.moods});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (moods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_outlined,
                size: 64, color: colorScheme.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 16),
            Text('No entries yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Start logging to build a streak!',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8A50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('🔥', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text('$streak',
                    style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                Text('day streak',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.white.withAlpha(200))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Last 7 days',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final date = DateTime.now().subtract(Duration(days: 6 - i));
              final key =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final entry = moods.where((m) {
                return m.date.day == date.day &&
                    m.date.month == date.month &&
                    m.date.year == date.year;
              }).isNotEmpty;
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: entry
                          ? Icon(Icons.check, color: Colors.white, size: 20)
                          : Icon(Icons.remove,
                              color: colorScheme.onSurfaceVariant, size: 20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('E').format(date).substring(0, 2),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

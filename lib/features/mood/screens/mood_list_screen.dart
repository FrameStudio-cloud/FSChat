import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/mood_entry.dart';
import 'mood_editor_screen.dart';

class MoodListScreen extends StatefulWidget {
  const MoodListScreen({super.key});

  @override
  State<MoodListScreen> createState() => _MoodListScreenState();
}

class _MoodListScreenState extends State<MoodListScreen> {
  final _db = DatabaseService();
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, MoodEntry> _moodMap = {};

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        centerTitle: false,
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
            final key = _dateKey(m.date);
            _moodMap[key] = m;
          }

          final todayKey = _dateKey(DateTime.now());
          final todayMood = _moodMap[todayKey];

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildMonthHeader(context),
              _buildCalendarGrid(context, uid),
              const SizedBox(height: 16),
              if (todayMood != null) _buildTodayMood(context, todayMood),
              _buildRecentList(context, moods),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: Icon(
          _moodMap[_dateKey(DateTime.now())] != null
              ? Icons.edit_rounded
              : Icons.mood_rounded,
        ),
        label: Text(
          _moodMap[_dateKey(DateTime.now())] != null
              ? 'Update Mood'
              : 'How are you?',
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _currentMonth =
                DateTime(_currentMonth.year, _currentMonth.month - 1, 1)),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _currentMonth =
                DateTime(_currentMonth.year, _currentMonth.month + 1, 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, String uid) {
    final theme = Theme.of(context);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
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
                const SizedBox(width: 32 + 8, height: 36),
              for (int day = 1; day <= daysInMonth; day++) ...[
                GestureDetector(
                  onTap: () {
                    final date =
                        DateTime(_currentMonth.year, _currentMonth.month, day);
                    _openEditor(context, date: date);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getMoodColor(day),
                      border: day == today.day &&
                              _currentMonth.month == today.month &&
                              _currentMonth.year == today.year
                          ? Border.all(
                              color: theme.colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getMoodColor(day) != null
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color? _getMoodColor(int day) {
    final key =
        _dateKey(DateTime(_currentMonth.year, _currentMonth.month, day));
    final entry = _moodMap[key];
    if (entry == null) return null;
    final option = MoodEntry.moods.firstWhere(
      (m) => m.emoji == entry.emoji,
      orElse: () => MoodEntry.moods[2],
    );
    return Color(option.color);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _buildTodayMood(BuildContext context, MoodEntry mood) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: theme.textTheme.labelSmall),
                Text(mood.label,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (mood.note.isNotEmpty)
                  Text(mood.note,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(BuildContext context, List<MoodEntry> moods) {
    final theme = Theme.of(context);
    final recent = moods.take(7).toList();
    if (recent.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Recent',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        ...recent.map((m) => ListTile(
              leading: Text(m.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(m.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text(
                DateFormat('MMM d, yyyy').format(m.date),
                style: theme.textTheme.bodySmall,
              ),
              trailing: m.note.isNotEmpty
                  ? Icon(Icons.notes_rounded,
                      color: theme.colorScheme.onSurfaceVariant)
                  : null,
            )),
      ],
    );
  }

  void _openEditor(BuildContext context, {DateTime? date}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodEditorScreen(initialDate: date ?? DateTime.now()),
      ),
    );
  }
}

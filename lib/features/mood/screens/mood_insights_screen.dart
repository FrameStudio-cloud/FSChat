import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

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

class MoodInsightsScreen extends StatelessWidget {
  final List<MoodEntry> moods;
  const MoodInsightsScreen({super.key, required this.moods});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (moods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined,
                size: 64, color: colorScheme.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 16),
            Text('No data yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeeklyTrend(theme: theme, colorScheme: colorScheme, moods: moods),
          const SizedBox(height: 20),
          _MoodDistribution(
              theme: theme, colorScheme: colorScheme, moods: moods),
          const SizedBox(height: 20),
          _CommonTags(theme: theme, colorScheme: colorScheme, moods: moods),
        ],
      ),
    );
  }
}

class _WeeklyTrend extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final List<MoodEntry> moods;
  const _WeeklyTrend(
      {required this.theme, required this.colorScheme, required this.moods});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekDays = List.generate(7, (i) {
      return today.subtract(Duration(days: 6 - i));
    });

    final dayScores = weekDays.map((day) {
      final match = moods.where((m) =>
          m.date.day == day.day &&
          m.date.month == day.month &&
          m.date.year == day.year);
      if (match.isEmpty) return 0.0;
      final avg =
          match.map((m) => _moodScores[m.emoji] ?? 5).reduce((a, b) => a + b) /
              match.length;
      return avg;
    }).toList();

    final maxScore = dayScores.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Trend',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final score = dayScores[i];
                final day = weekDays[i];
                final height = maxScore > 0 ? (score / maxScore) * 80 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (score > 0)
                          Text(score.toStringAsFixed(0),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                          height: height.clamp(4, 80),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [
                                Color.lerp(Colors.red, Colors.green,
                                        (score / 10).clamp(0, 1)) ??
                                    Colors.grey,
                                Color.lerp(Colors.red, Colors.green,
                                        (score / 10).clamp(0, 1)) ??
                                    Colors.grey,
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
}

class _MoodDistribution extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final List<MoodEntry> moods;
  const _MoodDistribution(
      {required this.theme, required this.colorScheme, required this.moods});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final m in moods) {
      counts[m.emoji] = (counts[m.emoji] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood Distribution',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...sorted.take(5).map((entry) {
            final option = MoodEntry.moods.firstWhere(
              (m) => m.emoji == entry.key,
              orElse: () => MoodEntry.moods[2],
            );
            final pct = (entry.value / moods.length * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(option.label,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            Text('$pct%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / moods.length,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: Color(option.color),
                            minHeight: 6,
                          ),
                        ),
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
}

class _CommonTags extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final List<MoodEntry> moods;
  const _CommonTags(
      {required this.theme, required this.colorScheme, required this.moods});

  @override
  Widget build(BuildContext context) {
    final tagCounts = <String, int>{};
    for (final m in moods) {
      for (final tag in m.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    if (tagCounts.isEmpty) return const SizedBox();

    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common Tags',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorted.map((entry) {
              return Chip(
                label: Text('${entry.key} (${entry.value})',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
                backgroundColor: colorScheme.primary.withAlpha(20),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

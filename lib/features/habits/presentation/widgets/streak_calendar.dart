import 'package:flutter/material.dart';
import '../../data/models/habit_model.dart';
import '../widgets/heatmap_painter.dart';

class StreakCalendar extends StatelessWidget {
  final Set<String> loggedDateStrings;
  final int currentStreak;
  final int totalLoggedDays;
  final int longestStreak;
  final List<Habit> habits;
  final void Function(DateTime date)? onDayTap;

  const StreakCalendar({
    super.key,
    required this.loggedDateStrings,
    required this.currentStreak,
    required this.totalLoggedDays,
    this.longestStreak = 0,
    this.habits = const [],
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Heatmap',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _StatChip(
                  icon: '\u{1F4AA}',
                  value: '$currentStreak',
                  label: 'streak',
                  color: colorScheme.primary),
              const SizedBox(width: 8),
              _StatChip(
                  icon: '\u{1F3C6}',
                  value: '$longestStreak',
                  label: 'best',
                  color: Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width - 64, 140),
              painter: HeatmapPainter(
                loggedDateStrings: loggedDateStrings,
                activeColor: activeColor,
                emptyColor: colorScheme.onSurface.withAlpha(18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$totalLoggedDays days logged',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Less',
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  _dot(emptyColor: colorScheme.onSurface.withAlpha(18)),
                  _dot(emptyColor: activeColor.withAlpha(60)),
                  _dot(emptyColor: activeColor.withAlpha(120)),
                  _dot(emptyColor: activeColor),
                  const SizedBox(width: 4),
                  Text('More',
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot({required Color emptyColor}) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        color: emptyColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w600, color: color),
          ),
          Text(
            ' $label',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}

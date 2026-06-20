import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/habit_model.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final bool isLoggedToday;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onSkip;
  final VoidCallback onTap;

  const HabitTile({
    super.key,
    required this.habit,
    required this.isLoggedToday,
    required this.streak,
    required this.onToggle,
    required this.onSkip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final habitColor =
        Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        onLongPress: () => _showMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLoggedToday ? habitColor : Colors.transparent,
                    border: Border.all(
                      color: isLoggedToday ? habitColor : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isLoggedToday
                      ? Icon(Icons.check,
                          size: 16, color: colorScheme.onPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 4,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: habitColor.withAlpha(180),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      habit.frequency == 'daily' ? 'Daily' : habit.frequency,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: streak >= 7
                        ? Colors.orange.withAlpha(30)
                        : habitColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        streak >= 7 ? '\u{1F525}' : '\u{1F4AA}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              streak >= 7 ? Colors.orange.shade700 : habitColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('Skip today'),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                onSkip();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmArchive(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive habit?'),
        content: const Text('You can restore it later from settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              onSkip(); // temp — will be replaced with archive
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}

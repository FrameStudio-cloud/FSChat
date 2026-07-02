import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/habit_model.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final bool isLoggedToday;
  final double todayCount;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onSkip;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const HabitTile({
    super.key,
    required this.habit,
    required this.isLoggedToday,
    this.todayCount = 0,
    required this.streak,
    required this.onToggle,
    this.onIncrement,
    this.onDecrement,
    required this.onSkip,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final habitColor =
        Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));

    final isQuantifiable = habit.habitType == 'quantifiable';
    final showCount = isQuantifiable && isLoggedToday;
    final targetStr = isQuantifiable
        ? '${todayCount.isFinite ? todayCount.toInt() : 0}/${habit.targetCount.isFinite ? habit.targetCount.toInt() : 1} ${habit.unit}'
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLoggedToday
              ? habitColor.withAlpha(60)
              : colorScheme.surfaceContainerHighest,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        onLongPress: () => _showMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Check circle
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
              // Color bar
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: habitColor.withAlpha(180),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      targetStr ??
                          (habit.frequency == 'daily'
                              ? 'Daily'
                              : habit.frequency),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantifiable +/- buttons
              if (isQuantifiable) ...[
                _MiniButton(
                  icon: Icons.remove,
                  onTap: onDecrement,
                  color: habitColor,
                ),
                const SizedBox(width: 4),
                _MiniButton(
                  icon: Icons.add,
                  onTap: onIncrement,
                  color: habitColor,
                ),
                const SizedBox(width: 8),
              ],
              // Streak badge
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
            _MenuTile(
              icon: Icons.skip_next,
              label: 'Skip today',
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                onSkip();
              },
            ),
            _MenuTile(
              icon: Icons.edit,
              label: 'Edit',
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            _MenuTile(
              icon: Icons.archive_outlined,
              label: 'Archive',
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
              onArchive();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _MiniButton(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import '../../habits/presentation/screens/habits_list_screen.dart';
import '../../mood/screens/mood_list_screen.dart';
import '../../challenges/screens/challenges_list_screen.dart';
import '../../reading_list/presentation/screens/reading_list_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tools = [
      _ToolItem(
        icon: Icons.check_circle_rounded,
        label: 'Habits',
        subtitle: 'Track daily habits & streaks',
        color: colorScheme.primary,
        screen: const HabitsListScreen(),
      ),
      _ToolItem(
        icon: Icons.mood_rounded,
        label: 'Mood Tracker',
        subtitle: 'Log your daily mood',
        color: Colors.amber.shade600,
        screen: const MoodListScreen(),
      ),
      _ToolItem(
        icon: Icons.emoji_events_rounded,
        label: 'Challenges',
        subtitle: 'Challenges with friends',
        color: Colors.deepOrange.shade400,
        screen: const ChallengesListScreen(),
      ),
      _ToolItem(
        icon: Icons.menu_book_rounded,
        label: 'Reading List',
        subtitle: 'Save articles & books',
        color: Colors.teal.shade500,
        screen: const ReadingListScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Tools',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  return Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => tool.screen!),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: tool.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                tool.icon,
                                color: tool.color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tool.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tool.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Widget screen;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.screen,
  });
}

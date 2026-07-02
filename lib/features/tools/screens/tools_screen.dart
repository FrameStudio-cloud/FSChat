import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';
import '../../habits/data/repositories/habit_repository.dart';
import '../../habits/domain/habit_notifier.dart';
import '../../mood/models/mood_entry.dart';
import '../../challenges/models/challenge_model.dart';
import '../../reading_list/data/datasources/book_local_source.dart';
import '../../reading_list/domain/book_notifier.dart';
import '../../../core/services/database_service.dart';
import '../models/project.dart';
import '../../speech/domain/speech_notifier.dart';
import '../../speech/screens/speech_practice_screen.dart';
import 'project_detail_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _db = DatabaseService();
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _uid = context.read<AuthProvider>().user?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'All Tools',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HabitsCard(uid: _uid),
              _MoodCard(uid: _uid, db: _db),
              _ChallengesCard(uid: _uid, db: _db),
              _ReadingCard(uid: _uid),
              _SpeechCard(uid: _uid),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Icon(Icons.widgets_rounded,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'My Projects',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: myProjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final project = myProjects[index];
                return _ProjectCard(
                  project: project,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(project: project),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String stat;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.stat,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                stat,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                label,
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
  }
}

class _HabitsCard extends StatefulWidget {
  final String? uid;
  const _HabitsCard({this.uid});

  @override
  State<_HabitsCard> createState() => _HabitsCardState();
}

class _HabitsCardState extends State<_HabitsCard> {
  HabitNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.uid != null && _notifier == null) {
      final repo = HabitRepository(FirebaseFirestore.instance);
      _notifier = HabitNotifier(repo);
      _notifier!.init(widget.uid!);
    }
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notifier == null) {
      return _StatCard(
        icon: Icons.check_circle_rounded,
        label: 'Track daily habits & streaks',
        stat: '...',
        color: Theme.of(context).colorScheme.primary,
        onTap: () => Navigator.pushNamed(context, '/habits'),
      );
    }
    return ListenableBuilder(
      listenable: _notifier!,
      builder: (context, _) {
        final n = _notifier!;
        String stat;
        if (n.loading) {
          stat = '...';
        } else {
          final completed = n.habits
              .where((h) => n.loggedToday[h.firestoreId] == true)
              .length;
          final bestStreak = n.streaks.values.isEmpty
              ? 0
              : n.streaks.values.reduce((a, b) => a > b ? a : b);
          stat = '${n.habits.length} habits';
          if (bestStreak > 0) stat += ' \u2022 $bestStreak day streak';
          if (completed > 0) stat = '$completed done \u2022 $stat';
        }
        return _StatCard(
          icon: Icons.check_circle_rounded,
          label: 'Track daily habits & streaks',
          stat: stat,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => Navigator.pushNamed(context, '/habits'),
        );
      },
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String? uid;
  final DatabaseService db;
  const _MoodCard({this.uid, required this.db});

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return _StatCard(
        icon: Icons.mood_rounded,
        label: 'Log your daily mood',
        stat: 'Sign in to track',
        color: Colors.amber.shade600,
        onTap: () => Navigator.pushNamed(context, '/mood'),
      );
    }
    return StreamBuilder<List<MoodEntry>>(
      stream: db.userMoodsStream(uid!),
      builder: (context, snapshot) {
        String stat;
        if (!snapshot.hasData) {
          stat = '...';
        } else {
          final moods = snapshot.data!;
          final today = DateTime.now();
          final todayKey =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final todayMood = moods.cast<MoodEntry?>().firstWhere(
                (m) =>
                    m != null &&
                    '${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}' ==
                        todayKey,
                orElse: () => null,
              );
          if (todayMood != null) {
            stat = '${todayMood.emoji} ${todayMood.label}';
          } else {
            stat = 'Not logged today';
          }
        }
        return _StatCard(
          icon: Icons.mood_rounded,
          label: 'Log your daily mood',
          stat: stat,
          color: Colors.amber.shade600,
          onTap: () => Navigator.pushNamed(context, '/mood'),
        );
      },
    );
  }
}

class _ChallengesCard extends StatelessWidget {
  final String? uid;
  final DatabaseService db;
  const _ChallengesCard({this.uid, required this.db});

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return _StatCard(
        icon: Icons.emoji_events_rounded,
        label: 'Challenges with friends',
        stat: 'Sign in to view',
        color: Colors.deepOrange.shade400,
        onTap: () => Navigator.pushNamed(context, '/challenges'),
      );
    }
    return StreamBuilder<List<Challenge>>(
      stream: db.userChallengesStream(uid!),
      builder: (context, snapshot) {
        String stat;
        if (!snapshot.hasData) {
          stat = '...';
        } else {
          final challenges = snapshot.data!;
          final active = challenges.length;
          if (active == 0) {
            stat = 'No active challenges';
          } else {
            stat = '$active active';
          }
        }
        return _StatCard(
          icon: Icons.emoji_events_rounded,
          label: 'Challenges with friends',
          stat: stat,
          color: Colors.deepOrange.shade400,
          onTap: () => Navigator.pushNamed(context, '/challenges'),
        );
      },
    );
  }
}

class _ReadingCard extends StatefulWidget {
  final String? uid;
  const _ReadingCard({this.uid});

  @override
  State<_ReadingCard> createState() => _ReadingCardState();
}

class _ReadingCardState extends State<_ReadingCard> {
  BookNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.uid != null && _notifier == null) {
      _notifier = BookNotifier(BookLocalSource());
      _notifier!.init(widget.uid!);
    }
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notifier == null) {
      return _StatCard(
        icon: Icons.menu_book_rounded,
        label: 'Save articles & books',
        stat: '...',
        color: Colors.teal.shade500,
        onTap: () => Navigator.pushNamed(context, '/reading'),
      );
    }
    return ListenableBuilder(
      listenable: _notifier!,
      builder: (context, _) {
        final n = _notifier!;
        String stat;
        if (n.loading) {
          stat = '...';
        } else {
          final total = n.books.length;
          final reading = n.reading.length;
          if (total == 0) {
            stat = 'No books yet';
          } else if (reading > 0) {
            stat = '$total books \u2022 $reading reading';
          } else {
            stat = '$total books';
          }
        }
        return _StatCard(
          icon: Icons.menu_book_rounded,
          label: 'Save articles & books',
          stat: stat,
          color: Colors.teal.shade500,
          onTap: () => Navigator.pushNamed(context, '/reading'),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 180,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: project.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(project.icon, color: project.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  project.title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  project.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        size: 14, color: project.color),
                    const SizedBox(width: 4),
                    Text(
                      'Learn more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: project.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechCard extends StatefulWidget {
  final String? uid;
  const _SpeechCard({this.uid});

  @override
  State<_SpeechCard> createState() => _SpeechCardState();
}

class _SpeechCardState extends State<_SpeechCard> {
  SpeechNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notifier == null && widget.uid != null) {
      _notifier = SpeechNotifier();
      _notifier!.init(widget.uid!);
    }
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _notifier!,
      builder: (context, _) {
        final n = _notifier!;
        final sessions = n.loading ? 0 : n.totalSessions;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SpeechPracticeScreen(),
            ),
          ),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.record_voice_over_rounded,
                        color: Color(0xFFE65100), size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.loading ? '...' : '$sessions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE65100),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Practice',
                    style: TextStyle(
                        color: Color(0xFFE65100),
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

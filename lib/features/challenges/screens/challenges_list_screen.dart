import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';
import '../models/challenge_progress.dart';
import 'challenge_detail_screen.dart';
import 'challenge_editor_screen.dart';

const _templateEmojis = {
  '30-Day Fitness': '🏃',
  '7-Day Gratitude': '📖',
  'Drink Water Daily': '💧',
  'Mindfulness': '🧘',
  'No Social Media': '📵',
  'Daily Writing': '✍️',
};

String _emojiFor(String title) {
  for (final e in _templateEmojis.entries) {
    if (title
        .toLowerCase()
        .contains(e.key.toLowerCase().split(' ').first.toLowerCase())) {
      return e.value;
    }
  }
  return '🏆';
}

class ChallengesListScreen extends StatefulWidget {
  const ChallengesListScreen({super.key});

  @override
  State<ChallengesListScreen> createState() => _ChallengesListScreenState();
}

class _ChallengesListScreenState extends State<ChallengesListScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Challenge>>(
        stream: _db.userChallengesStream(uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final challenges = snap.data!;
          if (challenges.isEmpty) {
            return _EmptyState(onCreate: () => _openEditor(context));
          }
          return _ChallengeListView(
            challenges: challenges,
            db: _db,
            uid: uid,
            theme: theme,
            colorScheme: colorScheme,
            onTap: (c) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeDetailScreen(challenge: c),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChallengeEditorScreen()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.emoji_events_rounded,
                  size: 40, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('No challenges yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Set a goal with friends and track\nprogress day by day',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Challenge'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeListView extends StatelessWidget {
  final List<Challenge> challenges;
  final DatabaseService db;
  final String uid;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final void Function(Challenge) onTap;

  const _ChallengeListView({
    required this.challenges,
    required this.db,
    required this.uid,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return _ChallengeCard(
            challenge: challenge,
            db: db,
            uid: uid,
            theme: theme,
            colorScheme: colorScheme,
            onTap: () => onTap(challenge),
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends StatefulWidget {
  final Challenge challenge;
  final DatabaseService db;
  final String uid;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.db,
    required this.uid,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<_ChallengeCard> {
  ChallengeProgress? _progress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final p = await widget.db.getMyProgress(widget.challenge.id, widget.uid);
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final daysLeft = c.daysLeft();
    final totalDays = c.totalDays();
    final completed = _progress?.completedDays.length ?? 0;
    final completion = totalDays > 0 ? completed / totalDays : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: widget.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_emojiFor(c.title),
                        style: const TextStyle(fontSize: 22),
                        textAlign: TextAlign.center,
                        textHeightBehavior: TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false),
                        strutStyle: const StrutStyle(
                            forceStrutHeight: true, height: 1.8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: widget.theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          '${c.participants.length} ${c.participants.length == 1 ? 'person' : 'people'}',
                          style: widget.theme.textTheme.bodySmall?.copyWith(
                              color: widget.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _DaysBadge(daysLeft: daysLeft),
                ],
              ),
              if (c.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(c.description,
                    style: widget.theme.textTheme.bodySmall
                        ?.copyWith(color: widget.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completion,
                  minHeight: 6,
                  backgroundColor: widget.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$completed/$totalDays days completed',
                style: widget.theme.textTheme.labelSmall
                    ?.copyWith(color: widget.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  final int daysLeft;
  const _DaysBadge({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    if (daysLeft <= 0) return const SizedBox();
    final urgent = daysLeft <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            urgent ? Colors.orange.withAlpha(25) : Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        urgent ? '$daysLeft days' : '$daysLeft days',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: urgent ? Colors.orange.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

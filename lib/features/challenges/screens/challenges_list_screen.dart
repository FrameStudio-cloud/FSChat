import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';
import 'challenge_detail_screen.dart';
import 'challenge_editor_screen.dart';

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
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final challenges = snapshot.data!;

          if (challenges.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No challenges yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Create a challenge with a friend',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Challenge'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                final daysLeft =
                    challenge.endDate.difference(DateTime.now()).inDays;
                final totalDays = challenge.totalDays();
                final completed = challenge.participants
                    .where((p) => challenge.progress(p) == 1.0)
                    .length;
                final totalParticipants = challenge.participants.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChallengeDetailScreen(challenge: challenge),
                      ),
                    ),
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
                                  color: colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.emoji_events_rounded,
                                    color: Colors.amber),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(challenge.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                    Text(
                                      '${challenge.tasks.length} days \u2022 $totalParticipants ${totalParticipants == 1 ? 'person' : 'people'}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              if (daysLeft >= 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: daysLeft <= 3
                                        ? Colors.orange.withAlpha(25)
                                        : Colors.green.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$daysLeft days left',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: daysLeft <= 3
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (challenge.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(challenge.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                            ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: completed / totalParticipants,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$completed/$totalParticipants completed',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

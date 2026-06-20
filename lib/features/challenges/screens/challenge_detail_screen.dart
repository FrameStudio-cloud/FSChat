import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';
import '../models/challenge_progress.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _db = DatabaseService();
  Map<String, ChallengeProgress?> _userProgress = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    for (final pid in widget.challenge.participants) {
      _db.challengeProgressStream(widget.challenge.id, pid).listen((p) {
        if (mounted) setState(() => _userProgress[pid] = p);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uid = context.watch<AuthProvider>().user?.uid;
    final isParticipant =
        uid != null && widget.challenge.participants.contains(uid);
    final myProgress = uid != null ? _userProgress[uid] : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.challenge.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade100, Colors.orange.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.challenge.title,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '${widget.challenge.totalDays()} days \u2022 ${widget.challenge.participants.length} ${widget.challenge.participants.length == 1 ? 'person' : 'people'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.challenge.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(widget.challenge.description,
                      style: theme.textTheme.bodyMedium),
                ],
                if (isParticipant && myProgress != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: myProgress.progress(widget.challenge.totalDays()),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${myProgress.completedDays.length}/${widget.challenge.totalDays()} days completed',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Participants',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...widget.challenge.participants.map((pid) {
            final name = widget.challenge.participantNames[pid] ?? pid;
            final progress = _userProgress[pid];
            final days = progress?.completedDays.length ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  avatarWidget(
                    radius: 16,
                    photoUrl: null,
                    name: name,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Text('$days/${widget.challenge.totalDays()}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Text('Tasks',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(widget.challenge.tasks.length, (i) {
            final dayIndex = i;
            final isCompleted =
                myProgress?.completedDays.contains(dayIndex) ?? false;
            final task = widget.challenge.tasks[i];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: isParticipant ? () => _toggleDay(dayIndex) : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isCompleted ? Colors.green : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green
                                : colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Day ${dayIndex + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                            Text(task, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _toggleDay(int dayIndex) async {
    final uid = context.read<AuthProvider>().user!.uid;
    final progress = _userProgress[uid];
    final isCompleted = progress?.completedDays.contains(dayIndex) ?? false;
    if (isCompleted) {
      await _db.markDayIncomplete(widget.challenge.id, uid, dayIndex);
    } else {
      await _db.markDayComplete(widget.challenge.id, uid, dayIndex);
    }
  }
}

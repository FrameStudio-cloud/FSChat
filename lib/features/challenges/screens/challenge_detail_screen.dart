import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';
import '../models/challenge_progress.dart';
import 'challenge_editor_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _db = DatabaseService();
  final Map<String, ChallengeProgress?> _userProgress = {};
  ChallengeProgress? _myProgress;
  StreamSubscription? _myProgressSub;
  final Set<int> _loadingDays = {};

  @override
  void initState() {
    super.initState();
    _initProgress();
    _scheduleDeadlineReminder();
  }

  void _scheduleDeadlineReminder() {
    NotificationService.scheduleChallengeDeadline(
      challengeId: widget.challenge.id,
      title: widget.challenge.title,
      endDate: widget.challenge.endDate,
    );
  }

  @override
  void dispose() {
    _myProgressSub?.cancel();
    NotificationService.cancelChallengeDeadline(widget.challenge.id);
    super.dispose();
  }

  void _initProgress() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    _myProgressSub = _db.myProgressStream(widget.challenge.id, uid).listen((p) {
      if (mounted) {
        setState(() {
          _myProgress = p;
          _userProgress[uid] = p;
        });
      }
    });

    for (final pid in widget.challenge.participants) {
      if (pid == uid) continue;
      _db.getMyProgress(widget.challenge.id, pid).then((p) {
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
    final totalDays = widget.challenge.totalDays();
    final completed = _myProgress?.completedDays.length ?? 0;
    final completion = totalDays > 0 ? completed / totalDays : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _HeaderSliver(
            challenge: widget.challenge,
            completion: completion,
            completed: completed,
            totalDays: totalDays,
            uid: uid,
            db: _db,
            onChallengeUpdated: (updated) {
              setState(() {});
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.challenge.description.isNotEmpty) ...[
                    Text(widget.challenge.description,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                  ],
                  Text('Participants',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...widget.challenge.participants.map((pid) {
                    final name = widget.challenge.participantNames[pid] ?? pid;
                    final progress = _userProgress[pid];
                    final days = progress?.completedDays.length ?? 0;
                    final isMe = pid == uid;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
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
                            child: Text(
                              isMe ? 'You' : name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text('$days/$totalDays',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }),
                  if (isParticipant) ...[
                    const SizedBox(height: 20),
                    Text('Daily Tasks',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...List.generate(widget.challenge.tasks.length, (i) {
                      final dayIndex = i;
                      final isCompleted =
                          _myProgress?.completedDays.contains(dayIndex) ??
                              false;
                      final isLoading = _loadingDays.contains(dayIndex);
                      final task = widget.challenge.tasks[i];
                      return _TaskCard(
                        dayIndex: dayIndex,
                        task: task,
                        isCompleted: isCompleted,
                        isLoading: isLoading,
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap:
                            isParticipant ? () => _toggleDay(dayIndex) : null,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDay(int dayIndex) async {
    if (_loadingDays.contains(dayIndex)) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final uid = user.uid;
    final isCompleted = _myProgress?.completedDays.contains(dayIndex) ?? false;
    setState(() => _loadingDays.add(dayIndex));
    try {
      if (isCompleted) {
        await _db.markDayIncomplete(widget.challenge.id, uid, dayIndex);
      } else {
        await _db.markDayComplete(widget.challenge.id, uid, dayIndex);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle day: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDays.remove(dayIndex));
    }
  }
}

class _HeaderSliver extends StatelessWidget {
  final Challenge challenge;
  final double completion;
  final int completed;
  final int totalDays;
  final String? uid;
  final DatabaseService db;
  final void Function(Challenge) onChallengeUpdated;

  const _HeaderSliver({
    required this.challenge,
    required this.completion,
    required this.completed,
    required this.totalDays,
    this.uid,
    required this.db,
    required this.onChallengeUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFFE65100),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFFF8A50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(challenge.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                '${challenge.participants.length} ${challenge.participants.length == 1 ? 'person' : 'people'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white.withAlpha(200)),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completion,
                  minHeight: 8,
                  backgroundColor: Colors.white.withAlpha(60),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$completed of $totalDays days done',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.white.withAlpha(220)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (uid != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenu(context, value, uid!),
            itemBuilder: (_) => [
              if (challenge.createdBy == uid)
                const PopupMenuItem(
                    value: 'edit',
                    child:
                        _MenuItem(icon: Icons.edit, label: 'Edit challenge')),
              const PopupMenuItem(
                  value: 'share',
                  child: _MenuItem(icon: Icons.share, label: 'Share')),
              if (challenge.createdBy == uid)
                const PopupMenuItem(
                    value: 'archive',
                    child: _MenuItem(icon: Icons.archive, label: 'Archive')),
              if (challenge.participants.contains(uid!))
                const PopupMenuItem(
                    value: 'leave',
                    child: _MenuItem(
                        icon: Icons.exit_to_app,
                        label: 'Leave challenge',
                        danger: true)),
              if (challenge.createdBy == uid)
                const PopupMenuItem(
                    value: 'delete',
                    child: _MenuItem(
                        icon: Icons.delete,
                        label: 'Delete challenge',
                        danger: true)),
            ],
          ),
      ],
    );
  }

  void _handleMenu(BuildContext context, String value, String uid) async {
    switch (value) {
      case 'edit':
        final updated = await Navigator.push<Challenge>(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeEditorScreen(challenge: challenge),
          ),
        );
        if (updated != null) onChallengeUpdated(updated);
      case 'archive':
        final confirm = await _confirm(context, 'Archive "${challenge.title}"?',
            'It will be hidden from your active challenges.');
        if (confirm == true) {
          await db.archiveChallenge(challenge.id);
          if (context.mounted) Navigator.pop(context);
        }
      case 'leave':
        final confirm = await _confirm(context, 'Leave "${challenge.title}"?',
            'You can rejoin only if someone invites you again.');
        if (confirm == true) {
          await db.leaveChallenge(challenge.id, uid);
          if (context.mounted) Navigator.pop(context);
        }
      case 'delete':
        final confirm = await _confirm(context, 'Delete "${challenge.title}"?',
            'This cannot be undone. All progress will be lost.');
        if (confirm == true) {
          await db.deleteChallenge(challenge.id);
          if (context.mounted) Navigator.pop(context);
        }
    }
  }

  Future<bool?> _confirm(BuildContext context, String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  const _MenuItem(
      {required this.icon, required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: danger ? Colors.red : null),
        const SizedBox(width: 8),
        Text(label, style: danger ? const TextStyle(color: Colors.red) : null),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final int dayIndex;
  final String task;
  final bool isCompleted;
  final bool isLoading;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.dayIndex,
    required this.task,
    required this.isCompleted,
    required this.isLoading,
    required this.colorScheme,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isCompleted
          ? colorScheme.primary.withAlpha(10)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted
            ? BorderSide(color: colorScheme.primary.withAlpha(30))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
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
                  color: isCompleted ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color:
                        isCompleted ? colorScheme.primary : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isCompleted ? Colors.white : null),
                      )
                    : isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${dayIndex + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: isCompleted
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                    Text(task,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color:
                              isCompleted ? colorScheme.onSurfaceVariant : null,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

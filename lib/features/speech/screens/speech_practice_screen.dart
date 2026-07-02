import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/background_mesh.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/speech_notifier.dart';
import '../models/speech_session.dart';

class SpeechPracticeScreen extends StatefulWidget {
  const SpeechPracticeScreen({super.key});

  @override
  State<SpeechPracticeScreen> createState() => _SpeechPracticeScreenState();
}

class _SpeechPracticeScreenState extends State<SpeechPracticeScreen> {
  final _titleController = TextEditingController();
  final _audioPlayer = AudioPlayer();
  final _db = DatabaseService();
  SpeechNotifier? _notifier;
  SpeechSession? _selectedSession;
  int _playingSessionIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _audioDuration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _durationSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notifier == null) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        _notifier = SpeechNotifier();
        _notifier!.init(uid);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    _notifier?.dispose();
    super.dispose();
  }

  void _playSession(SpeechSession session, int index) {
    if (session.audioUrl == null) return;
    _selectedSession = session;
    _playingSessionIndex = index;
    _audioPlayer.setUrl(session.audioUrl!);
    _audioPlayer.play();
    _positionSub?.cancel();
    _positionSub = _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSub?.cancel();
    _durationSub = _audioPlayer.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _audioDuration = d);
    });
    _playerStateSub?.cancel();
    _playerStateSub = _audioPlayer.playerStateStream.listen((s) {
      if (mounted) setState(() => _isPlaying = s.playing);
    });
    setState(() {});
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_notifier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Speech Practice')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ListenableBuilder(
      listenable: _notifier!,
      builder: (context, _) {
        final n = _notifier!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Speech Practice'),
            centerTitle: false,
            actions: [
              if (n.sessions.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.trending_up_rounded),
                  onPressed: () => _showProgress(context),
                  tooltip: 'Progress',
                ),
            ],
          ),
          body: BackgroundMesh(
            child: n.loading
                ? const Center(child: CircularProgressIndicator())
                : n.recordingState == RecordingState.recording
                    ? _buildRecordingView(n, colorScheme)
                    : n.recordingState == RecordingState.processing
                        ? _buildProcessingView(colorScheme)
                        : _buildDashboard(n, colorScheme, theme),
          ),
        );
      },
    );
  }

  Widget _buildProcessingView(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text('Analyzing your speech...',
              style: TextStyle(
                  fontSize: 15, color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Text('Transcribing & scoring',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildRecordingView(SpeechNotifier n, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(n.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(n.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Text('Recording...',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _WaveformPainter(
                color: AppColors.brand,
                elapsed: n.elapsedSeconds,
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _stopRecording(n),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Container(
                margin: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Tap to stop & analyze',
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildDashboard(SpeechNotifier n, ColorScheme cs, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStreakRow(n, cs),
        const SizedBox(height: 20),
        _buildRecordButton(n, cs),
        const SizedBox(height: 24),
        _buildStatsRow(n, cs),
        const SizedBox(height: 24),
        _buildSectionHeader(Icons.history_rounded, 'Recent Sessions', cs),
        const SizedBox(height: 8),
        if (n.sessions.isEmpty)
          _buildEmptyState(cs)
        else
          ...n.sessions
              .asMap()
              .entries
              .map((e) => _buildSessionTile(n, e.value, e.key, cs)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStreakRow(SpeechNotifier n, ColorScheme cs) {
    final streak = n.currentStreak;
    return Row(
      children: [
        Text('🔥', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text('$streak-day streak',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
        const SizedBox(width: 8),
        Text('Best: ${n.bestScore} score',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildRecordButton(SpeechNotifier n, ColorScheme cs) {
    if (n.recordingState == RecordingState.processing) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () => n.startRecording(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
                color: AppColors.brand.withValues(alpha: 0.08),
              ),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text('Tap to start recording',
                style: TextStyle(
                    fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
            const SizedBox(height: 4),
            Text('Speak naturally about any topic',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(SpeechNotifier n, ColorScheme cs) {
    return Row(
      children: [
        _StatTile(
          icon: Icons.check_circle_rounded,
          value: '${n.totalSessions}',
          label: 'SESSIONS',
          color: Colors.green,
          cs: cs,
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.music_note_rounded,
          value: _formatDuration(Duration(seconds: n.averageDuration.toInt())),
          label: 'AVG TIME',
          color: AppColors.brand,
          cs: cs,
        ),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.trending_up_rounded,
          value: '${n.averageScore.toInt()}',
          label: 'SCORE',
          color: Colors.blue,
          cs: cs,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.record_voice_over_rounded,
              size: 48, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text('No sessions yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text('Record your first speech practice',
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildSessionTile(
      SpeechNotifier n, SpeechSession session, int index, ColorScheme cs) {
    final isPlaying = _playingSessionIndex == index && _isPlaying;
    final scoreColor = session.score != null
        ? (session.score! >= 80
            ? Colors.green
            : session.score! >= 60
                ? Colors.orange
                : Colors.red)
        : cs.onSurface.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_playingSessionIndex == index) {
            _togglePlayPause();
          } else {
            _playSession(session, index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.brand.withValues(alpha: 0.15)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isPlaying
                      ? AppColors.brand
                      : cs.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDuration(Duration(seconds: session.duration))} · ${_formatDate(session.createdAt)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
              if (session.score != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${session.score}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scoreColor)),
                ),
              if (isPlaying)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _formatDuration(_position),
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}';
  }

  Future<void> _stopRecording(SpeechNotifier n) async {
    final showTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => _RecordingTitleDialog(controller: _titleController),
    );
    if (showTitle == null || !mounted) return;
    await n.stopRecording(title: showTitle);
    if (!mounted) return;

    if (n.lastAnalysis != null) {
      _showAnalysis(context, n);
    } else if (n.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(n.lastError!),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAnalysis(BuildContext context, SpeechNotifier n) {
    final analysis = n.lastAnalysis;
    if (analysis == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollController) => _AnalysisSheet(
          analysis: analysis,
          scrollController: scrollController,
          onDismiss: () {
            n.dismissAnalysis();
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showProgress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProgressScreen(notifier: _notifier!),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ColorScheme cs;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1.1)),
                Text(label,
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingTitleDialog extends StatefulWidget {
  final TextEditingController controller;
  const _RecordingTitleDialog({required this.controller});

  @override
  State<_RecordingTitleDialog> createState() => _RecordingTitleDialogState();
}

class _RecordingTitleDialogState extends State<_RecordingTitleDialog> {
  late TextEditingController _c;
  final _presets = [
    'Elevator Pitch',
    'TED Talk Warmup',
    'Storytelling',
    'Impromptu Speech',
    'Presentation Rehearsal',
    'Free Talk',
  ];

  @override
  void initState() {
    super.initState();
    _c = widget.controller;
    if (_c.text.isEmpty) _c.text = _presets[0];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Name your session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _presets
                .map((p) => ChoiceChip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      selected: _c.text == p,
                      onSelected: (_) => setState(() => _c.text = p),
                      selectedColor: AppColors.brand,
                      labelStyle: TextStyle(
                        color: _c.text == p ? Colors.white : null,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            decoration: InputDecoration(
              hintText: 'Or type a custom title...',
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  final int elapsed;

  _WaveformPainter({required this.color, required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final count = (size.width / 8).floor().clamp(10, 40);
    final dx = size.width / count;
    final rng = Random(elapsed);

    for (int i = 0; i < count; i++) {
      final h = 8 + rng.nextDouble() * (size.height - 16);
      final x = dx * i + dx / 2;
      paint.color = color.withValues(alpha: 0.3 + rng.nextDouble() * 0.5);
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height - h) / 2 + h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter o) => o.elapsed != elapsed;
}

class _ProgressScreen extends StatelessWidget {
  final SpeechNotifier notifier;
  const _ProgressScreen({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final sessions = notifier.sessions;
        final scored = sessions.where((s) => s.score != null).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Your Progress')),
          body: BackgroundMesh(
            child: sessions.isEmpty
                ? Center(
                    child: Text('No data yet',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4))))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Score Trend',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      const SizedBox(height: 12),
                      Container(
                        height: 140,
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: scored.isEmpty
                            ? Center(
                                child: Text('Complete sessions to see scores',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.4))))
                            : CustomPaint(
                                size: const Size(double.infinity, 110),
                                painter: _ScoreChartPainter(
                                  scores: scored.map((s) => s.score!).toList(),
                                  color: AppColors.brand,
                                  cs: cs,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _ProgressStat(
                            label: 'Best Score',
                            value: '${notifier.bestScore}',
                            color: Colors.green,
                            cs: cs,
                          ),
                          const SizedBox(width: 8),
                          _ProgressStat(
                            label: 'Avg Score',
                            value: '${notifier.averageScore.toInt()}',
                            color: Colors.blue,
                            cs: cs,
                          ),
                          const SizedBox(width: 8),
                          _ProgressStat(
                            label: 'Total Sessions',
                            value: '${notifier.totalSessions}',
                            color: AppColors.brand,
                            cs: cs,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('🔥', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text('Achievements',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _AchievementChip(
                                  label: '${notifier.currentStreak}-day streak',
                                  color: AppColors.brand,
                                  cs: cs,
                                ),
                                if (notifier.bestScore >= 80)
                                  _AchievementChip(
                                    label: 'Score 80+',
                                    color: Colors.green,
                                    cs: cs,
                                  ),
                                if (notifier.totalSessions >= 5)
                                  _AchievementChip(
                                    label: '5+ sessions',
                                    color: Colors.blue,
                                    cs: cs,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final ColorScheme cs;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final String label;
  final Color color;
  final ColorScheme cs;

  const _AchievementChip({
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<int> scores;
  final Color color;
  final ColorScheme cs;

  _ScoreChartPainter({
    required this.scores,
    required this.color,
    required this.cs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxScore = scores.reduce((a, b) => a > b ? a : b).toDouble();
    final minScore = scores.reduce((a, b) => a < b ? a : b).toDouble();
    final range = (maxScore - minScore).clamp(1, double.infinity);
    final stepX = size.width / (scores.length - 1).clamp(1, double.infinity);

    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height -
          ((scores[i] - minScore) / range) * (size.height - 20) -
          10;
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);

      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
    }

    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 2.5, Paint()..color = cs.surfaceContainerLow);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter o) =>
      o.scores != scores || o.color != color;
}

class _AnalysisSheet extends StatelessWidget {
  final GroqAnalysis analysis;
  final ScrollController scrollController;
  final VoidCallback onDismiss;

  const _AnalysisSheet({
    required this.analysis,
    required this.scrollController,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = analysis;
    final scoreColor = a.score >= 80
        ? Colors.green
        : a.score >= 60
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${a.score}',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: scoreColor)),
                    Text('score',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: scoreColor)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analysis Results',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                        a.transcript.length > 80
                            ? '${a.transcript.substring(0, 80)}...'
                            : a.transcript,
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _MetricBox(
                icon: Icons.timer_rounded,
                value: '${a.wordCount}',
                label: 'WORDS',
                color: Colors.blue,
                cs: cs,
              ),
              const SizedBox(width: 8),
              _MetricBox(
                icon: Icons.speed_rounded,
                value: '${a.pace}',
                label: 'WPM PACE',
                color: Colors.orange,
                cs: cs,
              ),
              const SizedBox(width: 8),
              _MetricBox(
                icon: Icons.block_rounded,
                value: '${a.fillerWordCount}',
                label: 'FILLERS',
                color: a.fillerWordCount > 5 ? Colors.red : Colors.green,
                cs: cs,
              ),
            ],
          ),
          if (a.fillerWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: a.fillerWords
                  .map((w) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('"$w"',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('Tip',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(a.tips,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7),
                        height: 1.4)),
              ],
            ),
          ),
          if (a.transcript.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transcript',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.3),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(a.transcript,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.7),
                          height: 1.5)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDismiss,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ColorScheme cs;

  const _MetricBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

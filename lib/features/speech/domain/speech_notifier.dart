import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/groq_service.dart';
import '../models/speech_session.dart';

enum RecordingState { idle, recording, processing, done }

class SpeechNotifier extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AudioRecorder _recorder = AudioRecorder();
  final GroqService _groq = GroqService();
  final Uuid _uuid = Uuid();

  String? _userId;
  List<SpeechSession> _sessions = [];
  bool _loading = true;
  RecordingState _recordingState = RecordingState.idle;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _currentFilePath;
  StreamSubscription? _sessionsSub;

  GroqAnalysis? _lastAnalysis;
  String? _lastError;

  String? get userId => _userId;
  List<SpeechSession> get sessions => _sessions;
  bool get loading => _loading;
  RecordingState get recordingState => _recordingState;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isRecording => _recordingState == RecordingState.recording;
  GroqAnalysis? get lastAnalysis => _lastAnalysis;
  String? get lastError => _lastError;

  int get totalSessions => _sessions.length;
  double get averageDuration {
    if (_sessions.isEmpty) return 0;
    return _sessions.fold(0, (sum, s) => sum + s.duration) / _sessions.length;
  }

  double get averageScore {
    final scored = _sessions.where((s) => s.score != null).toList();
    if (scored.isEmpty) return 0;
    return scored.fold(0, (sum, s) => sum + s.score!) / scored.length;
  }

  int get bestScore {
    final scored = _sessions.where((s) => s.score != null).toList();
    if (scored.isEmpty) return 0;
    return scored.map((s) => s.score!).reduce((a, b) => a > b ? a : b);
  }

  int get currentStreak {
    if (_sessions.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < _sessions.length; i++) {
      final diff = now.difference(_sessions[i].createdAt).inDays;
      if (diff == i) {
        streak++;
      } else if (diff > i) {
        break;
      }
    }
    return streak;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> init(String userId) async {
    _userId = userId;
    _loading = true;
    notifyListeners();
    _sessionsSub = _db.speechSessionsStream(userId).listen(
      (sessions) {
        _sessions = sessions;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> startRecording() async {
    if (_userId == null) return;
    _lastError = null;
    _lastAnalysis = null;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentFilePath = path;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );

    _recordingState = RecordingState.recording;
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<SpeechSession> stopRecording({String title = ''}) async {
    if (_recordingState != RecordingState.recording) {
      return _buildEmptySession();
    }

    _recordingState = RecordingState.processing;
    _timer?.cancel();
    notifyListeners();

    final filePath = _currentFilePath;
    final duration = _elapsedSeconds;

    _currentFilePath = null;
    _elapsedSeconds = 0;

    try {
      await _recorder.stop();
    } catch (_) {}

    if (filePath == null || duration < 1) {
      _recordingState = RecordingState.idle;
      notifyListeners();
      return _buildEmptySession();
    }

    final sessionId = _uuid.v4();
    final titleText =
        title.isNotEmpty ? title : 'Practice ${DateFormat('MMM d, HH:mm')}';

    var session = SpeechSession(
      id: sessionId,
      userId: _userId!,
      title: titleText,
      duration: duration,
      createdAt: DateTime.now(),
    );

    await _db.saveSpeechSession(session);

    GroqAnalysis? analysis;
    try {
      final audioUrl = await _db.uploadSpeechAudio(sessionId, filePath);
      analysis = await _groq.transcribeAndAnalyze(filePath, duration);
      _lastAnalysis = analysis;

      session = session.copyWith(
        audioUrl: audioUrl,
        transcript: analysis.transcript,
        wordCount: analysis.wordCount,
        fillerWordCount: analysis.fillerWordCount,
        pace: analysis.pace,
        score: analysis.score,
      );
      await _db.saveSpeechSession(session);
    } catch (e) {
      _lastError = e.toString();
    }

    try {
      File(filePath).delete();
    } catch (_) {}

    _recordingState = RecordingState.done;
    notifyListeners();
    return session;
  }

  void dismissAnalysis() {
    _lastAnalysis = null;
    notifyListeners();
  }

  SpeechSession _buildEmptySession() => SpeechSession(
        id: '',
        userId: _userId ?? '',
        createdAt: DateTime.now(),
      );

  @override
  void dispose() {
    _timer?.cancel();
    _sessionsSub?.cancel();
    _recorder.dispose();
    _groq.dispose();
    super.dispose();
  }
}

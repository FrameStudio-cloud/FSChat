import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../data/datasources/speech_local_source.dart';
import '../data/models/speech_session_model.dart';

enum RecordingState { idle, recording, processing, done }

class SpeechNotifier extends ChangeNotifier {
  final SpeechLocalSource _localSource = SpeechLocalSource();
  final AudioRecorder _recorder = AudioRecorder();
  final GroqService _groq = GroqService();
  final Uuid _uuid = Uuid();
  LocalStorageService? _storage;

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
    final uniqueDays = _sessions
        .map((s) =>
            DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (uniqueDays.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (uniqueDays.first.isBefore(todayDate)) return 0;

    int streak = 0;
    for (int i = 0; i < uniqueDays.length; i++) {
      final expected = todayDate.subtract(Duration(days: i));
      if (uniqueDays[i] == expected) {
        streak++;
      } else {
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
    _storage = await LocalStorageService.getInstance();
    _loading = true;
    notifyListeners();
    _sessionsSub = _localSource.watchSessions(userId).listen(
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
    if (_userId == null || _recordingState == RecordingState.recording) return;
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

  Future<SpeechSession?> stopRecording({String title = ''}) async {
    if (_recordingState != RecordingState.recording) return null;

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
      return null;
    }

    final sessionId = _uuid.v4();
    final titleText =
        title.isNotEmpty ? title : 'Practice ${DateFormat('MMM d, HH:mm')}';

    final session = SpeechSession()
      ..sessionId = sessionId
      ..userId = _userId!
      ..title = titleText
      ..duration = duration
      ..createdAt = DateTime.now();

    GroqAnalysis? analysis;
    try {
      final localPath = await _storage!.saveSpeechAudio(sessionId, filePath);

      analysis = await _groq.transcribeAndAnalyze(filePath, duration);
      _lastAnalysis = analysis;

      session.localAudioPath = localPath;
      session.transcript = analysis.transcript;
      session.wordCount = analysis.wordCount;
      session.fillerWordCount = analysis.fillerWordCount;
      session.pace = analysis.pace;
      session.score = analysis.score;
    } catch (e) {
      _lastError = e.toString();
    }

    await _localSource.putSession(session);

    try {
      File(filePath).delete();
    } catch (_) {}

    _recordingState = RecordingState.done;
    notifyListeners();
    return session;
  }

  Future<void> deleteSession(Id id, String sessionId) async {
    await _storage?.deleteSpeechAudio(sessionId);
    await _localSource.deleteSession(id);
  }

  void dismissAnalysis() {
    _lastAnalysis = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionsSub?.cancel();
    _recorder.dispose();
    _groq.dispose();
    super.dispose();
  }
}

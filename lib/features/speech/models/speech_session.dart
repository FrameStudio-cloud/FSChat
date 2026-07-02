class SpeechSession {
  final String id;
  final String userId;
  final String title;
  final String? audioUrl;
  final int duration;
  final String? transcript;
  final int? wordCount;
  final int? fillerWordCount;
  final int? pace;
  final int? score;
  final DateTime createdAt;

  SpeechSession({
    required this.id,
    required this.userId,
    this.title = '',
    this.audioUrl,
    this.duration = 0,
    this.transcript,
    this.wordCount,
    this.fillerWordCount,
    this.pace,
    this.score,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'audioUrl': audioUrl,
        'duration': duration,
        'transcript': transcript,
        'wordCount': wordCount,
        'fillerWordCount': fillerWordCount,
        'pace': pace,
        'score': score,
        'createdAt': createdAt,
      };

  factory SpeechSession.fromMap(Map<String, dynamic> map) => SpeechSession(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        audioUrl: map['audioUrl'] as String?,
        duration: map['duration'] as int? ?? 0,
        transcript: map['transcript'] as String?,
        wordCount: map['wordCount'] as int?,
        fillerWordCount: map['fillerWordCount'] as int?,
        pace: map['pace'] as int?,
        score: map['score'] as int?,
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  SpeechSession copyWith({
    String? id,
    String? userId,
    String? title,
    String? audioUrl,
    int? duration,
    String? transcript,
    int? wordCount,
    int? fillerWordCount,
    int? pace,
    int? score,
    DateTime? createdAt,
  }) =>
      SpeechSession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        audioUrl: audioUrl ?? this.audioUrl,
        duration: duration ?? this.duration,
        transcript: transcript ?? this.transcript,
        wordCount: wordCount ?? this.wordCount,
        fillerWordCount: fillerWordCount ?? this.fillerWordCount,
        pace: pace ?? this.pace,
        score: score ?? this.score,
        createdAt: createdAt ?? this.createdAt,
      );
}

class MoodEntry {
  final String id;
  final String userId;
  final String emoji;
  final String label;
  final String note;
  final List<String> tags;
  final DateTime date;
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.emoji,
    required this.label,
    this.note = '',
    this.tags = const [],
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'emoji': emoji,
        'label': label,
        'note': note,
        'tags': tags,
        'date': date,
        'createdAt': createdAt,
      };

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '\u{1F610}',
        label: map['label'] as String? ?? 'Okay',
        note: map['note'] as String? ?? '',
        tags: (map['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        date: (map['date'] as dynamic)?.toDate() ?? DateTime.now(),
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  static const moods = [
    MoodOption('\u{1F601}', 'Great', 0xFF4CAF50),
    MoodOption('\u{1F60A}', 'Good', 0xFF8BC34A),
    MoodOption('\u{1F610}', 'Okay', 0xFFFFC107),
    MoodOption('\u{1F614}', 'Sad', 0xFFFF9800),
    MoodOption('\u{1F622}', 'Rough', 0xFFFF5722),
    MoodOption('\u{1F620}', 'Angry', 0xFFF44336),
    MoodOption('\u{1F630}', 'Anxious', 0xFF9C27B0),
    MoodOption('\u{1F4AA}', 'Strong', 0xFF3F51B5),
    MoodOption('\u{1F9D8}', 'Calm', 0xFF00BCD4),
    MoodOption('\u{1F912}', 'Sick', 0xFF607D8B),
  ];
}

class MoodOption {
  final String emoji;
  final String label;
  final int color;
  const MoodOption(this.emoji, this.label, this.color);
}

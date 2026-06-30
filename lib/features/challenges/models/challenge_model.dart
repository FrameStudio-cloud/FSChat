class Challenge {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final List<String> participants;
  final Map<String, String> participantNames;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> tasks;
  final DateTime createdAt;
  final String status;

  Challenge({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdBy,
    this.participants = const [],
    this.participantNames = const {},
    required this.startDate,
    required this.endDate,
    this.tasks = const [],
    required this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'createdBy': createdBy,
        'participants': participants,
        'participantNames': participantNames,
        'startDate': startDate,
        'endDate': endDate,
        'tasks': tasks,
        'createdAt': createdAt,
        'status': status,
      };

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        createdBy: map['createdBy'] as String? ?? '',
        participants:
            (map['participants'] as List?)?.map((e) => e as String).toList() ??
                [],
        participantNames: (map['participantNames'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        startDate: (map['startDate'] as dynamic)?.toDate() ?? DateTime.now(),
        endDate: (map['endDate'] as dynamic)?.toDate() ?? DateTime.now(),
        tasks: (map['tasks'] as List?)?.map((e) => e as String).toList() ?? [],
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        status: map['status'] as String? ?? 'active',
      );

  int totalDays() => endDate.difference(startDate).inDays + 1;

  int daysLeft() => endDate.difference(DateTime.now()).inDays.clamp(0, 999999);

  bool get isArchived => status == 'archived';

  bool get isCancelled => status == 'cancelled';

  double elapsedProgress() {
    final total = totalDays();
    if (total <= 0) return 0.0;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

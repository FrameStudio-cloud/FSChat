class ChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final Set<int> completedDays;
  final DateTime lastUpdated;

  ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.completedDays = const {},
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'challengeId': challengeId,
        'userId': userId,
        'completedDays': completedDays.toList(),
        'lastUpdated': lastUpdated,
      };

  factory ChallengeProgress.fromMap(Map<String, dynamic> map) =>
      ChallengeProgress(
        id: map['id'] as String? ?? '',
        challengeId: map['challengeId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        completedDays:
            ((map['completedDays'] as List?)?.map((e) => e as int).toSet() ??
                {}),
        lastUpdated:
            (map['lastUpdated'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  double progress(int totalDays) =>
      totalDays > 0 ? completedDays.length / totalDays : 0;
}

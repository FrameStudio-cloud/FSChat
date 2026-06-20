import 'package:isar/isar.dart';

part 'habit_model.g.dart';

@collection
class Habit {
  Id id = Isar.autoIncrement;

  @Index()
  late String firestoreId;

  @Index()
  late String userId;
  late String name;
  late String colorHex;
  late String frequency;
  List<String> customDays = [];
  int currentStreak = 0;
  int longestStreak = 0;
  @Index()
  late DateTime createdAt;
  bool archived = false;

  Habit copyWith({
    String? name,
    String? colorHex,
    String? frequency,
    List<String>? customDays,
    int? currentStreak,
    int? longestStreak,
    bool? archived,
  }) =>
      Habit()
        ..id = id
        ..firestoreId = firestoreId
        ..userId = userId
        ..name = name ?? this.name
        ..colorHex = colorHex ?? this.colorHex
        ..frequency = frequency ?? this.frequency
        ..customDays = customDays ?? this.customDays
        ..currentStreak = currentStreak ?? this.currentStreak
        ..longestStreak = longestStreak ?? this.longestStreak
        ..createdAt = createdAt
        ..archived = archived ?? this.archived;
}

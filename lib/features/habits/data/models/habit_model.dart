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
  bool reminderEnabled = false;
  int reminderHour = 9;
  int reminderMinute = 0;
  String category = 'General';
  String habitType = 'boolean';
  double targetCount = 1;
  String unit = '';

  Habit copyWith({
    String? name,
    String? colorHex,
    String? frequency,
    List<String>? customDays,
    int? currentStreak,
    int? longestStreak,
    bool? archived,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? category,
    String? habitType,
    double? targetCount,
    String? unit,
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
        ..archived = archived ?? this.archived
        ..reminderEnabled = reminderEnabled ?? this.reminderEnabled
        ..reminderHour = reminderHour ?? this.reminderHour
        ..reminderMinute = reminderMinute ?? this.reminderMinute
        ..category = category ?? this.category
        ..habitType = habitType ?? this.habitType
        ..targetCount = targetCount ?? this.targetCount
        ..unit = unit ?? this.unit;
}

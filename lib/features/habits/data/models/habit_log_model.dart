import 'package:isar/isar.dart';

part 'habit_log_model.g.dart';

@collection
class HabitLog {
  Id id = Isar.autoIncrement;

  @Index()
  late String firestoreId;

  @Index()
  late String habitFirestoreId;

  @Index()
  late String dateString;

  late String status;
  String note = '';
  double progress = 0.0;
  late DateTime createdAt;
}

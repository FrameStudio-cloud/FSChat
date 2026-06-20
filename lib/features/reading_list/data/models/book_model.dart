import 'package:isar/isar.dart';

part 'book_model.g.dart';

enum ReadStatus { toRead, reading, completed, dnf }

@collection
class Book {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  late String title;
  String? author;
  int totalPages = 0;
  int currentPage = 0;

  @enumerated
  ReadStatus status = ReadStatus.toRead;

  int rating = 0;
  String notes = '';
  List<String> tags = [];
  late DateTime dateAdded;
  DateTime? dateStarted;
  DateTime? dateCompleted;

  double get progressPercent => totalPages > 0 ? currentPage / totalPages : 0.0;
}

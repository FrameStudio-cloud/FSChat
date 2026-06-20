import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../data/datasources/book_local_source.dart';
import '../data/models/book_model.dart';

class BookNotifier extends ChangeNotifier {
  final BookLocalSource _source;

  BookNotifier(this._source);

  List<Book> _books = [];
  List<Book> get books => _books;

  List<Book> get toRead =>
      _books.where((b) => b.status == ReadStatus.toRead).toList()
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  List<Book> get reading =>
      _books.where((b) => b.status == ReadStatus.reading).toList()
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  List<Book> get completed =>
      _books.where((b) => b.status == ReadStatus.completed).toList()
        ..sort((a, b) {
          if (a.dateCompleted == null && b.dateCompleted == null) return 0;
          if (a.dateCompleted == null) return 1;
          if (b.dateCompleted == null) return -1;
          return b.dateCompleted!.compareTo(a.dateCompleted!);
        });

  List<Book> get dnf => _books.where((b) => b.status == ReadStatus.dnf).toList()
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  bool _loading = true;
  bool get loading => _loading;

  StreamSubscription? _sub;

  void init(String userId) {
    _loading = true;
    notifyListeners();

    _sub = _source.watchBooks(userId).listen((books) {
      _books = books;
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> addBook({
    required String userId,
    required String title,
    String? author,
    int totalPages = 0,
    String notes = '',
    List<String> tags = const [],
  }) async {
    final book = Book()
      ..userId = userId
      ..title = title
      ..author = author
      ..totalPages = totalPages
      ..notes = notes
      ..tags = tags
      ..dateAdded = DateTime.now();
    await _source.putBook(book);
  }

  Future<void> updateBook(
    Id id, {
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    ReadStatus? status,
    String? notes,
    List<String>? tags,
  }) async {
    final book = await _source.getBook(id);
    if (book == null) return;

    if (title != null) book.title = title;
    if (author != null) book.author = author;
    if (totalPages != null) book.totalPages = totalPages;
    if (currentPage != null) book.currentPage = currentPage;
    if (notes != null) book.notes = notes;
    if (tags != null) book.tags = tags;

    if (status != null && status != book.status) {
      book.status = status;
      if (status == ReadStatus.reading && book.dateStarted == null) {
        book.dateStarted = DateTime.now();
      }
      if (status == ReadStatus.completed) {
        book.dateCompleted = DateTime.now();
      }
    }

    await _source.putBook(book);
  }

  Future<void> deleteBook(Id id) async {
    await _source.deleteBook(id);
  }

  Future<void> updateProgress(Id id, int currentPage) async {
    await _source.updateProgress(id, currentPage);
  }

  Future<void> updateRating(Id id, int rating) async {
    await _source.updateRating(id, rating);
  }

  Future<void> advanceStatus(Id id) async {
    final book = await _source.getBook(id);
    if (book == null) return;

    ReadStatus next;
    switch (book.status) {
      case ReadStatus.toRead:
        next = ReadStatus.reading;
        break;
      case ReadStatus.reading:
        next = ReadStatus.completed;
        book.dateCompleted = DateTime.now();
        break;
      case ReadStatus.completed:
        next = ReadStatus.dnf;
        break;
      case ReadStatus.dnf:
        next = ReadStatus.toRead;
        break;
    }
    book.status = next;
    if (next == ReadStatus.reading && book.dateStarted == null) {
      book.dateStarted = DateTime.now();
    }
    await _source.putBook(book);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

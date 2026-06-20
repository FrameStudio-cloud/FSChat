import 'package:isar/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../models/book_model.dart';

class BookLocalSource {
  Isar get _isar => IsarService.instance;

  Stream<List<Book>> watchBooks(String userId) {
    return _isar.books
        .where()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true);
  }

  Future<List<Book>> getAllBooks(String userId) async {
    return _isar.books.where().userIdEqualTo(userId).findAll();
  }

  Future<List<Book>> getBooksByStatus(String userId, ReadStatus status) async {
    return _isar.books
        .where()
        .userIdEqualTo(userId)
        .filter()
        .statusEqualTo(status)
        .findAll();
  }

  Future<Book?> getBook(Id id) async {
    return _isar.books.where().idEqualTo(id).findFirst();
  }

  Future<void> putBook(Book book) async {
    await _isar.writeTxn(() async {
      await _isar.books.put(book);
    });
  }

  Future<void> deleteBook(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.books.delete(id);
    });
  }

  Future<void> updateStatus(Id id, ReadStatus status) async {
    final book = await getBook(id);
    if (book != null) {
      await _isar.writeTxn(() async {
        book.status = status;
        if (status == ReadStatus.reading && book.dateStarted == null) {
          book.dateStarted = DateTime.now();
        }
        if (status == ReadStatus.completed) {
          book.dateCompleted = DateTime.now();
        }
        await _isar.books.put(book);
      });
    }
  }

  Future<void> updateProgress(Id id, int currentPage) async {
    final book = await getBook(id);
    if (book != null) {
      await _isar.writeTxn(() async {
        book.currentPage = currentPage;
        await _isar.books.put(book);
      });
    }
  }

  Future<void> updateRating(Id id, int rating) async {
    final book = await getBook(id);
    if (book != null) {
      await _isar.writeTxn(() async {
        book.rating = rating;
        await _isar.books.put(book);
      });
    }
  }
}

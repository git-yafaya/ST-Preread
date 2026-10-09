import 'dart:async';

import 'package:st_preread/domain/domain.dart';

/// 可以按需制造「迟迟不返回」「读取失败」「导入失败」「删除失败」的假书库，
/// 并记下每次导入、删除收到的参数。
///
/// 现成的内存假书库总是立即成功，覆盖不到这些情形。
class FakeBookRepository implements BookRepository {
  /// [initialBooks] 为 null 表示书架还没读出来：订阅后收不到任何列表。
  FakeBookRepository({List<Book>? initialBooks, required this.bookToImport})
    : _books = initialBooks;

  /// 导入成功时加到书架上的那本书。
  final Book bookToImport;

  /// 非 null 时，新的订阅只会收到这个错误。
  Exception? watchFailure;

  /// 非 null 时，导入以这个异常失败。
  Exception? importFailure;

  /// 非 null 时，删除以这个异常失败。
  Exception? deleteFailure;

  /// 非 null 时，导入要等它完成后才继续，用来停在「导入进行中」。
  Completer<void>? importGate;

  /// 非 null 时，删除要等它完成后才继续，用来停在「删除进行中」。
  Completer<void>? deleteGate;

  final List<String> importedSourcePaths = [];
  final List<String> deletedBookIds = [];

  final StreamController<List<Book>> _updates =
      StreamController<List<Book>>.broadcast();
  List<Book>? _books;

  /// 发布一份新的书架，已有的订阅者会立即收到。
  void publishBooks(List<Book> books) {
    _books = List<Book>.unmodifiable(books);
    _updates.add(_books!);
  }

  @override
  Stream<List<Book>> watchBooks() {
    return Stream<List<Book>>.multi((subscriber) {
      final failure = watchFailure;
      if (failure != null) {
        subscriber.addError(failure);
        return;
      }
      final books = _books;
      if (books != null) {
        subscriber.add(books);
      }
      final subscription = _updates.stream.listen(subscriber.add);
      subscriber.onCancel = subscription.cancel;
    });
  }

  @override
  Future<Book> importBook(String sourcePath) async {
    importedSourcePaths.add(sourcePath);
    await importGate?.future;
    final failure = importFailure;
    if (failure != null) {
      throw failure;
    }
    publishBooks([...?_books, bookToImport]);
    return bookToImport;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    deletedBookIds.add(bookId);
    await deleteGate?.future;
    final failure = deleteFailure;
    if (failure != null) {
      throw failure;
    }
    publishBooks([
      for (final book in _books ?? const <Book>[])
        if (book.id != bookId) book,
    ]);
  }

  @override
  Future<List<ChapterSummary>> listChapters(String bookId) {
    throw UnsupportedError('书架不读取目录');
  }

  @override
  Future<Chapter> loadChapter(String bookId, int chapterIndex) {
    throw UnsupportedError('书架不读取章节');
  }

  Future<void> dispose() => _updates.close();
}

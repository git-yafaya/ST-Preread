import '../../domain/domain.dart';
import 'latest_value_broadcaster.dart';
import 'sample/sample_book_factory.dart';

/// 读取当前时间的函数；抽出来是为了让测试得到确定的导入时间。
typedef CurrentTimeReader = DateTime Function();

/// 内存中的假书库：启动时自带示例书，导入时再追加一本示例书。
class MockBookRepository implements BookRepository {
  MockBookRepository({
    CurrentTimeReader? readCurrentTime,
    int initialBookCount = defaultInitialBookCount,
  }) : _readCurrentTime = readCurrentTime ?? DateTime.now {
    for (var count = 0; count < initialBookCount; count++) {
      _addSampleBook();
    }
  }

  /// 默认预置一本，让书架和阅读页一启动就有内容可看；
  /// 空书架状态可通过删除它或传入 0 得到。
  static const int defaultInitialBookCount = 1;

  final CurrentTimeReader _readCurrentTime;
  final Map<String, SampleBook> _sampleBooksById = {};
  final LatestValueBroadcaster<List<Book>> _books =
      LatestValueBroadcaster<List<Book>>(const []);

  /// 已创建过的示例书数量。只增不减，保证删除后再导入也不会复用旧 id。
  int _createdBookCount = 0;

  @override
  Stream<List<Book>> watchBooks() => _books.watch();

  @override
  Future<List<ChapterSummary>> listChapters(String bookId) async {
    final sampleBook = _requireSampleBook(bookId);
    return List<ChapterSummary>.unmodifiable(
      sampleBook.chapters.map((chapter) => chapter.summary),
    );
  }

  @override
  Future<Chapter> loadChapter(String bookId, int chapterIndex) async {
    final chapters = _requireSampleBook(bookId).chapters;
    if (chapterIndex < 0 || chapterIndex >= chapters.length) {
      throw ChapterNotFoundException(
        bookId: bookId,
        chapterIndex: chapterIndex,
      );
    }
    return chapters[chapterIndex];
  }

  @override
  Future<Book> importBook(String sourcePath) async {
    return _addSampleBook().book;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    _requireSampleBook(bookId);
    _sampleBooksById.remove(bookId);
    _publishBooks();
  }

  Future<void> dispose() => _books.close();

  SampleBook _addSampleBook() {
    _createdBookCount++;
    final sampleBook = buildSampleBook(
      sequenceNumber: _createdBookCount,
      importedAt: _readCurrentTime(),
    );
    _sampleBooksById[sampleBook.book.id] = sampleBook;
    _publishBooks();
    return sampleBook;
  }

  SampleBook _requireSampleBook(String bookId) {
    final sampleBook = _sampleBooksById[bookId];
    if (sampleBook == null) {
      throw BookNotFoundException(bookId);
    }
    return sampleBook;
  }

  void _publishBooks() {
    _books.emit(
      List<Book>.unmodifiable(
        _sampleBooksById.values.map((sampleBook) => sampleBook.book),
      ),
    );
  }
}

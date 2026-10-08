import '../entities/book.dart';
import '../entities/chapter.dart';
import '../entities/chapter_summary.dart';

/// 书籍与章节内容的来源。
///
/// 找不到书或章节时，实现应抛出
/// BookNotFoundException / ChapterNotFoundException。
abstract interface class BookRepository {
  /// 书架上的全部书籍；订阅后立即收到当前列表，之后每次变化再推送。
  Stream<List<Book>> watchBooks();

  Future<List<ChapterSummary>> listChapters(String bookId);

  Future<Chapter> loadChapter(String bookId, int chapterIndex);

  /// [sourcePath] 为 App 可读的本地文件路径。
  Future<Book> importBook(String sourcePath);

  Future<void> deleteBook(String bookId);
}

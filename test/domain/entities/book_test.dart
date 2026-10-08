import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  final importedAt = DateTime.utc(2026, 1, 2, 3, 4, 5);

  Book buildBook() {
    return Book(
      id: 'book-1',
      title: '书名',
      author: '作者',
      coverImagePath: 'covers/book-1.png',
      chapterCount: 3,
      importedAt: importedAt,
    );
  }

  group('Book', () {
    test('字段全部相同时相等且哈希一致', () {
      expect(buildBook(), buildBook());
      expect(buildBook().hashCode, buildBook().hashCode);
    });

    test('任一字段不同则不相等', () {
      final book = buildBook();
      expect(book.copyWith(id: 'book-2'), isNot(book));
      expect(book.copyWith(title: '另一本'), isNot(book));
      expect(book.copyWith(author: () => '别人'), isNot(book));
      expect(book.copyWith(coverImagePath: () => 'other.png'), isNot(book));
      expect(book.copyWith(chapterCount: 4), isNot(book));
      expect(book.copyWith(importedAt: DateTime.utc(2027)), isNot(book));
    });

    test('copyWith 不传参数时得到相等的副本', () {
      expect(buildBook().copyWith(), buildBook());
    });

    test('copyWith 只替换传入的字段', () {
      final renamed = buildBook().copyWith(title: '新书名');
      expect(renamed.title, '新书名');
      expect(renamed.id, 'book-1');
      expect(renamed.author, '作者');
      expect(renamed.chapterCount, 3);
      expect(renamed.importedAt, importedAt);
    });

    test('copyWith 可以把可空字段清空', () {
      final cleared = buildBook().copyWith(
        author: () => null,
        coverImagePath: () => null,
      );
      expect(cleared.author, isNull);
      expect(cleared.coverImagePath, isNull);
    });
  });
}

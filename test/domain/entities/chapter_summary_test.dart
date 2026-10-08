import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const summary = ChapterSummary(bookId: 'book-1', index: 2, title: '第三章');

  group('ChapterSummary', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameSummary = ChapterSummary(
        bookId: 'book-1',
        index: 2,
        title: '第三章',
      );
      expect(summary, sameSummary);
      expect(summary.hashCode, sameSummary.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(summary.copyWith(bookId: 'book-2'), isNot(summary));
      expect(summary.copyWith(index: 3), isNot(summary));
      expect(summary.copyWith(title: '别的章'), isNot(summary));
    });

    test('copyWith 只替换传入的字段', () {
      final moved = summary.copyWith(index: 5);
      expect(moved.index, 5);
      expect(moved.bookId, 'book-1');
      expect(moved.title, '第三章');
      expect(summary.copyWith(), summary);
    });
  });
}

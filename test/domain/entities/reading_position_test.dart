import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const position = ReadingPosition(
    bookId: 'book-1',
    chapterIndex: 2,
    blockIndex: 7,
  );

  group('ReadingPosition', () {
    test('字段全部相同时相等且哈希一致', () {
      const samePosition = ReadingPosition(
        bookId: 'book-1',
        chapterIndex: 2,
        blockIndex: 7,
      );
      expect(position, samePosition);
      expect(position.hashCode, samePosition.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(position.copyWith(bookId: 'book-2'), isNot(position));
      expect(position.copyWith(chapterIndex: 3), isNot(position));
      expect(position.copyWith(blockIndex: 8), isNot(position));
    });

    test('copyWith 只替换传入的字段', () {
      final moved = position.copyWith(blockIndex: 0);
      expect(moved.bookId, 'book-1');
      expect(moved.chapterIndex, 2);
      expect(moved.blockIndex, 0);
      expect(position.copyWith(), position);
    });
  });
}

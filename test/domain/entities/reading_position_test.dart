import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const anchor = ReadingAnchor(
    blockIndex: 7,
    side: TextSide.translation,
    textOffset: 42,
  );
  const position = ReadingPosition(
    bookId: 'book-1',
    chapterIndex: 2,
    anchor: anchor,
  );

  group('ReadingPosition', () {
    test('字段全部相同时相等且哈希一致', () {
      const samePosition = ReadingPosition(
        bookId: 'book-1',
        chapterIndex: 2,
        anchor: ReadingAnchor(
          blockIndex: 7,
          side: TextSide.translation,
          textOffset: 42,
        ),
      );
      expect(position, samePosition);
      expect(position.hashCode, samePosition.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(position.copyWith(bookId: 'book-2'), isNot(position));
      expect(position.copyWith(chapterIndex: 3), isNot(position));
      expect(
        position.copyWith(anchor: anchor.copyWith(textOffset: 43)),
        isNot(position),
      );
    });

    test('copyWith 只替换传入的字段', () {
      final movedAnchor = anchor.copyWith(blockIndex: 0, textOffset: 0);
      final moved = position.copyWith(anchor: movedAnchor);
      expect(moved.bookId, 'book-1');
      expect(moved.chapterIndex, 2);
      expect(moved.anchor, movedAnchor);
      expect(position.copyWith(), position);
    });
  });
}

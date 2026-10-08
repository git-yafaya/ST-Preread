import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const anchor = ReadingAnchor(
    blockIndex: 6,
    side: TextSide.translation,
    textOffset: 120,
  );

  group('ReadingAnchor', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameAnchor = ReadingAnchor(
        blockIndex: 6,
        side: TextSide.translation,
        textOffset: 120,
      );
      expect(anchor, sameAnchor);
      expect(anchor.hashCode, sameAnchor.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(anchor.copyWith(blockIndex: 7), isNot(anchor));
      expect(anchor.copyWith(side: () => TextSide.source), isNot(anchor));
      expect(anchor.copyWith(textOffset: 121), isNot(anchor));
    });

    test('copyWith 只替换传入的字段', () {
      final moved = anchor.copyWith(textOffset: 300);
      expect(moved.blockIndex, 6);
      expect(moved.side, TextSide.translation);
      expect(moved.textOffset, 300);
      expect(anchor.copyWith(), anchor);
    });

    test('copyWith 可以把面清空，表示块的开头（文字块同样合法）', () {
      final blockStart = anchor.copyWith(side: () => null, textOffset: 0);
      expect(blockStart.blockIndex, 6);
      expect(blockStart.side, isNull);
      expect(blockStart.textOffset, 0);
    });

    test('偏移为负，或 side 为 null 却带了非零偏移时断言失败', () {
      const negativeOffset = -1;
      const nonZeroOffset = 5;
      expect(
        () => ReadingAnchor(
          blockIndex: 0,
          side: TextSide.source,
          textOffset: negativeOffset,
        ),
        throwsAssertionError,
      );
      expect(
        () =>
            ReadingAnchor(blockIndex: 0, side: null, textOffset: nonZeroOffset),
        throwsAssertionError,
      );
    });
  });
}

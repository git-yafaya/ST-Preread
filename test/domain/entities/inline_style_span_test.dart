import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const span = InlineStyleSpan(
    startOffset: 3,
    endOffset: 8,
    styles: {InlineStyle.bold, InlineStyle.italic},
  );

  group('InlineStyleSpan', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameSpan = InlineStyleSpan(
        startOffset: 3,
        endOffset: 8,
        styles: {InlineStyle.bold, InlineStyle.italic},
      );
      expect(span, sameSpan);
      expect(span.hashCode, sameSpan.hashCode);
    });

    test('样式集合的书写顺序不影响相等与哈希', () {
      const reorderedSpan = InlineStyleSpan(
        startOffset: 3,
        endOffset: 8,
        styles: {InlineStyle.italic, InlineStyle.bold},
      );
      expect(span, reorderedSpan);
      expect(span.hashCode, reorderedSpan.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(span.copyWith(startOffset: 4), isNot(span));
      expect(span.copyWith(endOffset: 9), isNot(span));
      expect(span.copyWith(styles: const {InlineStyle.bold}), isNot(span));
      expect(
        span.copyWith(styles: const {InlineStyle.bold, InlineStyle.code}),
        isNot(span),
      );
    });

    test('copyWith 只替换传入的字段', () {
      final codeSpan = span.copyWith(styles: const {InlineStyle.code});
      expect(codeSpan.startOffset, 3);
      expect(codeSpan.endOffset, 8);
      expect(codeSpan.styles, {InlineStyle.code});
      expect(span.copyWith(), span);
    });

    test('区间为空或起点为负时断言失败', () {
      const styles = {InlineStyle.bold};
      expect(
        () => InlineStyleSpan(startOffset: 4, endOffset: 4, styles: styles),
        throwsAssertionError,
      );
      expect(
        () => InlineStyleSpan(startOffset: -1, endOffset: 4, styles: styles),
        throwsAssertionError,
      );
    });
  });
}

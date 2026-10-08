import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const source = SidedText(text: 'Hello.', sentences: []);
  const translation = SidedText(text: '你好。', sentences: []);
  const paragraph = ParagraphBlock(
    id: 'block-1',
    source: source,
    translation: translation,
  );
  const illustration = IllustrationBlock(
    id: 'block-2',
    imagePath: 'images/a.png',
    caption: '说明',
  );

  group('ParagraphBlock', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameParagraph = ParagraphBlock(
        id: 'block-1',
        source: SidedText(text: 'Hello.', sentences: []),
        translation: SidedText(text: '你好。', sentences: []),
      );
      expect(paragraph, sameParagraph);
      expect(paragraph.hashCode, sameParagraph.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(paragraph.copyWith(id: 'block-9'), isNot(paragraph));
      expect(paragraph.copyWith(source: () => null), isNot(paragraph));
      expect(paragraph.copyWith(translation: () => null), isNot(paragraph));
    });

    test('textOf 返回对应的一面，缺失的一面返回 null', () {
      expect(paragraph.textOf(TextSide.source), source);
      expect(paragraph.textOf(TextSide.translation), translation);

      final sourceOnly = paragraph.copyWith(translation: () => null);
      expect(sourceOnly.textOf(TextSide.source), source);
      expect(sourceOnly.textOf(TextSide.translation), isNull);
    });

    test('copyWith 不传参数时得到相等的副本', () {
      expect(paragraph.copyWith(), paragraph);
    });

    test('两面都为空时断言失败', () {
      expect(
        () => ParagraphBlock(id: 'empty', source: null, translation: null),
        throwsAssertionError,
      );
    });
  });

  group('IllustrationBlock', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameIllustration = IllustrationBlock(
        id: 'block-2',
        imagePath: 'images/a.png',
        caption: '说明',
      );
      expect(illustration, sameIllustration);
      expect(illustration.hashCode, sameIllustration.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(illustration.copyWith(id: 'block-9'), isNot(illustration));
      expect(illustration.copyWith(imagePath: 'b.png'), isNot(illustration));
      expect(illustration.copyWith(caption: () => null), isNot(illustration));
    });

    test('copyWith 可以清空说明文字', () {
      final withoutCaption = illustration.copyWith(caption: () => null);
      expect(withoutCaption.caption, isNull);
      expect(withoutCaption.imagePath, 'images/a.png');
      expect(illustration.copyWith(), illustration);
    });
  });

  group('ContentBlock', () {
    test('不同类型的块即使 id 相同也不相等', () {
      const ContentBlock paragraphBlock = ParagraphBlock(
        id: 'same-id',
        source: source,
        translation: null,
      );
      const ContentBlock illustrationBlock = IllustrationBlock(
        id: 'same-id',
        imagePath: 'images/a.png',
        caption: null,
      );
      expect(paragraphBlock, isNot(illustrationBlock));
    });

    test('可以用 switch 穷尽两种块', () {
      String describe(ContentBlock block) {
        return switch (block) {
          ParagraphBlock() => 'paragraph',
          IllustrationBlock() => 'illustration',
        };
      }

      expect(describe(paragraph), 'paragraph');
      expect(describe(illustration), 'illustration');
    });
  });
}

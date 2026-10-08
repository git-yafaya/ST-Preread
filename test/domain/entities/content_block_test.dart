import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const source = SidedText(text: 'Hello.', styleSpans: [], sentences: []);
  const translation = SidedText(text: '你好。', styleSpans: [], sentences: []);
  const paragraph = ParagraphBlock(
    id: 'block-1',
    style: ParagraphStyle.body,
    source: source,
    translation: translation,
  );
  const illustration = IllustrationBlock(
    id: 'block-2',
    imagePath: 'images/a.png',
    caption: '说明',
  );
  const divider = DividerBlock(id: 'block-3');

  group('ParagraphBlock', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameParagraph = ParagraphBlock(
        id: 'block-1',
        style: ParagraphStyle.body,
        source: SidedText(text: 'Hello.', styleSpans: [], sentences: []),
        translation: SidedText(text: '你好。', styleSpans: [], sentences: []),
      );
      expect(paragraph, sameParagraph);
      expect(paragraph.hashCode, sameParagraph.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(paragraph.copyWith(id: 'block-9'), isNot(paragraph));
      expect(paragraph.copyWith(style: ParagraphStyle.quote), isNot(paragraph));
      expect(paragraph.copyWith(source: () => null), isNot(paragraph));
      expect(paragraph.copyWith(translation: () => null), isNot(paragraph));
    });

    test('每一种块级样式都互不相等', () {
      final styledParagraphs = {
        for (final style in ParagraphStyle.values)
          paragraph.copyWith(style: style),
      };
      expect(styledParagraphs, hasLength(ParagraphStyle.values.length));
    });

    test('textOf 返回对应的一面，缺失的一面返回 null', () {
      expect(paragraph.textOf(TextSide.source), source);
      expect(paragraph.textOf(TextSide.translation), translation);

      final sourceOnly = paragraph.copyWith(translation: () => null);
      expect(sourceOnly.textOf(TextSide.source), source);
      expect(sourceOnly.textOf(TextSide.translation), isNull);
    });

    test('copyWith 只替换传入的字段', () {
      final heading = paragraph.copyWith(style: ParagraphStyle.heading2);
      expect(heading.style, ParagraphStyle.heading2);
      expect(heading.id, 'block-1');
      expect(heading.source, source);
      expect(heading.translation, translation);
      expect(paragraph.copyWith(), paragraph);
    });

    test('两面都为空时断言失败', () {
      expect(
        () => ParagraphBlock(
          id: 'empty',
          style: ParagraphStyle.body,
          source: null,
          translation: null,
        ),
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

  group('DividerBlock', () {
    test('id 相同时相等且哈希一致', () {
      const sameDivider = DividerBlock(id: 'block-3');
      expect(divider, sameDivider);
      expect(divider.hashCode, sameDivider.hashCode);
    });

    test('id 不同则不相等', () {
      expect(divider.copyWith(id: 'block-9'), isNot(divider));
    });

    test('copyWith 只替换传入的字段', () {
      expect(divider.copyWith(id: 'block-9').id, 'block-9');
      expect(divider.copyWith(), divider);
    });
  });

  group('ContentBlock', () {
    test('不同类型的块即使 id 相同也不相等', () {
      const List<ContentBlock> sameIdBlocks = [
        ParagraphBlock(
          id: 'same-id',
          style: ParagraphStyle.body,
          source: source,
          translation: null,
        ),
        IllustrationBlock(
          id: 'same-id',
          imagePath: 'images/a.png',
          caption: null,
        ),
        DividerBlock(id: 'same-id'),
      ];

      expect(sameIdBlocks.toSet(), hasLength(sameIdBlocks.length));
    });

    test('可以用 switch 穷尽三种块', () {
      String describe(ContentBlock block) {
        return switch (block) {
          ParagraphBlock() => 'paragraph',
          IllustrationBlock() => 'illustration',
          DividerBlock() => 'divider',
        };
      }

      expect(describe(paragraph), 'paragraph');
      expect(describe(illustration), 'illustration');
      expect(describe(divider), 'divider');
    });
  });
}

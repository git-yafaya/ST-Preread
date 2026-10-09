import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/logic/chapter_anchors.dart';

import '../support/reader_fixtures.dart';

void main() {
  const leadingBlock = DividerBlock(id: 'leading');

  Chapter chapterEndingWith(ContentBlock lastBlock) {
    return buildChapter(index: 0, blocks: [leadingBlock, lastBlock]);
  }

  group('chapterStartAnchor', () {
    test('是第一个块的开头', () {
      expect(
        chapterStartAnchor,
        const ReadingAnchor(blockIndex: 0, side: null, textOffset: 0),
      );
    });
  });

  group('resolveChapterEndAnchor', () {
    final bilingualParagraph = buildParagraph(
      source: buildPlainSidedText('原文共七个字符'),
      translation: buildPlainSidedText('译文四字'),
    );

    test('对照显示时取排在最后的辅文（原文）的最后一个字符', () {
      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(bilingualParagraph),
          BilingualDisplayMode.both,
        ),
        const ReadingAnchor(
          blockIndex: 1,
          side: TextSide.source,
          textOffset: 6,
        ),
      );
    });

    test('只看译文时取译文的最后一个字符', () {
      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(bilingualParagraph),
          BilingualDisplayMode.translationOnly,
        ),
        const ReadingAnchor(
          blockIndex: 1,
          side: TextSide.translation,
          textOffset: 3,
        ),
      );
    });

    test('只看原文时取原文的最后一个字符', () {
      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(bilingualParagraph),
          BilingualDisplayMode.sourceOnly,
        ),
        const ReadingAnchor(
          blockIndex: 1,
          side: TextSide.source,
          textOffset: 6,
        ),
      );
    });

    test('末段只有原文时，只看译文也回退到原文', () {
      final sourceOnlyParagraph = buildParagraph(
        source: buildPlainSidedText('只有原文'),
      );

      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(sourceOnlyParagraph),
          BilingualDisplayMode.translationOnly,
        ),
        const ReadingAnchor(
          blockIndex: 1,
          side: TextSide.source,
          textOffset: 3,
        ),
      );
    });

    test('末段只有译文时，对照显示与只看原文都落在译文', () {
      final translationOnlyParagraph = buildParagraph(
        translation: buildPlainSidedText('只有译文'),
      );
      const expected = ReadingAnchor(
        blockIndex: 1,
        side: TextSide.translation,
        textOffset: 3,
      );

      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(translationOnlyParagraph),
          BilingualDisplayMode.both,
        ),
        expected,
      );
      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(translationOnlyParagraph),
          BilingualDisplayMode.sourceOnly,
        ),
        expected,
      );
    });

    test('末块是插图时取块的开头', () {
      const illustration = IllustrationBlock(
        id: 'illustration',
        imagePath: 'missing.png',
        caption: null,
      );

      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(illustration),
          BilingualDisplayMode.both,
        ),
        const ReadingAnchor(blockIndex: 1, side: null, textOffset: 0),
      );
    });

    test('末块是分隔线时取块的开头', () {
      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(const DividerBlock(id: 'trailing')),
          BilingualDisplayMode.both,
        ),
        const ReadingAnchor(blockIndex: 1, side: null, textOffset: 0),
      );
    });

    test('末段文字为空时偏移为 0', () {
      final emptyParagraph = buildParagraph(
        translation: buildPlainSidedText(''),
      );

      expect(
        resolveChapterEndAnchor(
          chapterEndingWith(emptyParagraph),
          BilingualDisplayMode.both,
        ),
        const ReadingAnchor(
          blockIndex: 1,
          side: TextSide.translation,
          textOffset: 0,
        ),
      );
    });

    test('没有任何块的章节退回章首', () {
      expect(
        resolveChapterEndAnchor(
          buildChapter(index: 0, blocks: const []),
          BilingualDisplayMode.both,
        ),
        chapterStartAnchor,
      );
    });
  });

  group('resolveStartingPosition', () {
    final chapters = [
      for (var index = 0; index < 3; index++)
        ChapterSummary(
          bookId: fixtureBookId,
          index: index,
          title: '第 $index 章',
        ),
    ];

    test('没有进度时从第一章开头读起', () {
      expect(
        resolveStartingPosition(
          bookId: fixtureBookId,
          chapters: chapters,
          savedPosition: null,
        ),
        const ReadingPosition(
          bookId: fixtureBookId,
          chapterIndex: 0,
          anchor: chapterStartAnchor,
        ),
      );
    });

    test('有进度时接着上次的章节与锚点读', () {
      const savedPosition = ReadingPosition(
        bookId: fixtureBookId,
        chapterIndex: 2,
        anchor: ReadingAnchor(
          blockIndex: 4,
          side: TextSide.translation,
          textOffset: 120,
        ),
      );

      expect(
        resolveStartingPosition(
          bookId: fixtureBookId,
          chapters: chapters,
          savedPosition: savedPosition,
        ),
        savedPosition,
      );
    });

    test('进度里的章节已不在目录里时从第一章开头读起', () {
      const stalePosition = ReadingPosition(
        bookId: fixtureBookId,
        chapterIndex: 9,
        anchor: ReadingAnchor(blockIndex: 2, side: null, textOffset: 0),
      );

      expect(
        resolveStartingPosition(
          bookId: fixtureBookId,
          chapters: chapters,
          savedPosition: stalePosition,
        ).chapterIndex,
        0,
      );
    });
  });
}

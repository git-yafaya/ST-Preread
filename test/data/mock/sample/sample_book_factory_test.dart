import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/sample/sample_book_factory.dart';
import 'package:st_preread/domain/domain.dart';

/// 按默认字号，一屏手机正文大约容纳这么多汉字；超过它才算「超过一屏」。
const int _charactersPerScreen = 600;

/// 字符区间的统一表示，让样式区间与句子可以共用同一套校验。
typedef _OffsetRange = ({int startOffset, int endOffset});

/// 断言一组区间按顺序排列、互不重叠，且都落在长度为 [textLength] 的文字之内。
void _expectOrderedWithinBounds(List<_OffsetRange> ranges, int textLength) {
  var previousEndOffset = 0;
  for (final range in ranges) {
    expect(range.startOffset, greaterThanOrEqualTo(previousEndOffset));
    expect(range.endOffset, greaterThan(range.startOffset));
    expect(range.endOffset, lessThanOrEqualTo(textLength));
    previousEndOffset = range.endOffset;
  }
}

List<_OffsetRange> _sentenceRangesOf(SidedText sidedText) {
  return [
    for (final sentence in sidedText.sentences)
      (startOffset: sentence.startOffset, endOffset: sentence.endOffset),
  ];
}

List<_OffsetRange> _styleRangesOf(SidedText sidedText) {
  return [
    for (final span in sidedText.styleSpans)
      (startOffset: span.startOffset, endOffset: span.endOffset),
  ];
}

/// 一段样式是否同时盖住了两句话各自的一部分。
bool _crossesSentenceBoundary(InlineStyleSpan span, SidedText sidedText) {
  final touchedSentences = sidedText.sentences.where(
    (sentence) =>
        sentence.startOffset < span.endOffset &&
        span.startOffset < sentence.endOffset,
  );
  return touchedSentences.length > 1;
}

void main() {
  final importedAt = DateTime.utc(2026, 10, 8);
  final sampleBook = buildSampleBook(sequenceNumber: 1, importedAt: importedAt);
  final allBlocks = [
    for (final chapter in sampleBook.chapters) ...chapter.blocks,
  ];
  final paragraphs = allBlocks.whereType<ParagraphBlock>().toList();
  final illustrations = allBlocks.whereType<IllustrationBlock>().toList();
  final allSidedTexts = [
    for (final paragraph in paragraphs)
      for (final side in TextSide.values) ?paragraph.textOf(side),
  ];
  final allSentences = [
    for (final sidedText in allSidedTexts) ...sidedText.sentences,
  ];
  final allStyleSpans = [
    for (final sidedText in allSidedTexts) ...sidedText.styleSpans,
  ];
  final allStyledTexts = {
    for (final sidedText in allSidedTexts)
      for (final span in sidedText.styleSpans)
        sidedText.text.substring(span.startOffset, span.endOffset),
  };

  group('示例书的基本信息', () {
    test('书架条目与章节内容一致', () {
      expect(sampleBook.book.chapterCount, sampleBook.chapters.length);
      expect(sampleBook.book.importedAt, importedAt);
      expect(sampleBook.book.title, isNotEmpty);
      for (final (index, chapter) in sampleBook.chapters.indexed) {
        expect(chapter.summary.bookId, sampleBook.book.id);
        expect(chapter.summary.index, index);
        expect(chapter.summary.title, isNotEmpty);
      }
    });

    test('不同序号的示例书 id 与标题都不同', () {
      final anotherBook = buildSampleBook(
        sequenceNumber: 2,
        importedAt: importedAt,
      );

      expect(anotherBook.book.id, isNot(sampleBook.book.id));
      expect(anotherBook.book.title, isNot(sampleBook.book.title));
    });

    test('块 id 在整本书内唯一', () {
      final blockIds = allBlocks.map((block) => block.id).toList();
      expect(blockIds.toSet(), hasLength(blockIds.length));
    });
  });

  group('示例书的覆盖面', () {
    test('有多个章节', () {
      expect(sampleBook.chapters.length, greaterThan(1));
    });

    test('有双语段落，也有只有原文、只有译文的段落', () {
      bool hasOnly(ParagraphBlock paragraph, TextSide side) {
        return TextSide.values.every(
          (candidate) =>
              (paragraph.textOf(candidate) != null) == (candidate == side),
        );
      }

      expect(
        paragraphs.where(
          (paragraph) =>
              paragraph.source != null && paragraph.translation != null,
        ),
        isNotEmpty,
      );
      expect(
        paragraphs.where((paragraph) => hasOnly(paragraph, TextSide.source)),
        isNotEmpty,
      );
      expect(
        paragraphs.where(
          (paragraph) => hasOnly(paragraph, TextSide.translation),
        ),
        isNotEmpty,
      );
    });

    test('有带语音的句子，也有不带语音的句子', () {
      expect(allSentences.where((sentence) => sentence.hasAudio), isNotEmpty);
      expect(allSentences.where((sentence) => !sentence.hasAudio), isNotEmpty);
    });

    test('同一面里存在有语音与无语音句子混排的段落', () {
      bool isMixed(SidedText sidedText) {
        final audioFlags = sidedText.sentences.map(
          (sentence) => sentence.hasAudio,
        );
        return audioFlags.contains(true) && audioFlags.contains(false);
      }

      expect(allSidedTexts.where(isMixed), isNotEmpty);
    });

    test('有没有句级数据的一面', () {
      expect(
        allSidedTexts.where((sidedText) => sidedText.sentences.isEmpty),
        isNotEmpty,
      );
    });

    test('语音既有「一句一个文件」也有「一个文件按区间切分」', () {
      final clips = allSentences.map((sentence) => sentence.audio).nonNulls;

      expect(
        clips.where((clip) => clip.start == null && clip.end == null),
        isNotEmpty,
      );
      expect(
        clips.where((clip) => clip.start != null && clip.end != null),
        isNotEmpty,
      );
    });

    test('有插图块，带说明与不带说明的各至少一个', () {
      expect(
        illustrations.where((illustration) => illustration.caption != null),
        isNotEmpty,
      );
      expect(
        illustrations.where((illustration) => illustration.caption == null),
        isNotEmpty,
      );
      expect(
        illustrations.every(
          (illustration) => illustration.imagePath.isNotEmpty,
        ),
        isTrue,
      );
    });

    test('有两面都长到超过一屏的段落', () {
      final longParagraphs = paragraphs.where(
        (paragraph) => TextSide.values.every(
          (side) =>
              (paragraph.textOf(side)?.text.length ?? 0) > _charactersPerScreen,
        ),
      );

      expect(longParagraphs, isNotEmpty);
    });

    test('三章分别对应：朗读译文、回退到原文、不可播放', () {
      final narrationSides = [
        for (final chapter in sampleBook.chapters)
          selectNarrationSide(chapter, BilingualDisplayMode.both),
      ];

      expect(narrationSides, [TextSide.translation, TextSide.source, null]);
    });
  });

  group('示例书的 Markdown 覆盖面', () {
    test('四种行内样式都出现过', () {
      final usedStyles = {for (final span in allStyleSpans) ...span.styles};

      expect(usedStyles, InlineStyle.values.toSet());
    });

    test('有一处粗斜体叠加在同一个区间里', () {
      expect(
        allStyleSpans.where(
          (span) => span.styles.containsAll(const {
            InlineStyle.bold,
            InlineStyle.italic,
          }),
        ),
        isNotEmpty,
      );
    });

    test('有一处样式区间跨越句子边界', () {
      final crossingSidedTexts = allSidedTexts.where(
        (sidedText) => sidedText.styleSpans.any(
          (span) => _crossesSentenceBoundary(span, sidedText),
        ),
      );

      expect(crossingSidedTexts, isNotEmpty);
    });

    test('三级标题、引用段与正文段都出现过', () {
      final usedStyles = {for (final paragraph in paragraphs) paragraph.style};

      expect(usedStyles, ParagraphStyle.values.toSet());
    });

    test('有分隔线', () {
      expect(allBlocks.whereType<DividerBlock>(), isNotEmpty);
    });

    test('各章的 Markdown 形态与约定的分布一致', () {
      Set<ParagraphStyle> headingAndQuoteStylesOf(Chapter chapter) {
        return {
          for (final block in chapter.blocks.whereType<ParagraphBlock>())
            if (block.style != ParagraphStyle.body) block.style,
        };
      }

      Set<InlineStyle> inlineStylesOf(Chapter chapter) {
        return {
          for (final block in chapter.blocks.whereType<ParagraphBlock>())
            for (final side in TextSide.values)
              for (final span in block.textOf(side)?.styleSpans ?? const [])
                ...span.styles,
        };
      }

      final blockStylesByChapter = [
        for (final chapter in sampleBook.chapters)
          headingAndQuoteStylesOf(chapter),
      ];
      final inlineStylesByChapter = [
        for (final chapter in sampleBook.chapters) inlineStylesOf(chapter),
      ];
      final dividerCountsByChapter = [
        for (final chapter in sampleBook.chapters)
          chapter.blocks.whereType<DividerBlock>().length,
      ];

      expect(blockStylesByChapter, [
        {ParagraphStyle.heading1, ParagraphStyle.heading2},
        {ParagraphStyle.heading3, ParagraphStyle.quote},
        <ParagraphStyle>{},
      ]);
      expect(inlineStylesByChapter, [
        {InlineStyle.bold, InlineStyle.italic},
        {InlineStyle.strikethrough},
        {InlineStyle.code},
      ]);
      expect(dividerCountsByChapter, [1, 0, 1]);
    });

    test('样式区间框住的正是预期的那些文字', () {
      expect(allStyledTexts, {
        'Nobody',
        '没有人',
        'Come before the autumn tide',
        '赶在秋潮之前来',
        'a keeper',
        '守灯人',
        'did not come back. Inside the tower, slowly,',
        '没有再回来。塔里，有人慢慢地',
        'the direction of the wind',
        '风的方向',
        '19:06',
      });
    });

    test('正文是纯文字，不含 Markdown 标记', () {
      final inlineMarker = RegExp(r'[*_~`]');
      final blockMarker = RegExp(r'^\s*(#{1,6}\s|>\s|-{3,}\s*$)');

      for (final sidedText in allSidedTexts) {
        expect(sidedText.text, isNot(contains(inlineMarker)));
        expect(blockMarker.hasMatch(sidedText.text), isFalse);
      }
    });
  });

  group('示例书的区间数据', () {
    test('每一面的句子按顺序排列、互不重叠且不越界', () {
      for (final sidedText in allSidedTexts) {
        _expectOrderedWithinBounds(
          _sentenceRangesOf(sidedText),
          sidedText.text.length,
        );
      }
    });

    test('每一面的样式区间按起点排序、互不重叠且不越界', () {
      for (final sidedText in allSidedTexts) {
        _expectOrderedWithinBounds(
          _styleRangesOf(sidedText),
          sidedText.text.length,
        );
      }
    });

    test('样式区间首尾不落在空白上', () {
      for (final styledText in allStyledTexts) {
        expect(styledText, styledText.trim());
      }
    });

    test('句子首尾不落在空白上', () {
      for (final sidedText in allSidedTexts) {
        for (final sentence in sidedText.sentences) {
          final sentenceText = sidedText.text.substring(
            sentence.startOffset,
            sentence.endOffset,
          );
          expect(sentenceText, sentenceText.trim());
        }
      }
    });
  });
}

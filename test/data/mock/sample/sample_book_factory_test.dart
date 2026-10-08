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

List<String> _sentenceTextsOf(SidedText sidedText) {
  return [
    for (final sentence in sidedText.sentences)
      sidedText.text.substring(sentence.startOffset, sentence.endOffset),
  ];
}

List<String> _styledTextsOf(SidedText sidedText) {
  return [
    for (final span in sidedText.styleSpans)
      sidedText.text.substring(span.startOffset, span.endOffset),
  ];
}

bool _hasVoicedSentence(SidedText? sidedText) {
  return sidedText?.sentences.any((sentence) => sentence.hasAudio) ?? false;
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

/// 相邻两句之间是否留有不属于任何句子的文字。
bool _hasGapBetweenSentences(SidedText sidedText) {
  final sentences = sidedText.sentences;
  for (var index = 1; index < sentences.length; index++) {
    if (sentences[index].startOffset > sentences[index - 1].endOffset) {
      return true;
    }
  }
  return false;
}

bool _containsSurrogatePair(String text) => text.runes.length < text.length;

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

    test('有多个章节', () {
      expect(sampleBook.chapters.length, greaterThan(1));
    });
  });

  group('示例书的段落形态', () {
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

    test('原文是日语、译文是中文', () {
      final kana = RegExp(r'[぀-ヿ]');
      final sourceTexts = paragraphs
          .map((paragraph) => paragraph.source?.text)
          .nonNulls;
      final translationTexts = paragraphs
          .map((paragraph) => paragraph.translation?.text)
          .nonNulls;

      expect(sourceTexts.where(kana.hasMatch), isNotEmpty);
      expect(translationTexts.where(kana.hasMatch), isEmpty);
    });

    test('有没有句级数据的一面', () {
      expect(
        allSidedTexts.where((sidedText) => sidedText.sentences.isEmpty),
        isNotEmpty,
      );
    });

    test('有句间间隙：相邻两句之间留有不属于任何句子的文字', () {
      expect(allSidedTexts.where(_hasGapBetweenSentences), isNotEmpty);
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
  });

  group('示例书的语音分布', () {
    final bilingualParagraphs = paragraphs
        .where(
          (paragraph) =>
              paragraph.source != null && paragraph.translation != null,
        )
        .toList();

    Iterable<ParagraphBlock> paragraphsWhere({
      required bool sourceVoiced,
      required bool translationVoiced,
    }) {
      return bilingualParagraphs.where(
        (paragraph) =>
            _hasVoicedSentence(paragraph.source) == sourceVoiced &&
            _hasVoicedSentence(paragraph.translation) == translationVoiced,
      );
    }

    test('有只有译文句带语音的段落', () {
      expect(
        paragraphsWhere(sourceVoiced: false, translationVoiced: true),
        isNotEmpty,
      );
    });

    test('有只有原文句带语音的段落', () {
      expect(
        paragraphsWhere(sourceVoiced: true, translationVoiced: false),
        isNotEmpty,
      );
    });

    test('有两面都带语音的段落', () {
      expect(
        paragraphsWhere(sourceVoiced: true, translationVoiced: true),
        isNotEmpty,
      );
    });

    test('有两面都不带语音的段落', () {
      expect(
        paragraphsWhere(sourceVoiced: false, translationVoiced: false),
        isNotEmpty,
      );
    });

    test('同一段的同一面里有语音与无语音的句子混排', () {
      bool isMixed(SidedText sidedText) {
        final audioFlags = sidedText.sentences.map(
          (sentence) => sentence.hasAudio,
        );
        return audioFlags.contains(true) && audioFlags.contains(false);
      }

      expect(allSidedTexts.where(isMixed), isNotEmpty);
    });

    test('带语音的都是对白，旁白占多数且没有语音', () {
      // 一句对白可能被切成几句，所以只要求以引号开头或以引号结尾。
      final dialogueQuote = RegExp(r'^[「“]|[」”]$');
      final voicedTexts = [
        for (final sidedText in allSidedTexts)
          for (final (index, text) in _sentenceTextsOf(sidedText).indexed)
            if (sidedText.sentences[index].hasAudio) text,
      ];

      expect(voicedTexts, isNotEmpty);
      expect(voicedTexts, everyElement(contains(dialogueQuote)));
      expect(voicedTexts.length, lessThan(allSentences.length / 2));
    });

    test('长段落里也有可以点播的句子', () {
      final longSidedTexts = allSidedTexts.where(
        (sidedText) => sidedText.text.length > _charactersPerScreen,
      );

      expect(longSidedTexts, isNotEmpty);
      expect(longSidedTexts.every(_hasVoicedSentence), isTrue);
    });

    test('语音片段的区间有效，且都能算出时长', () {
      final clips = allSentences.map((sentence) => sentence.audio).nonNulls;

      for (final clip in clips) {
        final start = clip.start ?? Duration.zero;
        expect(start, greaterThanOrEqualTo(Duration.zero));
        expect(clip.end, isNotNull);
        expect(clip.end, greaterThan(start));
      }
    });

    test('语音既有「一句一个文件」也有「一个文件按区间切分」', () {
      final clips = allSentences
          .map((sentence) => sentence.audio)
          .nonNulls
          .toList();
      final filePaths = clips.map((clip) => clip.filePath).toList();

      expect(clips.where((clip) => clip.start == null), isNotEmpty);
      expect(clips.where((clip) => clip.start != null), isNotEmpty);
      expect(filePaths.toSet().length, lessThan(filePaths.length));
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

    test('样式区间框住的正是预期的那些文字', () {
      final styledTexts = {
        for (final sidedText in allSidedTexts) ..._styledTextsOf(sidedText),
      };

      expect(styledTexts, {
        '誰もいなかった',
        '没有人',
        '秋の大潮の前に来なさい',
        '赶在秋潮之前来',
        '灯台守',
        '守灯人',
        '戻ってはこなかった。塔の中で、誰かがゆっくりと',
        '没有再回来。塔里，有人慢慢地',
        '風の向き',
        '风的方向',
        '19:06',
        '今夜から',
        '今晚起',
      });
    });

    test('正文是显示文字，不含 Markdown 标记', () {
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

    test('句子与样式区间的首尾都不落在空白上', () {
      for (final sidedText in allSidedTexts) {
        final framedTexts = [
          ..._sentenceTextsOf(sidedText),
          ..._styledTextsOf(sidedText),
        ];
        for (final framedText in framedTexts) {
          expect(framedText, framedText.trim());
        }
      }
    });
  });

  group('含 emoji 的文字按 UTF-16 码元计算偏移', () {
    final emojiSidedTexts = allSidedTexts
        .where((sidedText) => _containsSurrogatePair(sidedText.text))
        .toList();

    test('两面各有一处含 emoji 的文字', () {
      expect(emojiSidedTexts, hasLength(TextSide.values.length));
    });

    test('emoji 之后的样式区间没有错位', () {
      final styledTextsAfterEmoji = [
        for (final sidedText in emojiSidedTexts)
          for (final span in sidedText.styleSpans)
            if (_containsSurrogatePair(
              sidedText.text.substring(0, span.startOffset),
            ))
              sidedText.text.substring(span.startOffset, span.endOffset),
      ];

      expect(styledTextsAfterEmoji, unorderedEquals(['今夜から', '今晚起']));
    });

    test('emoji 之后的句子区间没有错位', () {
      final sentenceTextsAfterEmoji = [
        for (final sidedText in emojiSidedTexts)
          for (final sentence in sidedText.sentences)
            if (_containsSurrogatePair(
              sidedText.text.substring(0, sentence.startOffset),
            ))
              sidedText.text.substring(
                sentence.startOffset,
                sentence.endOffset,
              ),
      ];

      expect(
        sentenceTextsAfterEmoji,
        unorderedEquals(['返事はすぐに来た。', '「風邪をひかないようにね」', '回信很快就来了。', '“别着凉。”']),
      );
    });

    test('区间没有把 emoji 的代理对从中间切开', () {
      bool startsWithLowSurrogate(String text) {
        const lowSurrogateStart = 0xDC00;
        const lowSurrogateEnd = 0xDFFF;
        final firstCodeUnit = text.codeUnitAt(0);
        return firstCodeUnit >= lowSurrogateStart &&
            firstCodeUnit <= lowSurrogateEnd;
      }

      for (final sidedText in emojiSidedTexts) {
        final framedTexts = [
          ..._sentenceTextsOf(sidedText),
          ..._styledTextsOf(sidedText),
        ];
        expect(framedTexts.where(startsWithLowSurrogate), isEmpty);
      }
    });
  });
}

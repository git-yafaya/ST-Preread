import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/sample/sample_book_factory.dart';
import 'package:st_preread/domain/domain.dart';

/// 按默认字号，一屏手机正文大约容纳这么多汉字；超过它才算「超过一屏」。
const int _charactersPerScreen = 600;

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

  group('示例书的句级数据', () {
    test('每一面的句子按顺序排列、互不重叠且不越界', () {
      for (final sidedText in allSidedTexts) {
        var previousEndOffset = 0;
        for (final sentence in sidedText.sentences) {
          expect(sentence.startOffset, greaterThanOrEqualTo(previousEndOffset));
          expect(sentence.endOffset, lessThanOrEqualTo(sidedText.text.length));
          previousEndOffset = sentence.endOffset;
        }
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

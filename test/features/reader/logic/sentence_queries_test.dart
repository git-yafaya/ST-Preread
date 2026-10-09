import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/logic/sentence_queries.dart';

import '../support/reader_fixtures.dart';

void main() {
  final translation = buildSidedText(const [
    FixtureSentence('旁白。'),
    FixtureSentence.voiced('“对白。”'),
  ], audioFileStem: 'translation');
  final chapter = buildChapter(
    index: 0,
    blocks: [
      const DividerBlock(id: 'divider'),
      buildParagraph(
        source: buildSidedText(const [FixtureSentence.voiced('「台詞」')]),
        translation: translation,
      ),
      buildParagraph(id: 'translation-only', translation: translation),
    ],
  );

  SentenceRef sentenceRef({
    int blockIndex = 1,
    TextSide side = TextSide.translation,
    int sentenceIndex = 1,
  }) {
    return SentenceRef(
      blockIndex: blockIndex,
      side: side,
      sentenceIndex: sentenceIndex,
    );
  }

  group('findAudioClip', () {
    test('取到带语音句子的语音', () {
      expect(
        findAudioClip(chapter, sentenceRef()),
        translation.sentences[1].audio,
      );
    });

    test('无语音的句子没有语音', () {
      expect(findAudioClip(chapter, sentenceRef(sentenceIndex: 0)), isNull);
    });

    test('定位对不上章节内容时返回 null 而不是抛错', () {
      expect(findAudioClip(chapter, sentenceRef(blockIndex: 9)), isNull);
      expect(findAudioClip(chapter, sentenceRef(blockIndex: 0)), isNull);
      expect(findAudioClip(chapter, sentenceRef(sentenceIndex: 7)), isNull);
      expect(
        findAudioClip(
          chapter,
          sentenceRef(blockIndex: 2, side: TextSide.source),
        ),
        isNull,
      );
    });
  });

  group('isSentenceDisplayed', () {
    bool isDisplayed(SentenceRef sentence, BilingualDisplayMode displayMode) {
      return isSentenceDisplayed(
        chapter: chapter,
        sentence: sentence,
        displayMode: displayMode,
      );
    }

    test('对照显示时两面的句子都在屏幕上', () {
      expect(isDisplayed(sentenceRef(), BilingualDisplayMode.both), isTrue);
      expect(
        isDisplayed(
          sentenceRef(side: TextSide.source, sentenceIndex: 0),
          BilingualDisplayMode.both,
        ),
        isTrue,
      );
    });

    test('只看一面时另一面的句子不再显示', () {
      expect(
        isDisplayed(sentenceRef(), BilingualDisplayMode.sourceOnly),
        isFalse,
      );
      expect(
        isDisplayed(
          sentenceRef(side: TextSide.source, sentenceIndex: 0),
          BilingualDisplayMode.translationOnly,
        ),
        isFalse,
      );
    });

    test('段落只有这一面时，只看另一面也会回退显示它', () {
      expect(
        isDisplayed(
          sentenceRef(blockIndex: 2),
          BilingualDisplayMode.sourceOnly,
        ),
        isTrue,
      );
    });

    test('定位对不上段落时视为不显示', () {
      expect(
        isDisplayed(sentenceRef(blockIndex: 0), BilingualDisplayMode.both),
        isFalse,
      );
      expect(
        isDisplayed(sentenceRef(blockIndex: 9), BilingualDisplayMode.both),
        isFalse,
      );
    });
  });
}

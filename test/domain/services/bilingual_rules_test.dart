import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

import '../../support/chapter_fixtures.dart';

void main() {
  const illustration = IllustrationBlock(
    id: 'illustration',
    imagePath: 'images/a.png',
    caption: null,
  );

  const divider = DividerBlock(id: 'divider');

  group('resolveDisplayedSides', () {
    final bilingual = buildParagraphFixture(
      sourceAudio: [true],
      translationAudio: [true],
    );
    final sourceOnly = buildParagraphFixture(sourceAudio: [true]);
    final translationOnly = buildParagraphFixture(translationAudio: [true]);

    test('双语段落按所选方式显示', () {
      expect(
        resolveDisplayedSides(bilingual, BilingualDisplayMode.sourceOnly),
        [TextSide.source],
      );
      expect(
        resolveDisplayedSides(bilingual, BilingualDisplayMode.translationOnly),
        [TextSide.translation],
      );
    });

    test('对照显示时原文在前、译文在后', () {
      expect(resolveDisplayedSides(bilingual, BilingualDisplayMode.both), [
        TextSide.source,
        TextSide.translation,
      ]);
    });

    test('所选的一面不存在时回退到实际拥有的那一面', () {
      expect(
        resolveDisplayedSides(sourceOnly, BilingualDisplayMode.translationOnly),
        [TextSide.source],
      );
      expect(
        resolveDisplayedSides(translationOnly, BilingualDisplayMode.sourceOnly),
        [TextSide.translation],
      );
    });

    test('对照显示遇到单面段落时只显示存在的那一面', () {
      expect(resolveDisplayedSides(sourceOnly, BilingualDisplayMode.both), [
        TextSide.source,
      ]);
      expect(
        resolveDisplayedSides(translationOnly, BilingualDisplayMode.both),
        [TextSide.translation],
      );
    });

    test('块级样式不影响显示哪几面', () {
      for (final style in ParagraphStyle.values) {
        final styledSourceOnly = buildParagraphFixture(
          style: style,
          sourceAudio: [true],
        );
        expect(
          resolveDisplayedSides(
            styledSourceOnly,
            BilingualDisplayMode.translationOnly,
          ),
          [TextSide.source],
        );
      }
    });

    test('任何显示方式下结果都不为空', () {
      for (final paragraph in [bilingual, sourceOnly, translationOnly]) {
        for (final displayMode in BilingualDisplayMode.values) {
          expect(resolveDisplayedSides(paragraph, displayMode), isNotEmpty);
        }
      }
    });
  });

  group('listPlayableSentences', () {
    test('按阅读顺序列出带语音的句子，跳过无语音的句子、插图块与分隔线', () {
      final chapter = buildChapterFixture([
        buildParagraphFixture(translationAudio: [true, false, true]),
        illustration,
        buildParagraphFixture(translationAudio: [false, true]),
        divider,
      ]);

      expect(listPlayableSentences(chapter, TextSide.translation), const [
        SentenceRef(
          blockIndex: 0,
          side: TextSide.translation,
          sentenceIndex: 0,
        ),
        SentenceRef(
          blockIndex: 0,
          side: TextSide.translation,
          sentenceIndex: 2,
        ),
        SentenceRef(
          blockIndex: 2,
          side: TextSide.translation,
          sentenceIndex: 1,
        ),
      ]);
    });

    test('标题与引用段里带语音的句子同样进入播放队列', () {
      final chapter = buildChapterFixture([
        buildParagraphFixture(
          style: ParagraphStyle.heading1,
          translationAudio: [true],
        ),
        buildParagraphFixture(
          style: ParagraphStyle.quote,
          translationAudio: [true],
        ),
      ]);

      expect(
        listPlayableSentences(chapter, TextSide.translation),
        hasLength(2),
      );
    });

    test('只统计指定的那一面', () {
      final chapter = buildChapterFixture([
        buildParagraphFixture(sourceAudio: [true], translationAudio: [false]),
        buildParagraphFixture(sourceAudio: [true]),
      ]);

      expect(listPlayableSentences(chapter, TextSide.source), hasLength(2));
      expect(listPlayableSentences(chapter, TextSide.translation), isEmpty);
    });

    test('没有句级数据或没有段落时为空', () {
      final withoutSentenceData = buildChapterFixture([
        buildParagraphFixture(sourceAudio: []),
        illustration,
        divider,
      ]);

      expect(
        listPlayableSentences(withoutSentenceData, TextSide.source),
        isEmpty,
      );
      expect(
        listPlayableSentences(buildChapterFixture([]), TextSide.source),
        isEmpty,
      );
    });
  });

  group('selectNarrationSide', () {
    final bothVoiced = buildChapterFixture([
      buildParagraphFixture(sourceAudio: [true], translationAudio: [true]),
    ]);
    final onlySourceVoiced = buildChapterFixture([
      buildParagraphFixture(sourceAudio: [true], translationAudio: [false]),
    ]);
    final onlyTranslationVoiced = buildChapterFixture([
      buildParagraphFixture(sourceAudio: [false], translationAudio: [true]),
    ]);
    final unvoiced = buildChapterFixture([
      buildParagraphFixture(sourceAudio: [false], translationAudio: [false]),
      illustration,
      divider,
    ]);

    test('单面显示时朗读所显示的那一面', () {
      expect(
        selectNarrationSide(bothVoiced, BilingualDisplayMode.sourceOnly),
        TextSide.source,
      );
      expect(
        selectNarrationSide(bothVoiced, BilingualDisplayMode.translationOnly),
        TextSide.translation,
      );
    });

    test('对照显示时优先译文', () {
      expect(
        selectNarrationSide(bothVoiced, BilingualDisplayMode.both),
        TextSide.translation,
      );
    });

    test('所选面在本章没有任何语音时退到另一面', () {
      expect(
        selectNarrationSide(
          onlySourceVoiced,
          BilingualDisplayMode.translationOnly,
        ),
        TextSide.source,
      );
      expect(
        selectNarrationSide(onlySourceVoiced, BilingualDisplayMode.both),
        TextSide.source,
      );
      expect(
        selectNarrationSide(
          onlyTranslationVoiced,
          BilingualDisplayMode.sourceOnly,
        ),
        TextSide.translation,
      );
    });

    test('按章判断：所选面只要有一句带语音就不回退', () {
      final mostlySilentTranslation = buildChapterFixture([
        buildParagraphFixture(sourceAudio: [true], translationAudio: [false]),
        buildParagraphFixture(sourceAudio: [true], translationAudio: [true]),
      ]);

      expect(
        selectNarrationSide(mostlySilentTranslation, BilingualDisplayMode.both),
        TextSide.translation,
      );
    });

    test('两面都没有语音时本章不可播放', () {
      for (final displayMode in BilingualDisplayMode.values) {
        expect(selectNarrationSide(unvoiced, displayMode), isNull);
      }
    });
  });
}

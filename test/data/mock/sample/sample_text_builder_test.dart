import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/sample/sample_content_spec.dart';
import 'package:st_preread/data/mock/sample/sample_text_builder.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const audioFileStem = 'audio/block';

  List<String> sentenceTextsOf(SidedText sidedText) {
    return [
      for (final sentence in sidedText.sentences)
        sidedText.text.substring(sentence.startOffset, sentence.endOffset),
    ];
  }

  List<String> styledTextsOf(SidedText sidedText) {
    return [
      for (final span in sidedText.styleSpans)
        sidedText.text.substring(span.startOffset, span.endOffset),
    ];
  }

  group('buildSidedText', () {
    test('译文句间不留空，每句的区间正好框住这一句', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(['第一句。', '第二句更长一些。']),
        side: TextSide.translation,
        audioFileStem: audioFileStem,
      );

      expect(sidedText.text, '第一句。第二句更长一些。');
      expect(sentenceTextsOf(sidedText), ['第一句。', '第二句更长一些。']);
    });

    test('原文句间有空格，空格不属于任何一句', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(['First one.', 'Second one.']),
        side: TextSide.source,
        audioFileStem: audioFileStem,
      );

      expect(sidedText.text, 'First one. Second one.');
      expect(sentenceTextsOf(sidedText), ['First one.', 'Second one.']);
    });

    test('译文的语音是一句一个文件、不带区间', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(['第一句。', '第二句。']),
        side: TextSide.translation,
        audioFileStem: audioFileStem,
      );
      final clips = [
        for (final sentence in sidedText.sentences) sentence.audio,
      ];

      expect(clips.map((clip) => clip?.filePath).toSet(), hasLength(2));
      expect(clips.every((clip) => clip?.start == null), isTrue);
      expect(clips.every((clip) => clip?.end == null), isTrue);
    });

    test('原文的语音是整段一个文件、按时间线依次切分', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(['First one.', 'Second one.']),
        side: TextSide.source,
        audioFileStem: audioFileStem,
      );
      final firstClip = sidedText.sentences.first.audio;
      final secondClip = sidedText.sentences.last.audio;

      expect(firstClip?.filePath, secondClip?.filePath);
      expect(firstClip?.start, Duration.zero);
      expect(firstClip?.end, greaterThan(Duration.zero));
      expect(secondClip?.start, greaterThanOrEqualTo(firstClip!.end!));
      expect(secondClip?.end, greaterThan(secondClip!.start!));
    });

    test('标记为无语音的句子没有语音，但仍保留句级切分', () {
      final sidedText = buildSidedText(
        spec: const SampleSideSpec([
          SampleSentence('有语音。'),
          SampleSentence('没有语音。', hasAudio: false),
        ]),
        side: TextSide.translation,
        audioFileStem: audioFileStem,
      );

      expect(sidedText.sentences.map((sentence) => sentence.hasAudio), [
        true,
        false,
      ]);
    });

    test('没有标注样式时样式区间为空', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(['第一句。']),
        side: TextSide.translation,
        audioFileStem: audioFileStem,
      );

      expect(sidedText.styleSpans, isEmpty);
    });

    test('样式短语换算成正好框住它的区间，正文仍是不含标记的纯文字', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(
          ['灯塔需要一个守灯人。'],
          styledPhrases: const [
            SampleStyledPhrase('守灯人', {InlineStyle.bold, InlineStyle.italic}),
          ],
        ),
        side: TextSide.translation,
        audioFileStem: audioFileStem,
      );
      final span = sidedText.styleSpans.single;

      expect(sidedText.text, '灯塔需要一个守灯人。');
      expect(styledTextsOf(sidedText), ['守灯人']);
      expect(span.styles, {InlineStyle.bold, InlineStyle.italic});
    });

    test('多处样式按在正文中的先后排序，与书写顺序无关', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(
          ['First one.', 'Second one.'],
          styledPhrases: const [
            SampleStyledPhrase('Second', {InlineStyle.code}),
            SampleStyledPhrase('First', {InlineStyle.strikethrough}),
          ],
        ),
        side: TextSide.source,
        audioFileStem: audioFileStem,
      );

      expect(styledTextsOf(sidedText), ['First', 'Second']);
      expect(sidedText.styleSpans.map((span) => span.styles), [
        {InlineStyle.strikethrough},
        {InlineStyle.code},
      ]);
    });

    test('样式短语可以跨越句子边界，句间分隔符也算在区间内', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withAudio(
          ['First one.', 'Second one.'],
          styledPhrases: const [
            SampleStyledPhrase('one. Second', {InlineStyle.italic}),
          ],
        ),
        side: TextSide.source,
        audioFileStem: audioFileStem,
      );
      final span = sidedText.styleSpans.single;
      final firstSentence = sidedText.sentences.first;
      final secondSentence = sidedText.sentences.last;

      expect(styledTextsOf(sidedText), ['one. Second']);
      expect(span.startOffset, lessThan(firstSentence.endOffset));
      expect(span.endOffset, greaterThan(secondSentence.startOffset));
    });

    test('没有句级数据的一面同样可以带样式', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withoutSentenceData(
          ['19:06，她点亮了灯。'],
          styledPhrases: const [
            SampleStyledPhrase('19:06', {InlineStyle.code}),
          ],
        ),
        side: TextSide.translation,
        audioFileStem: audioFileStem,
      );

      expect(sidedText.sentences, isEmpty);
      expect(styledTextsOf(sidedText), ['19:06']);
    });

    test('样式短语不存在、出现多次或互相重叠时报错', () {
      SidedText buildWith(List<SampleStyledPhrase> styledPhrases) {
        return buildSidedText(
          spec: SampleSideSpec.withAudio([
            '灯亮了，灯又灭了。',
          ], styledPhrases: styledPhrases),
          side: TextSide.translation,
          audioFileStem: audioFileStem,
        );
      }

      const bold = {InlineStyle.bold};
      expect(
        () => buildWith(const [SampleStyledPhrase('不存在', bold)]),
        throwsStateError,
      );
      expect(
        () => buildWith(const [SampleStyledPhrase('灯', bold)]),
        throwsStateError,
      );
      expect(
        () => buildWith(const [
          SampleStyledPhrase('灯亮了', bold),
          SampleStyledPhrase('亮了，', bold),
        ]),
        throwsStateError,
      );
    });

    test('没有句级数据时只保留整段文字', () {
      final sidedText = buildSidedText(
        spec: SampleSideSpec.withoutSentenceData(['第一句。', '第二句。']),
        side: TextSide.translation,
        audioFileStem: audioFileStem,
      );

      expect(sidedText.text, '第一句。第二句。');
      expect(sidedText.sentences, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/mock_playback_timing.dart';
import 'package:st_preread/data/mock/sample/sample_content_spec.dart';
import 'package:st_preread/data/mock/sample/sample_text_builder.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const audioFileStem = 'audio/block';

  SidedText build(SampleSideSpec spec, {TextSide side = TextSide.translation}) {
    return buildSidedText(spec: spec, side: side, audioFileStem: audioFileStem);
  }

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

  group('buildSidedText 的句子区间', () {
    test('句子首尾相接，每句的区间正好框住这一句', () {
      final sidedText = build(SampleSideSpec.narration(['第一句。', '第二句更长一些。']));

      expect(sidedText.text, '第一句。第二句更长一些。');
      expect(sentenceTextsOf(sidedText), ['第一句。', '第二句更长一些。']);
    });

    test('句后的间隙出现在正文里，但不属于任何一句', () {
      final sidedText = build(
        const SampleSideSpec([
          SampleSentence('「着いたのかい？', gapAfter: '　'),
          SampleSentence('よく来たね」'),
        ]),
        side: TextSide.source,
      );
      final firstSentence = sidedText.sentences.first;
      final secondSentence = sidedText.sentences.last;

      expect(sidedText.text, '「着いたのかい？　よく来たね」');
      expect(sentenceTextsOf(sidedText), ['「着いたのかい？', 'よく来たね」']);
      expect(secondSentence.startOffset - firstSentence.endOffset, 1);
    });

    test('emoji 按 UTF-16 占两个码元，其后的句子区间不会错位', () {
      final sidedText = build(SampleSideSpec.narration(['到了🌊。', '下一句。']));
      final secondSentence = sidedText.sentences.last;

      expect(sentenceTextsOf(sidedText), ['到了🌊。', '下一句。']);
      expect(secondSentence.startOffset, '到了🌊。'.length);
      expect(secondSentence.startOffset, '到了🌊。'.runes.length + 1);
    });

    test('没有句级数据时只保留整段文字', () {
      final sidedText = build(
        SampleSideSpec.withoutSentenceData(['第一句。', '第二句。']),
      );

      expect(sidedText.text, '第一句。第二句。');
      expect(sidedText.sentences, isEmpty);
    });
  });

  group('buildSidedText 的语音', () {
    const mixedSpec = SampleSideSpec([
      SampleSentence('旁白没有语音。'),
      SampleSentence.voiced('“对白有语音。”'),
      SampleSentence.voiced('“第二句对白更长一些。”'),
    ]);

    test('只有标记为带语音的句子才有语音', () {
      final sidedText = build(mixedSpec);

      expect(sidedText.sentences.map((sentence) => sentence.hasAudio), [
        false,
        true,
        true,
      ]);
    });

    test('旁白式的描述整面都没有语音，但保留句级切分', () {
      final sidedText = build(SampleSideSpec.narration(['第一句。', '第二句。']));

      expect(sidedText.sentences, hasLength(2));
      expect(sidedText.sentences.any((sentence) => sentence.hasAudio), isFalse);
    });

    test('译文是一句一个文件、从文件开头播起，时长随句子长度变化', () {
      final voicedSentences = build(mixedSpec).sentences
          .where((sentence) => sentence.hasAudio)
          .toList();
      final clips = [for (final sentence in voicedSentences) sentence.audio!];

      expect(clips.map((clip) => clip.filePath).toSet(), hasLength(2));
      expect(clips.map((clip) => clip.start), everyElement(isNull));
      expect(clips.map((clip) => clip.end), [
        for (final sentence in voicedSentences)
          MockPlaybackTiming.durationPerCharacter * sentence.length,
      ]);
    });

    test('原文是整段一个文件、按时间线依次切分，时长随句子长度变化', () {
      final voicedSentences = build(
        mixedSpec,
        side: TextSide.source,
      ).sentences.where((sentence) => sentence.hasAudio).toList();
      final firstClip = voicedSentences.first.audio!;
      final secondClip = voicedSentences.last.audio!;

      expect(firstClip.filePath, secondClip.filePath);
      expect(secondClip.start, greaterThanOrEqualTo(firstClip.end!));
      expect(
        firstClip.end! - firstClip.start!,
        MockPlaybackTiming.durationPerCharacter * voicedSentences.first.length,
      );
      expect(
        secondClip.end! - secondClip.start!,
        MockPlaybackTiming.durationPerCharacter * voicedSentences.last.length,
      );
    });
  });

  group('buildSidedText 的样式区间', () {
    test('没有标注样式时样式区间为空', () {
      expect(build(SampleSideSpec.narration(['第一句。'])).styleSpans, isEmpty);
    });

    test('样式短语换算成正好框住它的区间，正文里不含任何标记', () {
      final sidedText = build(
        SampleSideSpec.narration(
          ['灯塔需要一个守灯人。'],
          styledPhrases: const [
            SampleStyledPhrase('守灯人', {InlineStyle.bold, InlineStyle.italic}),
          ],
        ),
      );

      expect(sidedText.text, '灯塔需要一个守灯人。');
      expect(styledTextsOf(sidedText), ['守灯人']);
      expect(sidedText.styleSpans.single.styles, {
        InlineStyle.bold,
        InlineStyle.italic,
      });
    });

    test('多处样式按在正文中的先后排序，与书写顺序无关', () {
      final sidedText = build(
        SampleSideSpec.narration(
          ['先点灯。', '再记账。'],
          styledPhrases: const [
            SampleStyledPhrase('记账', {InlineStyle.code}),
            SampleStyledPhrase('点灯', {InlineStyle.strikethrough}),
          ],
        ),
      );

      expect(styledTextsOf(sidedText), ['点灯', '记账']);
      expect(sidedText.styleSpans.map((span) => span.styles), [
        {InlineStyle.strikethrough},
        {InlineStyle.code},
      ]);
    });

    test('样式短语可以跨越句子边界', () {
      final sidedText = build(
        SampleSideSpec.narration(
          ['没有再回来。', '塔里有人。'],
          styledPhrases: const [
            SampleStyledPhrase('回来。塔里', {InlineStyle.italic}),
          ],
        ),
      );
      final span = sidedText.styleSpans.single;

      expect(styledTextsOf(sidedText), ['回来。塔里']);
      expect(span.startOffset, lessThan(sidedText.sentences.first.endOffset));
      expect(span.endOffset, greaterThan(sidedText.sentences.last.startOffset));
    });

    test('emoji 之后的样式区间按 UTF-16 码元计，不会错位', () {
      final sidedText = build(
        SampleSideSpec.narration(
          ['我到灯塔了🌊 今晚起由我来点灯。'],
          styledPhrases: const [
            SampleStyledPhrase('今晚起', {InlineStyle.bold}),
          ],
        ),
      );

      expect(styledTextsOf(sidedText), ['今晚起']);
      expect(
        sidedText.styleSpans.single.startOffset,
        '我到灯塔了🌊 '.runes.length + 1,
      );
    });

    test('没有句级数据的一面同样可以带样式', () {
      final sidedText = build(
        SampleSideSpec.withoutSentenceData(
          ['19:06，她点亮了灯。'],
          styledPhrases: const [
            SampleStyledPhrase('19:06', {InlineStyle.code}),
          ],
        ),
      );

      expect(sidedText.sentences, isEmpty);
      expect(styledTextsOf(sidedText), ['19:06']);
    });

    test('样式短语不存在、出现多次或互相重叠时报错', () {
      SidedText buildWith(List<SampleStyledPhrase> styledPhrases) {
        return build(
          SampleSideSpec.narration(['灯亮了，灯又灭了。'], styledPhrases: styledPhrases),
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
  });

  group('buildSidedText 输出的集合不可修改', () {
    final styledPhrases = [
      SampleStyledPhrase('守灯人', {InlineStyle.bold}),
    ];

    test('句子列表、样式区间列表与样式集合都拒绝修改', () {
      final sidedText = build(
        SampleSideSpec.narration(['灯塔需要一个守灯人。'], styledPhrases: styledPhrases),
      );

      expect(sidedText.sentences.clear, throwsUnsupportedError);
      expect(sidedText.styleSpans.clear, throwsUnsupportedError);
      expect(sidedText.styleSpans.single.styles.clear, throwsUnsupportedError);
    });

    test('没有句级数据、没有样式时得到的空列表同样拒绝修改', () {
      final sidedText = build(SampleSideSpec.withoutSentenceData(['一段文字。']));
      const sentence = Sentence(startOffset: 0, endOffset: 1, audio: null);

      expect(() => sidedText.sentences.add(sentence), throwsUnsupportedError);
      expect(sidedText.styleSpans.clear, throwsUnsupportedError);
    });

    test('构建之后再改动内容描述里的样式集合，不影响已构建的实体', () {
      final sidedText = build(
        SampleSideSpec.narration(['灯塔需要一个守灯人。'], styledPhrases: styledPhrases),
      );

      styledPhrases.single.styles.add(InlineStyle.italic);

      expect(sidedText.styleSpans.single.styles, {InlineStyle.bold});
    });
  });
}

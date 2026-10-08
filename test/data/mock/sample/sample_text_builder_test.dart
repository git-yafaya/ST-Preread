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

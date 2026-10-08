import '../../../core/constants/mock_playback_timing.dart';
import '../../../domain/domain.dart';
import 'sample_content_spec.dart';

/// 示例语音文件的扩展名。文件并不存在，假播放器不会去读它。
const String _audioFileExtension = '.mp3';

/// 句子之间的分隔符：原文是英文，句间有空格；译文是中文，句间不留空。
String _sentenceSeparatorOf(TextSide side) {
  return switch (side) {
    TextSide.source => ' ',
    TextSide.translation => '',
  };
}

/// 把一面的内容描述拼成正文，并推算行内样式区间、每一句的字符区间与语音。
///
/// [audioFileStem] 是这一面语音文件的路径前缀（不含扩展名）。
/// 样式短语找不到、出现多次或互相重叠时抛 [StateError]：
/// 那是示例内容写错了，应当立刻暴露而不是生成错位的区间。
SidedText buildSidedText({
  required SampleSideSpec spec,
  required TextSide side,
  required String audioFileStem,
}) {
  final separator = _sentenceSeparatorOf(side);
  final text = spec.sentences.map((sentence) => sentence.text).join(separator);
  return SidedText(
    text: text,
    styleSpans: _buildStyleSpans(text, spec.styledPhrases),
    sentences: spec.hasSentenceData
        ? _buildSentences(spec.sentences, side, audioFileStem)
        : const [],
  );
}

List<InlineStyleSpan> _buildStyleSpans(
  String text,
  List<SampleStyledPhrase> styledPhrases,
) {
  final styleSpans = [
    for (final styledPhrase in styledPhrases)
      _locateStyledPhrase(text, styledPhrase),
  ]..sort((first, second) => first.startOffset.compareTo(second.startOffset));
  _ensureNoOverlap(styleSpans);
  return styleSpans;
}

InlineStyleSpan _locateStyledPhrase(
  String text,
  SampleStyledPhrase styledPhrase,
) {
  final startOffset = text.indexOf(styledPhrase.phrase);
  final occursExactlyOnce =
      startOffset >= 0 && startOffset == text.lastIndexOf(styledPhrase.phrase);
  if (!occursExactlyOnce) {
    throw StateError('样式短语必须在所属文字中恰好出现一次：${styledPhrase.phrase}');
  }
  return InlineStyleSpan(
    startOffset: startOffset,
    endOffset: startOffset + styledPhrase.phrase.length,
    styles: styledPhrase.styles,
  );
}

/// [sortedStyleSpans] 须已按起点排序。
void _ensureNoOverlap(List<InlineStyleSpan> sortedStyleSpans) {
  for (var index = 1; index < sortedStyleSpans.length; index++) {
    final previousSpan = sortedStyleSpans[index - 1];
    final currentSpan = sortedStyleSpans[index];
    if (currentSpan.startOffset < previousSpan.endOffset) {
      throw StateError('样式区间互相重叠：$previousSpan 与 $currentSpan');
    }
  }
}

List<Sentence> _buildSentences(
  List<SampleSentence> sampleSentences,
  TextSide side,
  String audioFileStem,
) {
  final separatorLength = _sentenceSeparatorOf(side).length;
  final sentences = <Sentence>[];
  var startOffset = 0;
  for (final (sentenceIndex, sampleSentence) in sampleSentences.indexed) {
    final endOffset = startOffset + sampleSentence.text.length;
    final unvoicedSentence = Sentence(
      startOffset: startOffset,
      endOffset: endOffset,
      audio: null,
    );
    sentences.add(
      sampleSentence.hasAudio
          ? _attachAudio(unvoicedSentence, side, audioFileStem, sentenceIndex)
          : unvoicedSentence,
    );
    startOffset = endOffset + separatorLength;
  }
  return sentences;
}

/// 两面故意用不同的语音组织方式，让两种导出形态在界面开发阶段都被用到。
Sentence _attachAudio(
  Sentence sentence,
  TextSide side,
  String audioFileStem,
  int sentenceIndex,
) {
  final audio = switch (side) {
    // 原文：整段一个文件，按时间线切分；时间线位置按字符偏移折算。
    TextSide.source => AudioClip(
      filePath: '$audioFileStem$_audioFileExtension',
      start: MockPlaybackTiming.durationPerCharacter * sentence.startOffset,
      end: MockPlaybackTiming.durationPerCharacter * sentence.endOffset,
    ),
    // 译文：一句一个文件。
    TextSide.translation => AudioClip(
      filePath: '$audioFileStem-$sentenceIndex$_audioFileExtension',
      start: null,
      end: null,
    ),
  };
  return sentence.copyWith(audio: () => audio);
}

/// 示例书的「内容描述」：只写文字与是否带语音，
/// 字符区间、块 id、语音路径都由构建器推算，避免手写下标出错。
library;

/// 一句示例文字。
class SampleSentence {
  const SampleSentence(this.text, {this.hasAudio = true});

  final String text;
  final bool hasAudio;
}

/// 段落某一面的示例文字。
class SampleSideSpec {
  const SampleSideSpec(this.sentences, {this.hasSentenceData = true});

  /// 这一面有句级切分，但没有任何语音。
  SampleSideSpec.withoutAudio(List<String> sentenceTexts)
    : this([
        for (final text in sentenceTexts) SampleSentence(text, hasAudio: false),
      ]);

  /// 这一面每一句都有语音。
  SampleSideSpec.withAudio(List<String> sentenceTexts)
    : this([for (final text in sentenceTexts) SampleSentence(text)]);

  /// 这一面只有整段文字，没有句级切分。
  SampleSideSpec.withoutSentenceData(List<String> sentenceTexts)
    : this([
        for (final text in sentenceTexts) SampleSentence(text),
      ], hasSentenceData: false);

  final List<SampleSentence> sentences;

  /// 为 false 时构建出的 SidedText.sentences 为空列表。
  final bool hasSentenceData;
}

sealed class SampleBlockSpec {
  const SampleBlockSpec();
}

final class SampleParagraphSpec extends SampleBlockSpec {
  const SampleParagraphSpec({this.source, this.translation});

  final SampleSideSpec? source;
  final SampleSideSpec? translation;
}

final class SampleIllustrationSpec extends SampleBlockSpec {
  const SampleIllustrationSpec({required this.imageFileName, this.caption});

  final String imageFileName;
  final String? caption;
}

class SampleChapterSpec {
  const SampleChapterSpec({required this.title, required this.blocks});

  final String title;
  final List<SampleBlockSpec> blocks;
}

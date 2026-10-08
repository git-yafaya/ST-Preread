/// 示例书的「内容描述」：只写纯文字、哪些短语带样式、哪些句子带语音，
/// 字符区间、块 id、语音路径都由构建器推算，避免手写下标出错。
library;

import '../../../domain/domain.dart';

/// 一句示例文字。
class SampleSentence {
  const SampleSentence(this.text, {this.hasAudio = true});

  final String text;
  final bool hasAudio;
}

/// 一处行内样式：用「被加样式的那段文字」来指明位置。
///
/// [phrase] 必须在所属那一面的整段文字里恰好出现一次，
/// 构建器据此算出字符区间；它可以跨越句子边界。
class SampleStyledPhrase {
  const SampleStyledPhrase(this.phrase, this.styles);

  final String phrase;
  final Set<InlineStyle> styles;
}

/// 段落某一面的示例文字。
class SampleSideSpec {
  const SampleSideSpec(
    this.sentences, {
    this.hasSentenceData = true,
    this.styledPhrases = const [],
  });

  /// 这一面有句级切分，但没有任何语音。
  SampleSideSpec.withoutAudio(
    List<String> sentenceTexts, {
    List<SampleStyledPhrase> styledPhrases = const [],
  }) : this([
         for (final text in sentenceTexts)
           SampleSentence(text, hasAudio: false),
       ], styledPhrases: styledPhrases);

  /// 这一面每一句都有语音。
  SampleSideSpec.withAudio(
    List<String> sentenceTexts, {
    List<SampleStyledPhrase> styledPhrases = const [],
  }) : this([
         for (final text in sentenceTexts) SampleSentence(text),
       ], styledPhrases: styledPhrases);

  /// 这一面只有整段文字，没有句级切分。
  SampleSideSpec.withoutSentenceData(
    List<String> sentenceTexts, {
    List<SampleStyledPhrase> styledPhrases = const [],
  }) : this(
         [for (final text in sentenceTexts) SampleSentence(text)],
         hasSentenceData: false,
         styledPhrases: styledPhrases,
       );

  final List<SampleSentence> sentences;

  /// 为 false 时构建出的 SidedText.sentences 为空列表。
  final bool hasSentenceData;

  final List<SampleStyledPhrase> styledPhrases;
}

sealed class SampleBlockSpec {
  const SampleBlockSpec();
}

final class SampleParagraphSpec extends SampleBlockSpec {
  const SampleParagraphSpec({
    this.style = ParagraphStyle.body,
    this.source,
    this.translation,
  });

  final ParagraphStyle style;
  final SampleSideSpec? source;
  final SampleSideSpec? translation;
}

final class SampleIllustrationSpec extends SampleBlockSpec {
  const SampleIllustrationSpec({required this.imageFileName, this.caption});

  final String imageFileName;
  final String? caption;
}

final class SampleDividerSpec extends SampleBlockSpec {
  const SampleDividerSpec();
}

class SampleChapterSpec {
  const SampleChapterSpec({required this.title, required this.blocks});

  final String title;
  final List<SampleBlockSpec> blocks;
}

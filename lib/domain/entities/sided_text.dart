import 'collection_equality.dart';
import 'inline_style_span.dart';
import 'sentence.dart';

/// 段落某一面的文字，以及这一面的行内样式与句级切分。
class SidedText {
  const SidedText({
    required this.text,
    required this.styleSpans,
    required this.sentences,
  });

  /// 最终显示的文字。已支持的 Markdown 语法的标记在导入时就解析掉；
  /// 不支持的语法与被转义的字面符号原样保留为文字。
  /// 这样句高亮、点句命中、分页都对着同一份文字计算，不必处理「符号占位」。
  final String text;

  /// 按起点排序、互不重叠；未覆盖的区间为默认样式。
  final List<InlineStyleSpan> styleSpans;

  /// 按出现顺序排列、互不重叠；句与句之间允许有不属于任何句子的间隙（如空格）。
  /// 空列表表示这一面没有句级数据。
  final List<Sentence> sentences;

  SidedText copyWith({
    String? text,
    List<InlineStyleSpan>? styleSpans,
    List<Sentence>? sentences,
  }) {
    return SidedText(
      text: text ?? this.text,
      styleSpans: styleSpans ?? this.styleSpans,
      sentences: sentences ?? this.sentences,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SidedText &&
        other.text == text &&
        areListsEqual(other.styleSpans, styleSpans) &&
        areListsEqual(other.sentences, sentences);
  }

  @override
  int get hashCode =>
      Object.hash(text, Object.hashAll(styleSpans), Object.hashAll(sentences));

  @override
  String toString() =>
      'SidedText(length: ${text.length}, '
      'styleSpanCount: ${styleSpans.length}, '
      'sentenceCount: ${sentences.length})';
}

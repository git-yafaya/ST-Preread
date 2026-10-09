import 'dart:collection';

import '../../../domain/domain.dart';
import '../../../domain/entities/collection_equality.dart';
import 'sentence_lookup.dart';
import 'side_highlight.dart';

/// 一个分段受到的播放高亮。
enum SegmentHighlight {
  none,

  /// 属于正被播放（或暂停）的那一句。
  activeSentence,

  /// 属于被播句子所在段落的另一面，整段淡色高亮。
  companion,
}

/// 一面文字里样式完全一致的一段连续字符 `[startOffset, endOffset)`。
///
/// 偏移相对所属那一面的完整文字（不是相对切片），以 UTF-16 码元为单位。
class TextSegment {
  const TextSegment({
    required this.startOffset,
    required this.endOffset,
    required this.inlineStyles,
    required this.isPlayable,
    required this.highlight,
  });

  final int startOffset;
  final int endOffset;
  final Set<InlineStyle> inlineStyles;

  /// 这一段属于一句带语音的句子，需要画「可播」下划线。
  final bool isPlayable;
  final SegmentHighlight highlight;

  /// 两段的样式是否完全一致（不比较位置）。
  bool hasSameAppearanceAs(TextSegment other) {
    return other.isPlayable == isPlayable &&
        other.highlight == highlight &&
        areSetsEqual(other.inlineStyles, inlineStyles);
  }

  @override
  bool operator ==(Object other) {
    return other is TextSegment &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        hasSameAppearanceAs(other);
  }

  @override
  int get hashCode => Object.hash(
    startOffset,
    endOffset,
    Object.hashAllUnordered(inlineStyles),
    isPlayable,
    highlight,
  );

  @override
  String toString() =>
      'TextSegment([$startOffset, $endOffset), '
      'styles: ${inlineStyles.map((style) => style.name).toList()}, '
      'isPlayable: $isPlayable, highlight: ${highlight.name})';
}

/// 一面文字里的一个字符区间 `[start, end)`。
typedef TextFragmentRange = ({int start, int end});

/// 把调用方给的切片区间收进 `[0, textLength]`；[endOffset] 为 null 表示到文字结尾。
///
/// 进度里存的偏移可能来自旧数据，越界时收回来比抛错更合适。
TextFragmentRange clampFragmentRange({
  required int textLength,
  required int startOffset,
  required int? endOffset,
}) {
  final start = startOffset.clamp(0, textLength);
  final end = (endOffset ?? textLength).clamp(start, textLength);
  return (start: start, end: end);
}

/// 把「行内样式区间 + 可播句子区间 + 播放高亮区间」合并成首尾相接、互不重叠的分段。
///
/// 只输出切片 `[startOffset, endOffset)` 之内的部分（[endOffset] 为 null 表示到结尾），
/// 分段的偏移仍相对完整文字。样式完全一致的相邻分段会合并成一段。
/// 切片为空时返回空列表。
List<TextSegment> buildTextSegments({
  required SidedText sidedText,
  required SideHighlight highlight,
  int startOffset = 0,
  int? endOffset,
}) {
  final range = clampFragmentRange(
    textLength: sidedText.text.length,
    startOffset: startOffset,
    endOffset: endOffset,
  );
  if (range.start == range.end) {
    return const [];
  }
  final boundaries = _collectBoundaries(sidedText, range);
  final segments = <TextSegment>[];
  for (var index = 0; index < boundaries.length - 1; index++) {
    final segment = _describeRun(
      sidedText: sidedText,
      highlight: highlight,
      runStart: boundaries[index],
      runEnd: boundaries[index + 1],
    );
    _appendMergingSameAppearance(segments, segment);
  }
  return segments;
}

/// 切片内所有可能改变样式的位置，升序且不重复；首尾分别是切片的起点与终点。
List<int> _collectBoundaries(SidedText sidedText, TextFragmentRange range) {
  final boundaries = SplayTreeSet<int>()
    ..add(range.start)
    ..add(range.end);
  void addIfInsideRange(int offset) {
    if (offset > range.start && offset < range.end) {
      boundaries.add(offset);
    }
  }

  for (final styleSpan in sidedText.styleSpans) {
    addIfInsideRange(styleSpan.startOffset);
    addIfInsideRange(styleSpan.endOffset);
  }
  for (final sentence in sidedText.sentences) {
    addIfInsideRange(sentence.startOffset);
    addIfInsideRange(sentence.endOffset);
  }
  return boundaries.toList();
}

/// 相邻两个边界之间不会再有样式变化，所以取这一段起点处的样式即可代表整段。
TextSegment _describeRun({
  required SidedText sidedText,
  required SideHighlight highlight,
  required int runStart,
  required int runEnd,
}) {
  final sentenceIndex = findSentenceIndexAt(sidedText.sentences, runStart);
  final isPlayable =
      sentenceIndex != null && sidedText.sentences[sentenceIndex].hasAudio;
  return TextSegment(
    startOffset: runStart,
    endOffset: runEnd,
    inlineStyles: _inlineStylesAt(sidedText.styleSpans, runStart),
    isPlayable: isPlayable,
    highlight: _highlightOf(highlight, sentenceIndex),
  );
}

Set<InlineStyle> _inlineStylesAt(List<InlineStyleSpan> styleSpans, int offset) {
  for (final styleSpan in styleSpans) {
    if (offset >= styleSpan.startOffset && offset < styleSpan.endOffset) {
      return styleSpan.styles;
    }
  }
  return const {};
}

SegmentHighlight _highlightOf(SideHighlight highlight, int? sentenceIndex) {
  return switch (highlight) {
    NoSideHighlight() => SegmentHighlight.none,
    CompanionSideHighlight() => SegmentHighlight.companion,
    ActiveSentenceHighlight() =>
      sentenceIndex == highlight.sentenceIndex
          ? SegmentHighlight.activeSentence
          : SegmentHighlight.none,
  };
}

void _appendMergingSameAppearance(
  List<TextSegment> segments,
  TextSegment segment,
) {
  if (segments.isEmpty || !segments.last.hasSameAppearanceAs(segment)) {
    segments.add(segment);
    return;
  }
  final previous = segments.removeLast();
  segments.add(
    TextSegment(
      startOffset: previous.startOffset,
      endOffset: segment.endOffset,
      inlineStyles: previous.inlineStyles,
      isPlayable: previous.isPlayable,
      highlight: previous.highlight,
    ),
  );
}

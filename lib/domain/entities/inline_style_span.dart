import 'collection_equality.dart';

/// 行内样式。
enum InlineStyle { bold, italic, strikethrough, code }

/// 一段行内样式，作用于所属 SidedText.text 的字符区间。
class InlineStyleSpan {
  const InlineStyleSpan({
    required this.startOffset,
    required this.endOffset,
    required this.styles,
  }) : assert(startOffset >= 0, 'startOffset 不能为负'),
       assert(endOffset > startOffset, '样式区间不能为空');

  /// 起始字符下标（含）。
  final int startOffset;

  /// 结束字符下标（不含）。
  final int endOffset;

  /// 嵌套样式（如粗斜体）合并在同一个区间里，
  /// 这样同一面的样式区间可以保持互不重叠。
  final Set<InlineStyle> styles;

  InlineStyleSpan copyWith({
    int? startOffset,
    int? endOffset,
    Set<InlineStyle>? styles,
  }) {
    return InlineStyleSpan(
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      styles: styles ?? this.styles,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InlineStyleSpan &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        areSetsEqual(other.styles, styles);
  }

  @override
  int get hashCode =>
      Object.hash(startOffset, endOffset, Object.hashAllUnordered(styles));

  @override
  String toString() =>
      'InlineStyleSpan(startOffset: $startOffset, endOffset: $endOffset, '
      'styles: ${styles.map((style) => style.name).toList()})';
}

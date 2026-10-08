import 'nullable_value_getter.dart';
import 'text_side.dart';

/// 与排版无关的阅读锚点：读到了哪个块的哪一面的第几个字符。
///
/// 一个长段落会跨多屏 / 多页，只记块下标无法恢复到段内位置；
/// 而页码、滚动距离又会随字号与屏幕尺寸变化，所以用正文里的字符位置来记。
class ReadingAnchor {
  const ReadingAnchor({
    required this.blockIndex,
    required this.side,
    required this.textOffset,
  }) : assert(textOffset >= 0, 'textOffset 不能为负'),
       assert(side != null || textOffset == 0, '非文字块的 textOffset 必须为 0');

  /// 所在块在章内的下标。
  final int blockIndex;

  /// 锚点所在的那一面；非文字块为 null。
  final TextSide? side;

  /// 相对该面文字的字符偏移（UTF-16 码元）；[side] 为 null 时恒为 0。
  final int textOffset;

  ReadingAnchor copyWith({
    int? blockIndex,
    NullableValueGetter<TextSide>? side,
    int? textOffset,
  }) {
    return ReadingAnchor(
      blockIndex: blockIndex ?? this.blockIndex,
      side: side == null ? this.side : side(),
      textOffset: textOffset ?? this.textOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingAnchor &&
        other.blockIndex == blockIndex &&
        other.side == side &&
        other.textOffset == textOffset;
  }

  @override
  int get hashCode => Object.hash(blockIndex, side, textOffset);

  @override
  String toString() =>
      'ReadingAnchor(blockIndex: $blockIndex, side: ${side?.name}, '
      'textOffset: $textOffset)';
}

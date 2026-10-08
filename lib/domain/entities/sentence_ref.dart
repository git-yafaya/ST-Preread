import 'text_side.dart';

/// 章内一句话的定位。
class SentenceRef {
  const SentenceRef({
    required this.blockIndex,
    required this.side,
    required this.sentenceIndex,
  });

  /// 所在块在章内的下标。
  final int blockIndex;
  final TextSide side;

  /// 在该块这一面的句子列表中的下标。
  final int sentenceIndex;

  SentenceRef copyWith({int? blockIndex, TextSide? side, int? sentenceIndex}) {
    return SentenceRef(
      blockIndex: blockIndex ?? this.blockIndex,
      side: side ?? this.side,
      sentenceIndex: sentenceIndex ?? this.sentenceIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SentenceRef &&
        other.blockIndex == blockIndex &&
        other.side == side &&
        other.sentenceIndex == sentenceIndex;
  }

  @override
  int get hashCode => Object.hash(blockIndex, side, sentenceIndex);

  @override
  String toString() =>
      'SentenceRef(blockIndex: $blockIndex, side: ${side.name}, '
      'sentenceIndex: $sentenceIndex)';
}

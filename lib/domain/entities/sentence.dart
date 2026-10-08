import 'audio_clip.dart';
import 'nullable_value_getter.dart';

/// 一句话。
///
/// 用「在所属 SidedText.text 中的字符区间」表示，而不是另存一份文字，
/// 这样高亮与点句命中可以直接对着正文计算，不会出现两份文字对不上。
class Sentence {
  const Sentence({
    required this.startOffset,
    required this.endOffset,
    required this.audio,
  }) : assert(startOffset >= 0, 'startOffset 不能为负'),
       assert(endOffset > startOffset, '句子区间不能为空');

  /// 起始字符下标（含）。
  final int startOffset;

  /// 结束字符下标（不含）。
  final int endOffset;

  /// 为 null 表示这一句没有语音。
  final AudioClip? audio;

  int get length => endOffset - startOffset;

  bool get hasAudio => audio != null;

  Sentence copyWith({
    int? startOffset,
    int? endOffset,
    NullableValueGetter<AudioClip>? audio,
  }) {
    return Sentence(
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      audio: audio == null ? this.audio : audio(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Sentence &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.audio == audio;
  }

  @override
  int get hashCode => Object.hash(startOffset, endOffset, audio);

  @override
  String toString() =>
      'Sentence(startOffset: $startOffset, endOffset: $endOffset, '
      'hasAudio: $hasAudio)';
}

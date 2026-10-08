import 'list_equality.dart';
import 'sentence.dart';

/// 段落某一面的文字，以及这一面的句级切分。
class SidedText {
  const SidedText({required this.text, required this.sentences});

  final String text;

  /// 按出现顺序排列、互不重叠。空列表表示这一面没有句级数据（即没有语音）。
  final List<Sentence> sentences;

  SidedText copyWith({String? text, List<Sentence>? sentences}) {
    return SidedText(
      text: text ?? this.text,
      sentences: sentences ?? this.sentences,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SidedText &&
        other.text == text &&
        areListsEqual(other.sentences, sentences);
  }

  @override
  int get hashCode => Object.hash(text, Object.hashAll(sentences));

  @override
  String toString() =>
      'SidedText(length: ${text.length}, sentenceCount: ${sentences.length})';
}

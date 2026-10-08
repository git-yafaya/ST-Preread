import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  SidedText buildText() {
    return const SidedText(
      text: '第一句。第二句。',
      sentences: [
        Sentence(startOffset: 0, endOffset: 4, audio: null),
        Sentence(startOffset: 4, endOffset: 8, audio: null),
      ],
    );
  }

  group('SidedText', () {
    test('文字与句子列表逐项相同时相等且哈希一致', () {
      final first = buildText();
      final second = SidedText(
        text: first.text,
        sentences: List.of(first.sentences),
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('文字或句子不同则不相等', () {
      final text = buildText();
      expect(text.copyWith(text: '别的文字。别的文字'), isNot(text));
      expect(text.copyWith(sentences: const []), isNot(text));
      expect(
        text.copyWith(sentences: text.sentences.reversed.toList()),
        isNot(text),
      );
    });

    test('copyWith 只替换传入的字段', () {
      final withoutSentences = buildText().copyWith(sentences: const []);
      expect(withoutSentences.text, '第一句。第二句。');
      expect(withoutSentences.sentences, isEmpty);
      expect(buildText().copyWith(), buildText());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const boldSpan = InlineStyleSpan(
    startOffset: 0,
    endOffset: 3,
    styles: {InlineStyle.bold},
  );

  SidedText buildText() {
    return const SidedText(
      text: '第一句。第二句。',
      styleSpans: [boldSpan],
      sentences: [
        Sentence(startOffset: 0, endOffset: 4, audio: null),
        Sentence(startOffset: 4, endOffset: 8, audio: null),
      ],
    );
  }

  group('SidedText', () {
    test('文字、样式区间与句子列表逐项相同时相等且哈希一致', () {
      final first = buildText();
      final second = SidedText(
        text: first.text,
        styleSpans: List.of(first.styleSpans),
        sentences: List.of(first.sentences),
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('文字、样式区间或句子不同则不相等', () {
      final text = buildText();
      expect(text.copyWith(text: '别的文字。别的文字'), isNot(text));
      expect(text.copyWith(styleSpans: const []), isNot(text));
      expect(
        text.copyWith(
          styleSpans: [
            boldSpan.copyWith(styles: const {InlineStyle.italic}),
          ],
        ),
        isNot(text),
      );
      expect(text.copyWith(sentences: const []), isNot(text));
      expect(
        text.copyWith(sentences: text.sentences.reversed.toList()),
        isNot(text),
      );
    });

    test('copyWith 只替换传入的字段', () {
      final withoutSentences = buildText().copyWith(sentences: const []);
      expect(withoutSentences.text, '第一句。第二句。');
      expect(withoutSentences.styleSpans, [boldSpan]);
      expect(withoutSentences.sentences, isEmpty);

      final withoutStyles = buildText().copyWith(styleSpans: const []);
      expect(withoutStyles.styleSpans, isEmpty);
      expect(withoutStyles.sentences, hasLength(2));

      expect(buildText().copyWith(), buildText());
    });
  });
}

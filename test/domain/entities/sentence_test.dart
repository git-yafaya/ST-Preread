import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const audio = AudioClip(filePath: 'audio/a.mp3', start: null, end: null);
  const sentence = Sentence(startOffset: 2, endOffset: 9, audio: audio);

  group('Sentence', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameSentence = Sentence(startOffset: 2, endOffset: 9, audio: audio);
      expect(sentence, sameSentence);
      expect(sentence.hashCode, sameSentence.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(sentence.copyWith(startOffset: 3), isNot(sentence));
      expect(sentence.copyWith(endOffset: 10), isNot(sentence));
      expect(sentence.copyWith(audio: () => null), isNot(sentence));
    });

    test('length 为区间长度，hasAudio 反映是否带语音', () {
      expect(sentence.length, 7);
      expect(sentence.hasAudio, isTrue);
      expect(sentence.copyWith(audio: () => null).hasAudio, isFalse);
    });

    test('copyWith 不传参数时得到相等的副本', () {
      expect(sentence.copyWith(), sentence);
    });

    test('区间为空或起点为负时断言失败', () {
      expect(
        () => Sentence(startOffset: 4, endOffset: 4, audio: null),
        throwsAssertionError,
      );
      expect(
        () => Sentence(startOffset: -1, endOffset: 4, audio: null),
        throwsAssertionError,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const sentenceRef = SentenceRef(
    blockIndex: 3,
    side: TextSide.translation,
    sentenceIndex: 1,
  );

  group('SentenceRef', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameRef = SentenceRef(
        blockIndex: 3,
        side: TextSide.translation,
        sentenceIndex: 1,
      );
      expect(sentenceRef, sameRef);
      expect(sentenceRef.hashCode, sameRef.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(sentenceRef.copyWith(blockIndex: 4), isNot(sentenceRef));
      expect(sentenceRef.copyWith(side: TextSide.source), isNot(sentenceRef));
      expect(sentenceRef.copyWith(sentenceIndex: 2), isNot(sentenceRef));
    });

    test('copyWith 只替换传入的字段', () {
      final nextSentence = sentenceRef.copyWith(sentenceIndex: 2);
      expect(nextSentence.blockIndex, 3);
      expect(nextSentence.side, TextSide.translation);
      expect(nextSentence.sentenceIndex, 2);
      expect(sentenceRef.copyWith(), sentenceRef);
    });
  });
}

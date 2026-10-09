import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/features/reader/content/content.dart';

import '../support/reader_fixtures.dart';

void main() {
  // 「甲甲甲」[0,3) 无语音，「乙乙乙」[3,6) 带语音，间隙 [6,7)，「丙丙丙」[7,10) 带语音。
  final sentences = buildSidedText(const [
    FixtureSentence('甲甲甲'),
    FixtureSentence.voiced('乙乙乙', gapAfter: '　'),
    FixtureSentence.voiced('丙丙丙'),
  ]).sentences;

  group('findSentenceIndexAt', () {
    test('区间半开：起点属于这一句，终点属于下一句', () {
      expect(findSentenceIndexAt(sentences, 0), 0);
      expect(findSentenceIndexAt(sentences, 2), 0);
      expect(findSentenceIndexAt(sentences, 3), 1);
      expect(findSentenceIndexAt(sentences, 9), 2);
    });

    test('句间空隙与文字之外不属于任何句子', () {
      expect(findSentenceIndexAt(sentences, 6), isNull);
      expect(findSentenceIndexAt(sentences, 10), isNull);
      expect(findSentenceIndexAt(sentences, -1), isNull);
    });

    test('没有句级数据时找不到句子', () {
      expect(findSentenceIndexAt(const [], 0), isNull);
    });
  });

  group('findPlayableSentenceIndexInFragment', () {
    int? hit({
      required int fragmentStartOffset,
      required int offsetInFragment,
      int fragmentEndOffset = 10,
    }) {
      return findPlayableSentenceIndexInFragment(
        sentences: sentences,
        fragmentStartOffset: fragmentStartOffset,
        fragmentEndOffset: fragmentEndOffset,
        offsetInFragment: offsetInFragment,
      );
    }

    test('片段从头开始时，片段内偏移就是这一面的偏移', () {
      expect(hit(fragmentStartOffset: 0, offsetInFragment: 4), 1);
      expect(hit(fragmentStartOffset: 0, offsetInFragment: 8), 2);
    });

    test('片段是切片时，命中的偏移要加回片段起点', () {
      // 片段从偏移 5 切开：片段内的 0 是「乙乙乙」的最后一个字，3 是「丙丙丙」的第二个字。
      expect(hit(fragmentStartOffset: 5, offsetInFragment: 0), 1);
      expect(hit(fragmentStartOffset: 5, offsetInFragment: 3), 2);
    });

    test('点到无语音的句子不命中', () {
      expect(hit(fragmentStartOffset: 0, offsetInFragment: 1), isNull);
    });

    test('点到句间空隙不命中', () {
      expect(hit(fragmentStartOffset: 0, offsetInFragment: 6), isNull);
      expect(hit(fragmentStartOffset: 5, offsetInFragment: 1), isNull);
    });

    test('偏移落在片段之外不命中，即使那里有带语音的句子', () {
      expect(hit(fragmentStartOffset: 5, offsetInFragment: -1), isNull);
      expect(
        hit(fragmentStartOffset: 0, fragmentEndOffset: 5, offsetInFragment: 8),
        isNull,
      );
    });

    test('含 emoji 时按 UTF-16 码元换算', () {
      final emojiSentences = buildSidedText(const [
        FixtureSentence('😀😀'),
        FixtureSentence.voiced('好的'),
      ]).sentences;

      int? hitEmoji(int offsetInFragment) {
        return findPlayableSentenceIndexInFragment(
          sentences: emojiSentences,
          fragmentStartOffset: 2,
          fragmentEndOffset: 6,
          offsetInFragment: offsetInFragment,
        );
      }

      // 片段从第二个 emoji 切开：它占 2 个码元，之后才是带语音的句子。
      expect(hitEmoji(1), isNull);
      expect(hitEmoji(2), 1);
    });
  });
}

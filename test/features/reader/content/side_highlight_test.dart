import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';

void main() {
  const activeSentence = SentenceRef(
    blockIndex: 3,
    side: TextSide.translation,
    sentenceIndex: 2,
  );

  group('resolveSideHighlight', () {
    test('没有在播的句子时不高亮', () {
      expect(
        resolveSideHighlight(
          activeSentence: null,
          blockIndex: 3,
          side: TextSide.translation,
        ),
        const NoSideHighlight(),
      );
    });

    test('在播的句子在别的块里时不高亮', () {
      expect(
        resolveSideHighlight(
          activeSentence: activeSentence,
          blockIndex: 4,
          side: TextSide.translation,
        ),
        const NoSideHighlight(),
      );
    });

    test('在播的句子就在这一面时按句高亮', () {
      expect(
        resolveSideHighlight(
          activeSentence: activeSentence,
          blockIndex: 3,
          side: TextSide.translation,
        ),
        const ActiveSentenceHighlight(2),
      );
    });

    test('在播的句子在同一段的另一面时，这一面整段淡色高亮', () {
      expect(
        resolveSideHighlight(
          activeSentence: activeSentence,
          blockIndex: 3,
          side: TextSide.source,
        ),
        const CompanionSideHighlight(),
      );
    });
  });
}

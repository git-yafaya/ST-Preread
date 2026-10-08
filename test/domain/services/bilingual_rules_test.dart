import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

import '../../support/paragraph_fixtures.dart';

void main() {
  final bilingual = buildParagraphFixture(
    sourceAudio: [true],
    translationAudio: [true],
  );
  final translationOnly = buildParagraphFixture(translationAudio: [true]);
  final sourceOnly = buildParagraphFixture(sourceAudio: [true]);

  group('resolveDisplayedSides', () {
    test('对照显示：译文为主、原文为辅；单面段落显示它拥有的那一面', () {
      const displayMode = BilingualDisplayMode.both;

      expect(resolveDisplayedSides(bilingual, displayMode), [
        TextSide.translation,
        TextSide.source,
      ]);
      expect(resolveDisplayedSides(translationOnly, displayMode), [
        TextSide.translation,
      ]);
      expect(resolveDisplayedSides(sourceOnly, displayMode), [TextSide.source]);
    });

    test('只看译文：有译文就只显示译文，没有译文时回退到原文', () {
      const displayMode = BilingualDisplayMode.translationOnly;

      expect(resolveDisplayedSides(bilingual, displayMode), [
        TextSide.translation,
      ]);
      expect(resolveDisplayedSides(translationOnly, displayMode), [
        TextSide.translation,
      ]);
      expect(resolveDisplayedSides(sourceOnly, displayMode), [TextSide.source]);
    });

    test('只看原文：有原文就只显示原文，没有原文时回退到译文', () {
      const displayMode = BilingualDisplayMode.sourceOnly;

      expect(resolveDisplayedSides(bilingual, displayMode), [TextSide.source]);
      expect(resolveDisplayedSides(translationOnly, displayMode), [
        TextSide.translation,
      ]);
      expect(resolveDisplayedSides(sourceOnly, displayMode), [TextSide.source]);
    });

    test('任何显示方式下结果都不为空', () {
      for (final paragraph in [bilingual, translationOnly, sourceOnly]) {
        for (final displayMode in BilingualDisplayMode.values) {
          expect(resolveDisplayedSides(paragraph, displayMode), isNotEmpty);
        }
      }
    });

    test('块级样式不影响显示哪几面', () {
      for (final style in ParagraphStyle.values) {
        final styledBilingual = buildParagraphFixture(
          style: style,
          sourceAudio: [true],
          translationAudio: [true],
        );

        expect(
          resolveDisplayedSides(styledBilingual, BilingualDisplayMode.both),
          [TextSide.translation, TextSide.source],
        );
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';

import '../support/reader_fixtures.dart';
import '../support/text_layout_probes.dart';

void main() {
  const blockIndex = 4;

  final source = buildSidedText(const [
    FixtureSentence('地の文。'),
    FixtureSentence.voiced('「台詞」'),
  ]);
  final translation = buildSidedText(const [
    FixtureSentence('旁白。'),
    FixtureSentence.voiced('“对白。”'),
  ]);
  final bilingualParagraph = buildParagraph(
    source: source,
    translation: translation,
  );

  late ReaderTextTheme textTheme;
  late List<SentenceRef> tappedSentences;

  setUp(() {
    tappedSentences = [];
  });

  Future<void> pumpParagraph(
    WidgetTester tester, {
    required ParagraphBlock paragraph,
    BilingualDisplayMode displayMode = BilingualDisplayMode.both,
    SentenceRef? activeSentence,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              textTheme = ReaderTextTheme.fromTheme(
                Theme.of(context),
                fontScale: 1,
              );
              return ParagraphBlockView(
                paragraph: paragraph,
                blockIndex: blockIndex,
                displayMode: displayMode,
                textTheme: textTheme,
                activeSentence: activeSentence,
                onSentenceTap: tappedSentences.add,
              );
            },
          ),
        ),
      ),
    );
  }

  List<TextFragmentView> fragmentsOf(WidgetTester tester) {
    return tester
        .widgetList<TextFragmentView>(find.byType(TextFragmentView))
        .toList();
  }

  group('三种显示方式', () {
    testWidgets('对照显示：译文为主文在上，原文为辅文在下', (tester) async {
      await pumpParagraph(tester, paragraph: bilingualParagraph);

      final fragments = fragmentsOf(tester);
      expect(fragments.map((fragment) => fragment.side), [
        TextSide.translation,
        TextSide.source,
      ]);
      expect(fragments.map((fragment) => fragment.role), [
        TextRole.primary,
        TextRole.secondary,
      ]);
      expect(
        tester.getTopLeft(findFragmentOf(translation)).dy,
        lessThan(tester.getTopLeft(findFragmentOf(source)).dy),
      );
    });

    testWidgets('对照显示时辅文的字号更小、颜色更淡', (tester) async {
      await pumpParagraph(tester, paragraph: bilingualParagraph);

      final primaryStyle = paragraphOf(
        tester,
        findFragmentOf(translation),
      ).text.style!;
      final secondaryStyle = paragraphOf(
        tester,
        findFragmentOf(source),
      ).text.style!;

      expect(secondaryStyle.fontSize, lessThan(primaryStyle.fontSize!));
      expect(secondaryStyle.color!.a, lessThan(primaryStyle.color!.a));
    });

    testWidgets('只看译文：只有译文，且作为主文', (tester) async {
      await pumpParagraph(
        tester,
        paragraph: bilingualParagraph,
        displayMode: BilingualDisplayMode.translationOnly,
      );

      final fragment = fragmentsOf(tester).single;
      expect(fragment.side, TextSide.translation);
      expect(fragment.role, TextRole.primary);
    });

    testWidgets('只看原文：只有原文，且作为主文', (tester) async {
      await pumpParagraph(
        tester,
        paragraph: bilingualParagraph,
        displayMode: BilingualDisplayMode.sourceOnly,
      );

      final fragment = fragmentsOf(tester).single;
      expect(fragment.side, TextSide.source);
      expect(fragment.role, TextRole.primary);
    });

    testWidgets('段落只有原文时，只看译文也显示原文', (tester) async {
      await pumpParagraph(
        tester,
        paragraph: buildParagraph(source: source),
        displayMode: BilingualDisplayMode.translationOnly,
      );

      final fragment = fragmentsOf(tester).single;
      expect(fragment.side, TextSide.source);
      expect(fragment.role, TextRole.primary);
    });
  });

  group('播放高亮', () {
    testWidgets('被播的句子按句高亮，另一面整段淡色高亮', (tester) async {
      await pumpParagraph(
        tester,
        paragraph: bilingualParagraph,
        activeSentence: const SentenceRef(
          blockIndex: blockIndex,
          side: TextSide.translation,
          sentenceIndex: 1,
        ),
      );

      final translationSpans = segmentSpansOf(
        tester,
        findFragmentOf(translation),
      );
      final sourceSpans = segmentSpansOf(tester, findFragmentOf(source));

      expect(translationSpans[0].style, isNull);
      expect(
        translationSpans[1].style!.backgroundColor,
        textTheme.activeSentenceHighlightColor,
      );
      expect(
        sourceSpans.map((span) => span.style!.backgroundColor),
        everyElement(textTheme.companionHighlightColor),
      );
      expect(sourceSpans.map((span) => span.text).join(), source.text);
    });

    testWidgets('被播的句子在别的块里时本段不高亮', (tester) async {
      await pumpParagraph(
        tester,
        paragraph: bilingualParagraph,
        activeSentence: const SentenceRef(
          blockIndex: blockIndex + 1,
          side: TextSide.translation,
          sentenceIndex: 1,
        ),
      );

      final spans = [
        ...segmentSpansOf(tester, findFragmentOf(translation)),
        ...segmentSpansOf(tester, findFragmentOf(source)),
      ];

      expect(
        spans.map((span) => span.style?.backgroundColor),
        everyElement(isNull),
      );
    });
  });

  group('点句', () {
    testWidgets('点主文里带语音的句子，回调带上块下标、面与句子下标', (tester) async {
      await pumpParagraph(tester, paragraph: bilingualParagraph);

      await tapSentence(tester, translation, 1);

      expect(tappedSentences, [
        const SentenceRef(
          blockIndex: blockIndex,
          side: TextSide.translation,
          sentenceIndex: 1,
        ),
      ]);
    });

    testWidgets('辅文里带语音的句子同样可以点', (tester) async {
      await pumpParagraph(tester, paragraph: bilingualParagraph);

      await tapSentence(tester, source, 1);

      expect(tappedSentences, [
        const SentenceRef(
          blockIndex: blockIndex,
          side: TextSide.source,
          sentenceIndex: 1,
        ),
      ]);
    });

    testWidgets('点无语音的句子不回调', (tester) async {
      await pumpParagraph(tester, paragraph: bilingualParagraph);

      await tapSentence(tester, translation, 0);
      await tapSentence(tester, source, 0);

      expect(tappedSentences, isEmpty);
    });
  });

  group('块级样式', () {
    Finder findQuoteBar() {
      return find.descendant(
        of: find.byType(ParagraphFrame),
        matching: find.byType(DecoratedBox),
      );
    }

    testWidgets('引用段左侧有竖线，文字相应缩进', (tester) async {
      await pumpParagraph(
        tester,
        paragraph: buildParagraph(
          style: ParagraphStyle.quote,
          translation: translation,
        ),
      );

      expect(findQuoteBar(), findsOneWidget);
      expect(
        tester.getTopLeft(findFragmentOf(translation)).dx -
            tester.getTopLeft(find.byType(ParagraphFrame)).dx,
        ParagraphFrame.horizontalInsetOf(ParagraphStyle.quote),
      );
    });

    testWidgets('普通段落没有竖线也不缩进', (tester) async {
      await pumpParagraph(tester, paragraph: bilingualParagraph);

      expect(findQuoteBar(), findsNothing);
      expect(ParagraphFrame.horizontalInsetOf(ParagraphStyle.body), 0);
    });

    testWidgets('标题的字号比正文大', (tester) async {
      await pumpParagraph(
        tester,
        paragraph: buildParagraph(
          style: ParagraphStyle.heading1,
          translation: translation,
        ),
      );

      expect(
        paragraphOf(tester, findFragmentOf(translation)).text.style!.fontSize,
        greaterThan(textTheme.bodyFontSize),
      );
    });
  });
}

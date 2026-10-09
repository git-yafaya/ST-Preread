import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';

import '../support/reader_fixtures.dart';
import '../support/text_layout_probes.dart';

void main() {
  const fragmentWidth = 300.0;
  final fragmentFinder = find.byType(TextFragmentView);

  late ReaderTextTheme textTheme;
  late List<int> tappedSentenceIndexes;
  late int outerTapCount;

  setUp(() {
    tappedSentenceIndexes = [];
    outerTapCount = 0;
  });

  /// 把片段放在一个固定宽度、外层带点击手势的区域里。
  Future<void> pumpFragment(
    WidgetTester tester, {
    required SidedText sidedText,
    int startOffset = 0,
    int? endOffset,
    SideHighlight highlight = const NoSideHighlight(),
    TextRole role = TextRole.primary,
    bool isTappable = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => outerTapCount++,
              child: SizedBox(
                width: fragmentWidth,
                child: Builder(
                  builder: (context) {
                    textTheme = ReaderTextTheme.fromTheme(
                      Theme.of(context),
                      fontScale: 1,
                    );
                    return TextFragmentView(
                      sidedText: sidedText,
                      side: TextSide.translation,
                      textTheme: textTheme,
                      paragraphStyle: ParagraphStyle.body,
                      role: role,
                      highlight: highlight,
                      onSentenceTap: isTappable
                          ? tappedSentenceIndexes.add
                          : null,
                      startOffset: startOffset,
                      endOffset: endOffset,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapCharacter(WidgetTester tester, int offsetInFragment) async {
    await tester.tapAt(
      globalCenterOfCharacter(tester, fragmentFinder, offsetInFragment),
    );
    await tester.pump();
  }

  RenderTextFragment renderFragment(WidgetTester tester) {
    return tester.renderObject<RenderTextFragment>(fragmentFinder);
  }

  // 「旁白。」[0,3) 无语音；「对白！」[3,6) 带语音；间隙 [6,7)；「再说。」[7,10) 带语音。
  final mixedText = buildSidedText(const [
    FixtureSentence('旁白。'),
    FixtureSentence.voiced('对白！', gapAfter: '　'),
    FixtureSentence.voiced('再说。'),
  ]);

  group('渲染', () {
    testWidgets('默认渲染整面文字', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);

      expect(
        paragraphOf(tester, fragmentFinder).text.toPlainText(),
        mixedText.text,
      );
    });

    testWidgets('指定字符区间时只渲染这一段', (tester) async {
      await pumpFragment(
        tester,
        sidedText: mixedText,
        startOffset: 2,
        endOffset: 8,
      );

      expect(
        paragraphOf(tester, fragmentFinder).text.toPlainText(),
        mixedText.text.substring(2, 8),
      );
    });

    testWidgets('带语音的句子有下划线，无语音的句子与句间空隙没有', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);

      final spans = segmentSpansOf(tester, fragmentFinder);

      expect(spans.map((span) => span.text), ['旁白。', '对白！', '　', '再说。']);
      expect(spans[0].style, isNull);
      expect(spans[1].style!.decoration, TextDecoration.underline);
      expect(spans[2].style, isNull);
      expect(spans[3].style!.decoration, TextDecoration.underline);
    });

    testWidgets('被播的句子带高亮底色，其余句子没有', (tester) async {
      await pumpFragment(
        tester,
        sidedText: mixedText,
        highlight: const ActiveSentenceHighlight(1),
      );

      final spans = segmentSpansOf(tester, fragmentFinder);

      expect(
        spans[1].style!.backgroundColor,
        textTheme.activeSentenceHighlightColor,
      );
      expect(spans[3].style!.backgroundColor, isNull);
    });

    testWidgets('辅文的字号比主文小', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);
      final primaryFontSize = paragraphOf(
        tester,
        fragmentFinder,
      ).text.style!.fontSize!;

      await pumpFragment(
        tester,
        sidedText: mixedText,
        role: TextRole.secondary,
      );
      final secondaryFontSize = paragraphOf(
        tester,
        fragmentFinder,
      ).text.style!.fontSize!;

      expect(secondaryFontSize, lessThan(primaryFontSize));
    });
  });

  group('点句命中', () {
    testWidgets('点带语音的句子回调它的句子下标', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);

      await tapCharacter(tester, 4);
      await tapCharacter(tester, 9);

      expect(tappedSentenceIndexes, [1, 2]);
    });

    testWidgets('点无语音的句子不回调', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);

      await tapCharacter(tester, 1);

      expect(tappedSentenceIndexes, isEmpty);
    });

    testWidgets('点句间空隙不回调', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);

      await tapCharacter(tester, 6);

      expect(tappedSentenceIndexes, isEmpty);
    });

    testWidgets('点在行尾之后的留白上不回调，即使最后一句带语音', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);
      final fragmentRect = tester.getRect(fragmentFinder);
      final lastCharacterBox = characterBoxOf(tester, fragmentFinder, 9);

      // 文字不足一行，片段右侧是留白。
      expect(lastCharacterBox.right, lessThan(fragmentWidth - 20));
      await tester.tapAt(fragmentRect.centerRight - const Offset(10, 0));
      await tester.pump();

      expect(tappedSentenceIndexes, isEmpty);
    });

    testWidgets('片段是切片时，回调的仍是句子在整面文字里的下标', (tester) async {
      // 从偏移 5 切开：片段内第 0 个字符是「对白！」的最后一个字，第 2 个是「再说。」的第一个字。
      await pumpFragment(tester, sidedText: mixedText, startOffset: 5);

      await tapCharacter(tester, 0);
      await tapCharacter(tester, 2);

      expect(tappedSentenceIndexes, [1, 2]);
    });

    testWidgets('切片里点到句间空隙同样不回调', (tester) async {
      await pumpFragment(tester, sidedText: mixedText, startOffset: 5);

      await tapCharacter(tester, 1);

      expect(tappedSentenceIndexes, isEmpty);
    });

    testWidgets('句子前面有 emoji 时仍然命中正确的句子', (tester) async {
      final emojiText = buildSidedText(const [
        FixtureSentence('😀😀'),
        FixtureSentence.voiced('好的。'),
        FixtureSentence('嗯。'),
      ]);
      await pumpFragment(tester, sidedText: emojiText);

      // 两个 emoji 各占 2 个码元，带语音的句子从偏移 4 开始。
      await tapCharacter(tester, 0);
      await tapCharacter(tester, 4);
      await tapCharacter(tester, 7);

      expect(tappedSentenceIndexes, [1]);
    });

    testWidgets('点到带语音的句子时不会再触发外层的点击', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);

      await tapCharacter(tester, 4);

      expect(tappedSentenceIndexes, [1]);
      expect(outerTapCount, 0);
    });

    testWidgets('点不到带语音的句子时把点击让给外层', (tester) async {
      await pumpFragment(tester, sidedText: mixedText);

      await tapCharacter(tester, 1);

      expect(outerTapCount, 1);
    });

    testWidgets('不提供回调时片段不响应点击', (tester) async {
      await pumpFragment(tester, sidedText: mixedText, isTappable: false);

      await tapCharacter(tester, 4);

      expect(tappedSentenceIndexes, isEmpty);
      expect(outerTapCount, 1);
    });
  });

  group('行级定位', () {
    final wrappedText = buildLongSidedText(character: '字', length: 120);

    /// 第二行第一个字符在片段内的偏移，直接从文本布局量出来。
    int measureCharactersPerLine(WidgetTester tester) {
      final firstLineTop = characterBoxOf(tester, fragmentFinder, 0).top;
      var offset = 0;
      while (characterBoxOf(tester, fragmentFinder, offset).top ==
          firstLineTop) {
        offset++;
      }
      return offset;
    }

    testWidgets('按纵坐标取到所在行的行首偏移', (tester) async {
      await pumpFragment(tester, sidedText: wrappedText);
      final charactersPerLine = measureCharactersPerLine(tester);
      final thirdLineBox = characterBoxOf(
        tester,
        fragmentFinder,
        charactersPerLine * 2,
      );

      final fragment = renderFragment(tester);

      expect(charactersPerLine, greaterThan(1));
      expect(fragment.lineStartOffsetAt(0), 0);
      expect(
        fragment.lineStartOffsetAt(thirdLineBox.center.dy),
        charactersPerLine * 2,
      );
    });

    testWidgets('按偏移取到所在行的行顶', (tester) async {
      await pumpFragment(tester, sidedText: wrappedText);
      final charactersPerLine = measureCharactersPerLine(tester);
      final thirdLineBox = characterBoxOf(
        tester,
        fragmentFinder,
        charactersPerLine * 2,
      );

      final fragment = renderFragment(tester);

      expect(
        fragment.lineTopOf(0),
        characterBoxOf(tester, fragmentFinder, 0).top,
      );
      expect(fragment.lineTopOf(charactersPerLine * 2 + 3), thirdLineBox.top);
      expect(
        thirdLineBox.top,
        greaterThan(characterBoxOf(tester, fragmentFinder, 0).top),
      );
    });

    testWidgets('片段是切片时，偏移换算要算上片段起点', (tester) async {
      const sliceStart = 7;
      await pumpFragment(
        tester,
        sidedText: wrappedText,
        startOffset: sliceStart,
      );
      final charactersPerLine = measureCharactersPerLine(tester);
      final secondLineBox = characterBoxOf(
        tester,
        fragmentFinder,
        charactersPerLine,
      );

      final fragment = renderFragment(tester);

      expect(
        fragment.lineStartOffsetAt(secondLineBox.center.dy),
        sliceStart + charactersPerLine,
      );
      expect(
        fragment.lineTopOf(sliceStart + charactersPerLine + 1),
        secondLineBox.top,
      );
    });

    testWidgets('偏移或纵坐标超出片段时取最近的一端', (tester) async {
      await pumpFragment(tester, sidedText: wrappedText, endOffset: 60);
      final lastCharacterBox = characterBoxOf(tester, fragmentFinder, 59);

      final fragment = renderFragment(tester);

      expect(fragment.lineTopOf(9999), lastCharacterBox.top);
      expect(fragment.lineStartOffsetAt(-50), 0);
    });

    testWidgets('偏移落在 emoji 的后半个码元上时，仍取到它所在行的行顶', (tester) async {
      // 把 emoji 挤到第二行：章末锚点取「文字长度减 1」，末尾是 emoji 时就落在这里。
      await pumpFragment(tester, sidedText: wrappedText);
      final charactersPerLine = measureCharactersPerLine(tester);
      final emojiText = buildPlainSidedText('${'字' * charactersPerLine}😀');
      await pumpFragment(tester, sidedText: emojiText);
      final emojiBox = characterBoxOf(
        tester,
        fragmentFinder,
        charactersPerLine,
      );

      final fragment = renderFragment(tester);

      expect(emojiBox.top, greaterThan(1));
      expect(fragment.lineTopOf(emojiText.text.length - 1), emojiBox.top);
    });

    testWidgets('空文字的片段定位在自身开头，不报错', (tester) async {
      await pumpFragment(tester, sidedText: buildPlainSidedText(''));

      final fragment = renderFragment(tester);

      expect(fragment.lineTopOf(0), 0);
      expect(fragment.lineStartOffsetAt(10), 0);
    });
  });

  group('candidateCodeUnitOffsets', () {
    test('下游亲和时优先取光标之后的字符', () {
      expect(candidateCodeUnitOffsets(const TextPosition(offset: 5)), [5, 4]);
    });

    test('上游亲和时优先取光标之前的字符', () {
      expect(
        candidateCodeUnitOffsets(
          const TextPosition(offset: 5, affinity: TextAffinity.upstream),
        ),
        [4, 5],
      );
    });
  });

  group('collectTextFragments', () {
    testWidgets('按显示顺序收集子树里的全部片段', (tester) async {
      final first = buildPlainSidedText('第一面');
      final second = buildPlainSidedText('第二面');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final theme = ReaderTextTheme.fromTheme(
                  Theme.of(context),
                  fontScale: 1,
                );
                return Column(
                  key: const Key('root'),
                  children: [
                    for (final (sidedText, side) in [
                      (first, TextSide.translation),
                      (second, TextSide.source),
                    ])
                      TextFragmentView(
                        sidedText: sidedText,
                        side: side,
                        textTheme: theme,
                        paragraphStyle: ParagraphStyle.body,
                        role: TextRole.primary,
                        highlight: const NoSideHighlight(),
                        onSentenceTap: null,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final fragments = collectTextFragments(
        tester.renderObject(find.byKey(const Key('root'))),
      );

      expect(fragments.map((fragment) => fragment.side), [
        TextSide.translation,
        TextSide.source,
      ]);
    });
  });
}

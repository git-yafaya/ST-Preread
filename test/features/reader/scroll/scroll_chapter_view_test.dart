import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_layout_constants.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/constants/reader_strings.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/data/mock/mock_reader_settings_repository.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';
import 'package:st_preread/features/reader/logic/chapter_anchors.dart';
import 'package:st_preread/features/reader/scroll/scroll_chapter_view.dart';

import '../support/reader_fixtures.dart';
import '../support/text_layout_probes.dart';

void main() {
  /// 位置比较的容差：行顶与视口顶部之间允许有不到一个像素的舍入误差。
  const positionTolerance = 1.0;
  const longTextLength = 1500;
  const midParagraphOffset = 700;

  // 块 0：带语音句子的短段落；块 1：分隔线；块 2：两面都超过一屏的长段落；块 3：只有译文的短段落。
  final openingTranslation = buildSidedText(const [
    FixtureSentence('旁白。'),
    FixtureSentence.voiced('“对白。”'),
  ]);
  final openingSource = buildPlainSidedText('地の文。「台詞」');
  final longTranslation = buildLongSidedText(
    character: '译',
    length: longTextLength,
  );
  // 辅文字小、每行字多，要更长才能保证锚点之后还剩下不止一屏。
  final longSource = buildLongSidedText(
    character: '原',
    length: longTextLength * 2,
  );
  final closingTranslation = buildPlainSidedText('最后一段。');
  const longBlockIndex = 2;
  final longChapter = buildChapter(
    index: 1,
    blocks: [
      buildParagraph(
        id: 'opening',
        source: openingSource,
        translation: openingTranslation,
      ),
      const DividerBlock(id: 'divider'),
      buildParagraph(
        id: 'long',
        source: longSource,
        translation: longTranslation,
      ),
      buildParagraph(id: 'closing', translation: closingTranslation),
    ],
  );
  final shortChapter = buildChapter(
    index: 0,
    blocks: [buildParagraph(translation: buildPlainSidedText('只有一小段。'))],
  );

  const midTranslationAnchor = ReadingAnchor(
    blockIndex: longBlockIndex,
    side: TextSide.translation,
    textOffset: midParagraphOffset,
  );
  const midSourceAnchor = ReadingAnchor(
    blockIndex: longBlockIndex,
    side: TextSide.source,
    textOffset: midParagraphOffset,
  );

  late MockReaderSettingsRepository settingsRepository;
  late List<ReadingAnchor> reportedAnchors;
  late List<SentenceRef> tappedSentences;
  late int previousChapterRequestCount;
  late int nextChapterRequestCount;

  setUp(() {
    settingsRepository = MockReaderSettingsRepository(
      initialSettings: defaultReaderSettings,
    );
    addTearDown(settingsRepository.dispose);
    reportedAnchors = [];
    tappedSentences = [];
    previousChapterRequestCount = 0;
    nextChapterRequestCount = 0;
  });

  /// 渲染视图并等它完成定位。再次调用时沿用同一棵组件树，相当于父组件改了参数。
  Future<void> pumpView(
    WidgetTester tester, {
    required Chapter chapter,
    BilingualDisplayMode displayMode = BilingualDisplayMode.both,
    ReadingAnchor initialAnchor = chapterStartAnchor,
    SentenceRef? activeSentence,
    bool hasPreviousChapter = false,
    bool hasNextChapter = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ScrollChapterView(
              chapter: chapter,
              displayMode: displayMode,
              initialAnchor: initialAnchor,
              activeSentence: activeSentence,
              onAnchorChanged: reportedAnchors.add,
              onSentenceTap: tappedSentences.add,
              onPreviousChapterRequested: hasPreviousChapter
                  ? () => previousChapterRequestCount++
                  : null,
              onNextChapterRequested: hasNextChapter
                  ? () => nextChapterRequestCount++
                  : null,
            ),
          ),
        ),
      ),
    );
    // 定位发生在排版之后，要再过一帧内容才按新位置画出来。
    await tester.pumpAndSettle();
  }

  /// 视口顶部当前的锚点。初始锚点恰好就是行首时视图不会再回报，此时它就是当前锚点。
  ReadingAnchor latestAnchorOr(ReadingAnchor initialAnchor) {
    return reportedAnchors.isEmpty ? initialAnchor : reportedAnchors.last;
  }

  double viewportTop(WidgetTester tester) {
    return tester.getTopLeft(find.byType(ScrollChapterView)).dy;
  }

  ScrollPosition scrollPosition(WidgetTester tester) {
    return tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ScrollChapterView),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
  }

  Future<void> scrollTo(WidgetTester tester, double pixels) async {
    scrollPosition(tester).jumpTo(pixels);
    await tester.pump();
  }

  Finder findBlock(int blockIndex) {
    return find.byWidgetPredicate(
      (widget) => widget is ContentBlockView && widget.blockIndex == blockIndex,
    );
  }

  /// 断言 [sidedText] 第 [textOffset] 个字符所在的那一行正好在视口顶部。
  void expectLineAtViewportTop(
    WidgetTester tester,
    SidedText sidedText,
    int textOffset,
  ) {
    expect(
      globalLineTopOf(tester, findFragmentOf(sidedText), textOffset),
      closeTo(viewportTop(tester), positionTolerance),
    );
  }

  /// 断言第 [blockIndex] 个块的开头在视口顶部（上方只留出定位留白）。
  void expectBlockStartAtViewportTop(WidgetTester tester, int blockIndex) {
    expect(
      tester.getTopLeft(findBlock(blockIndex)).dy,
      closeTo(
        viewportTop(tester) + ReaderLayoutConstants.blockStartLeadingMargin,
        positionTolerance,
      ),
    );
  }

  group('按锚点定位', () {
    testWidgets('章首锚点停在最上方', (tester) async {
      await pumpView(tester, chapter: longChapter);

      expect(scrollPosition(tester).pixels, 0);
    });

    testWidgets('能定位到长段落内部：锚点所在的那一行对到视口顶部', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );

      expect(scrollPosition(tester).pixels, greaterThan(0));
      expectLineAtViewportTop(tester, longTranslation, midParagraphOffset);
    });

    testWidgets('锚点在辅文一面时定位到辅文里的那一行', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midSourceAnchor,
      );

      expectLineAtViewportTop(tester, longSource, midParagraphOffset);
    });

    testWidgets('锚点没有指明哪一面时定位到块的开头', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: const ReadingAnchor(
          blockIndex: longBlockIndex,
          side: null,
          textOffset: 0,
        ),
      );

      expectBlockStartAtViewportTop(tester, longBlockIndex);
    });

    testWidgets('锚点所指的面当前不显示时退到块的开头', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        displayMode: BilingualDisplayMode.translationOnly,
        initialAnchor: midSourceAnchor,
      );

      expect(findFragmentOf(longSource), findsNothing);
      expectBlockStartAtViewportTop(tester, longBlockIndex);
    });

    testWidgets('章末锚点超出可滚动范围时停在末尾，不报错', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: resolveChapterEndAnchor(
          longChapter,
          BilingualDisplayMode.both,
        ),
      );

      final position = scrollPosition(tester);
      expect(position.pixels, position.maxScrollExtent);
      expect(position.maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('锚点的块下标不在本章范围内时不报错', (tester) async {
      await pumpView(
        tester,
        chapter: shortChapter,
        initialAnchor: const ReadingAnchor(
          blockIndex: 42,
          side: TextSide.translation,
          textOffset: 99,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ContentBlockView), findsOneWidget);
    });

    testWidgets('没有任何块的章节也能显示换章入口', (tester) async {
      await pumpView(
        tester,
        chapter: buildChapter(index: 0, blocks: const []),
        hasNextChapter: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(ReaderStrings.nextChapter), findsOneWidget);
    });
  });

  group('回报锚点', () {
    testWidgets('定位完成后回报视口顶部的实际锚点：章首是第一个块主文的开头', (tester) async {
      await pumpView(tester, chapter: longChapter);

      expect(reportedAnchors, [
        const ReadingAnchor(
          blockIndex: 0,
          side: TextSide.translation,
          textOffset: 0,
        ),
      ]);
    });

    testWidgets('滚到长段落内部时，锚点是视口顶部那一行的行首', (tester) async {
      await pumpView(tester, chapter: longChapter);
      final longParagraphTop =
          tester.getTopLeft(findFragmentOf(longTranslation)).dy -
          viewportTop(tester);

      await scrollTo(tester, longParagraphTop + 400);

      final anchor = reportedAnchors.last;
      expect(anchor.blockIndex, longBlockIndex);
      expect(anchor.side, TextSide.translation);
      expect(anchor.textOffset, greaterThan(0));
      final fragment = findFragmentOf(longTranslation);
      final lineTop = globalLineTopOf(tester, fragment, anchor.textOffset);
      final previousLineTop = globalLineTopOf(
        tester,
        fragment,
        anchor.textOffset - 1,
      );
      // 这一行跨着视口顶部，且偏移正是行首（前一个字符在上一行）。
      expect(lineTop, lessThanOrEqualTo(viewportTop(tester) + 1));
      expect(previousLineTop, lessThan(lineTop));
      expect(
        characterBoxOf(tester, fragment, anchor.textOffset).height,
        greaterThan(viewportTop(tester) - lineTop),
      );
    });

    testWidgets('回报的锚点再拿来定位，能回到同一行', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );
      final reportedAnchor = latestAnchorOr(midTranslationAnchor);
      final pixelsAfterFirstPositioning = scrollPosition(tester).pixels;

      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: reportedAnchor,
      );

      expect(reportedAnchor.side, TextSide.translation);
      expect(reportedAnchor.textOffset, lessThanOrEqualTo(midParagraphOffset));
      expect(
        scrollPosition(tester).pixels,
        closeTo(pixelsAfterFirstPositioning, positionTolerance),
      );
    });

    testWidgets('视口顶部落在辅文里时，锚点记的是辅文那一面', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midSourceAnchor,
      );

      // 再往下滚几行，保证回报的是滚动之后的位置。
      await scrollTo(tester, scrollPosition(tester).pixels + 100);

      expect(reportedAnchors.last.side, TextSide.source);
      expect(reportedAnchors.last.blockIndex, longBlockIndex);
      expect(reportedAnchors.last.textOffset, greaterThan(midParagraphOffset));
    });

    testWidgets('视口顶部是非文字块时，锚点是这个块的开头', (tester) async {
      await pumpView(tester, chapter: longChapter);
      final dividerTop =
          tester.getTopLeft(findBlock(1)).dy - viewportTop(tester);

      await scrollTo(tester, dividerTop);

      expect(
        reportedAnchors.last,
        const ReadingAnchor(blockIndex: 1, side: null, textOffset: 0),
      );
    });

    testWidgets('在同一行之内滚动不重复回报', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );
      final pixels = scrollPosition(tester).pixels;
      final reportCountBefore = reportedAnchors.length;

      await scrollTo(tester, pixels + 2);
      await scrollTo(tester, pixels + 4);
      await scrollTo(tester, pixels + 6);

      expect(reportedAnchors, hasLength(reportCountBefore));
    });

    testWidgets('滚过多行时每换一行回报一次，相邻两次不重复', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );
      final pixels = scrollPosition(tester).pixels;
      reportedAnchors.clear();

      for (var step = 1; step <= 30; step++) {
        await scrollTo(tester, pixels + step * 5);
      }

      expect(reportedAnchors.length, inInclusiveRange(2, 29));
      for (var index = 1; index < reportedAnchors.length; index++) {
        expect(reportedAnchors[index], isNot(reportedAnchors[index - 1]));
      }
    });

    testWidgets('章首有「上一章」入口时，入口不会成为锚点', (tester) async {
      await pumpView(tester, chapter: longChapter, hasPreviousChapter: true);

      await scrollTo(tester, 0);

      expect(
        reportedAnchors.map((anchor) => anchor.blockIndex),
        everyElement(0),
      );
    });
  });

  group('保持阅读位置', () {
    testWidgets('显示方式变化后，仍停在变化前的那一行', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );
      final anchorBeforeChange = latestAnchorOr(midTranslationAnchor);
      final pixelsBeforeChange = scrollPosition(tester).pixels;

      await pumpView(
        tester,
        chapter: longChapter,
        displayMode: BilingualDisplayMode.translationOnly,
        initialAnchor: midTranslationAnchor,
      );

      expectLineAtViewportTop(
        tester,
        longTranslation,
        anchorBeforeChange.textOffset,
      );
      expect(scrollPosition(tester).pixels, isNot(pixelsBeforeChange));
    });

    testWidgets('显示方式变化使锚点所在的面消失时，退到那个块的开头', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midSourceAnchor,
      );

      await pumpView(
        tester,
        chapter: longChapter,
        displayMode: BilingualDisplayMode.translationOnly,
        initialAnchor: midSourceAnchor,
      );

      expectBlockStartAtViewportTop(tester, longBlockIndex);
    });

    testWidgets('字号变化后，仍停在变化前的那一行', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );
      final anchorBeforeChange = latestAnchorOr(midTranslationAnchor);
      final fontSizeBeforeChange = paragraphOf(
        tester,
        findFragmentOf(longTranslation),
      ).text.style!.fontSize!;

      await settingsRepository.saveSettings(
        defaultReaderSettings.copyWith(fontScale: 1.5),
      );
      await tester.pumpAndSettle();

      expect(
        paragraphOf(
          tester,
          findFragmentOf(longTranslation),
        ).text.style!.fontSize,
        fontSizeBeforeChange * 1.5,
      );
      expectLineAtViewportTop(
        tester,
        longTranslation,
        anchorBeforeChange.textOffset,
      );
    });

    testWidgets('可用宽度变化后，仍停在变化前的那一行', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );
      final anchorBeforeChange = latestAnchorOr(midTranslationAnchor);

      await tester.binding.setSurfaceSize(const Size(480, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpAndSettle();

      expectLineAtViewportTop(
        tester,
        longTranslation,
        anchorBeforeChange.textOffset,
      );
    });
  });

  group('重新定位', () {
    testWidgets('initialAnchor 变化时按新锚点定位', (tester) async {
      await pumpView(tester, chapter: longChapter);

      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );

      expectLineAtViewportTop(tester, longTranslation, midParagraphOffset);
    });

    testWidgets('换了章节时按新章的锚点定位，不沿用旧章的滚动位置', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        initialAnchor: midTranslationAnchor,
      );
      final anotherLongTranslation = buildLongSidedText(
        character: '新',
        length: longTextLength,
      );
      final anotherChapter = buildChapter(
        index: 2,
        blocks: [buildParagraph(translation: anotherLongTranslation)],
      );

      await pumpView(tester, chapter: anotherChapter);

      expect(scrollPosition(tester).pixels, 0);
      expect(findFragmentOf(anotherLongTranslation), findsOneWidget);
      expect(findFragmentOf(longTranslation), findsNothing);
    });
  });

  group('换章入口', () {
    testWidgets('没有上一章时不显示「上一章」入口', (tester) async {
      await pumpView(tester, chapter: shortChapter);

      expect(find.text(ReaderStrings.previousChapter), findsNothing);
    });

    testWidgets('有上一章时入口在第一个块之前，点击发出请求', (tester) async {
      await pumpView(tester, chapter: shortChapter, hasPreviousChapter: true);
      final entry = find.text(ReaderStrings.previousChapter);

      expect(
        tester.getBottomLeft(entry).dy,
        lessThan(tester.getTopLeft(findBlock(0)).dy),
      );
      await tester.tap(entry);

      expect(previousChapterRequestCount, 1);
      expect(nextChapterRequestCount, 0);
    });

    testWidgets('有上一章时，按章首打开会把入口收在视口上方', (tester) async {
      await pumpView(tester, chapter: longChapter, hasPreviousChapter: true);

      expect(scrollPosition(tester).pixels, greaterThan(0));
      expectBlockStartAtViewportTop(tester, 0);
    });

    testWidgets('有下一章时入口在最后一个块之后，点击发出请求', (tester) async {
      await pumpView(tester, chapter: shortChapter, hasNextChapter: true);
      final entry = find.text(ReaderStrings.nextChapter);

      expect(
        tester.getTopLeft(entry).dy,
        greaterThan(tester.getBottomLeft(findBlock(0)).dy),
      );
      await tester.tap(entry);

      expect(nextChapterRequestCount, 1);
      expect(previousChapterRequestCount, 0);
    });

    testWidgets('已是最后一章时章末只有一行提示文字，不可点', (tester) async {
      await pumpView(tester, chapter: shortChapter);
      final notice = find.text(ReaderStrings.lastChapterReached);

      expect(notice, findsOneWidget);
      expect(find.text(ReaderStrings.nextChapter), findsNothing);
      expect(
        find.ancestor(of: notice, matching: find.byType(ButtonStyleButton)),
        findsNothing,
      );
      await tester.tap(notice);

      expect(nextChapterRequestCount, 0);
    });
  });

  group('点句与高亮', () {
    testWidgets('点带语音的句子回调它的定位', (tester) async {
      await pumpView(tester, chapter: longChapter);

      await tapSentence(tester, openingTranslation, 1);

      expect(tappedSentences, [
        const SentenceRef(
          blockIndex: 0,
          side: TextSide.translation,
          sentenceIndex: 1,
        ),
      ]);
    });

    testWidgets('点无语音的句子不回调', (tester) async {
      await pumpView(tester, chapter: longChapter);

      await tapSentence(tester, openingTranslation, 0);

      expect(tappedSentences, isEmpty);
    });

    testWidgets('正在播放的句子高亮，同一段的另一面整段淡色高亮', (tester) async {
      await pumpView(
        tester,
        chapter: longChapter,
        activeSentence: const SentenceRef(
          blockIndex: 0,
          side: TextSide.translation,
          sentenceIndex: 1,
        ),
      );

      expect(
        tester
            .widget<TextFragmentView>(findFragmentOf(openingTranslation))
            .highlight,
        const ActiveSentenceHighlight(1),
      );
      expect(
        tester
            .widget<TextFragmentView>(findFragmentOf(openingSource))
            .highlight,
        const CompanionSideHighlight(),
      );
      expect(
        tester
            .widget<TextFragmentView>(findFragmentOf(longTranslation))
            .highlight,
        const NoSideHighlight(),
      );
    });
  });

  group('排版常量', () {
    test('块开头的定位留白小于块间距，留白里不会露出上一个块', () {
      expect(
        ReaderLayoutConstants.blockStartLeadingMargin,
        lessThan(ReaderLayoutConstants.blockSpacing),
      );
    });
  });
}

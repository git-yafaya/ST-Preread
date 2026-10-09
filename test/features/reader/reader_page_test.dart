import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/constants/reader_strings.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/player/player_bar.dart';
import 'package:st_preread/features/reader/content/content.dart';
import 'package:st_preread/features/reader/logic/chapter_anchors.dart';
import 'package:st_preread/features/reader/paged/paged_chapter_view.dart';
import 'package:st_preread/features/reader/reader_page.dart';
import 'package:st_preread/features/reader/scroll/scroll_chapter_view.dart';
import 'package:st_preread/features/settings/reader_settings_sheet.dart';

import 'support/reader_fixtures.dart';
import 'support/reader_test_environment.dart';
import 'support/text_layout_probes.dart';

void main() {
  const positionTolerance = 1.0;
  const longTextLength = 1500;
  const midParagraphOffset = 700;
  const longBlockIndex = 1;

  // 第一章：带语音句子的双语段落、超过一屏的长段落、结尾的短段落。
  final openingTranslation = buildSidedText(const [
    FixtureSentence('旁白。'),
    FixtureSentence.voiced('“对白。”'),
  ], audioFileStem: 'opening-translation');
  final openingSource = buildSidedText(const [
    FixtureSentence.voiced('「台詞」'),
  ], audioFileStem: 'opening-source');
  final longTranslation = buildLongSidedText(
    character: '译',
    length: longTextLength,
  );
  final firstChapterEnding = buildPlainSidedText('第一章的最后一段。');
  final firstChapter = buildChapter(
    index: 0,
    title: '第一章 开端',
    blocks: [
      buildParagraph(
        id: 'opening',
        source: openingSource,
        translation: openingTranslation,
      ),
      buildParagraph(id: 'long', translation: longTranslation),
      buildParagraph(id: 'ending', translation: firstChapterEnding),
    ],
  );
  final secondChapterOpening = buildPlainSidedText('第二章的第一段。');
  final secondChapter = buildChapter(
    index: 1,
    title: '第二章 途中',
    blocks: [buildParagraph(translation: secondChapterOpening)],
  );
  final thirdChapter = buildChapter(
    index: 2,
    title: '第三章 终点',
    blocks: [buildParagraph(translation: buildPlainSidedText('全书的最后一段。'))],
  );
  final chapters = [firstChapter, secondChapter, thirdChapter];

  const voicedTranslationSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.translation,
    sentenceIndex: 1,
  );
  const midParagraphAnchor = ReadingAnchor(
    blockIndex: longBlockIndex,
    side: TextSide.translation,
    textOffset: midParagraphOffset,
  );

  ReaderTestEnvironment createEnvironment({
    ReaderSettings settings = defaultReaderSettings,
    ReadingPosition? savedPosition,
  }) {
    final environment = ReaderTestEnvironment(
      chapters: chapters,
      settings: settings,
      savedPosition: savedPosition,
    );
    addTearDown(environment.dispose);
    return environment;
  }

  ReadingPosition positionIn(int chapterIndex, ReadingAnchor anchor) {
    return ReadingPosition(
      bookId: fixtureBookId,
      chapterIndex: chapterIndex,
      anchor: anchor,
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    ReaderTestEnvironment environment, {
    String bookId = fixtureBookId,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: environment.overrides,
        child: MaterialApp(home: ReaderPage(bookId: bookId)),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  String appBarTitle(WidgetTester tester) {
    final title = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(title).data!;
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

  double viewportTop(WidgetTester tester) {
    return tester.getTopLeft(find.byType(ScrollChapterView)).dy;
  }

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

  ScrollChapterView scrollView(WidgetTester tester) {
    return tester.widget<ScrollChapterView>(find.byType(ScrollChapterView));
  }

  group('加载与出错', () {
    testWidgets('加载中显示进度指示，加载完成后显示正文', (tester) async {
      final environment = createEnvironment();
      final gate = Completer<void>();
      environment.bookRepository.listChaptersGate = gate;

      await pumpPage(tester, environment, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ScrollChapterView), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ScrollChapterView), findsOneWidget);
    });

    testWidgets('找不到书时显示对应的提示', (tester) async {
      await pumpPage(tester, createEnvironment(), bookId: 'unknown-book');

      expect(find.text(ReaderStrings.bookNotFound), findsOneWidget);
      expect(find.byType(ScrollChapterView), findsNothing);
    });

    testWidgets('找不到章节时显示对应的提示，重试成功后显示正文', (tester) async {
      final environment = createEnvironment();
      environment.bookRepository.missingChapterIndexes.add(0);

      await pumpPage(tester, environment);

      expect(find.text(ReaderStrings.chapterNotFound), findsOneWidget);

      environment.bookRepository.missingChapterIndexes.clear();
      await tester.tap(find.text(ReaderStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text(ReaderStrings.chapterNotFound), findsNothing);
      expect(find.byType(ScrollChapterView), findsOneWidget);
    });

    testWidgets('其他读取异常显示一般的加载失败提示', (tester) async {
      final environment = createEnvironment();
      environment.bookRepository.listChaptersError = const FormatException();

      await pumpPage(tester, environment);

      expect(find.text(ReaderStrings.loadFailed), findsOneWidget);
    });
  });

  group('正常显示', () {
    testWidgets('首次打开显示第一章，顶栏是章节名，底部拼上播放条', (tester) async {
      await pumpPage(tester, createEnvironment());

      expect(appBarTitle(tester), firstChapter.summary.title);
      expect(scrollView(tester).chapter, firstChapter);
      expect(scrollView(tester).initialAnchor, chapterStartAnchor);
      expect(find.byType(PlayerBar), findsOneWidget);
      expect(scrollPosition(tester).pixels, 0);
    });

    testWidgets('有进度时恢复到上次的章节', (tester) async {
      final environment = createEnvironment(
        savedPosition: positionIn(1, chapterStartAnchor),
      );

      await pumpPage(tester, environment);

      expect(appBarTitle(tester), secondChapter.summary.title);
      expect(findFragmentOf(secondChapterOpening), findsOneWidget);
    });

    testWidgets('按锚点恢复到长段落内部的那一行', (tester) async {
      final environment = createEnvironment(
        savedPosition: positionIn(0, midParagraphAnchor),
      );

      await pumpPage(tester, environment);

      expect(scrollPosition(tester).pixels, greaterThan(0));
      expectLineAtViewportTop(tester, longTranslation, midParagraphOffset);
    });
  });

  group('三种显示方式', () {
    List<TextSide> openingSides(WidgetTester tester) {
      return [
        for (final sidedText in [openingTranslation, openingSource])
          if (findFragmentOf(sidedText).evaluate().isNotEmpty)
            tester.widget<TextFragmentView>(findFragmentOf(sidedText)).side,
      ];
    }

    testWidgets('默认对照显示：译文为主、原文为辅', (tester) async {
      await pumpPage(tester, createEnvironment());

      expect(openingSides(tester), [TextSide.translation, TextSide.source]);
      expect(
        tester
            .widget<TextFragmentView>(findFragmentOf(openingTranslation))
            .role,
        TextRole.primary,
      );
      expect(
        tester.widget<TextFragmentView>(findFragmentOf(openingSource)).role,
        TextRole.secondary,
      );
    });

    testWidgets('改为只看译文后只剩译文', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);

      await environment.updateSettings(
        (settings) => settings.copyWith(
          displayMode: BilingualDisplayMode.translationOnly,
        ),
      );
      await tester.pumpAndSettle();

      expect(openingSides(tester), [TextSide.translation]);
    });

    testWidgets('改为只看原文后只剩原文，没有原文的段落仍显示译文', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);

      await environment.updateSettings(
        (settings) =>
            settings.copyWith(displayMode: BilingualDisplayMode.sourceOnly),
      );
      await tester.pumpAndSettle();

      expect(openingSides(tester), [TextSide.source]);
      expect(findFragmentOf(longTranslation), findsOneWidget);
    });

    testWidgets('显示方式变化后阅读位置保持在原来那一行', (tester) async {
      final environment = createEnvironment(
        savedPosition: positionIn(0, midParagraphAnchor),
      );
      await pumpPage(tester, environment);
      final pixelsBeforeChange = scrollPosition(tester).pixels;

      await environment.updateSettings(
        (settings) => settings.copyWith(
          displayMode: BilingualDisplayMode.translationOnly,
        ),
      );
      await tester.pumpAndSettle();

      // 第一段少了辅文，上方内容变短，滚动距离变了，但顶部仍是同一行。
      expect(scrollPosition(tester).pixels, lessThan(pixelsBeforeChange));
      expectLineAtViewportTop(tester, longTranslation, midParagraphOffset);
    });
  });

  group('点句播放', () {
    testWidgets('点带语音的句子会调用播放服务播放这一句', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);

      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();

      expect(environment.playbackService.playRequests, [
        (
          sentence: voicedTranslationSentence,
          clip: openingTranslation.sentences[1].audio!,
        ),
      ]);
    });

    testWidgets('点无语音的句子不会调用播放服务', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);

      await tapSentence(tester, openingTranslation, 0);
      await tester.pumpAndSettle();

      expect(environment.playbackService.playRequests, isEmpty);
    });

    testWidgets('播放中的句子传给视图用于高亮', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);

      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();

      expect(scrollView(tester).activeSentence, voicedTranslationSentence);
    });

    testWidgets('再点正在播的那一句是停止，高亮随之消失', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();

      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();

      expect(environment.playbackService.playRequests, hasLength(1));
      expect(environment.playbackService.stopCallCount, 1);
      expect(scrollView(tester).activeSentence, isNull);
    });

    testWidgets('点另一面带语音的句子是改播那一句', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();

      await tapSentence(tester, openingSource, 0);
      await tester.pumpAndSettle();

      expect(
        environment.playbackService.playRequests.map(
          (request) => request.sentence,
        ),
        [
          voicedTranslationSentence,
          const SentenceRef(
            blockIndex: 0,
            side: TextSide.source,
            sentenceIndex: 0,
          ),
        ],
      );
    });

    testWidgets('播放失败时给出简短提示', (tester) async {
      final environment = createEnvironment();
      environment.playbackService.shouldFailToPlay = true;
      await pumpPage(tester, environment);

      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(ReaderStrings.playbackFailed), findsOneWidget);
    });

    testWidgets('显示方式改变使在播句子所在的面消失时停止播放', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      await tapSentence(tester, openingSource, 0);
      await tester.pumpAndSettle();

      await environment.updateSettings(
        (settings) => settings.copyWith(
          displayMode: BilingualDisplayMode.translationOnly,
        ),
      );
      await tester.pumpAndSettle();

      expect(environment.playbackService.stopCallCount, 1);
      expect(scrollView(tester).activeSentence, isNull);
    });
  });

  group('目录', () {
    Future<void> openContents(WidgetTester tester) async {
      await tester.tap(find.byTooltip(ReaderStrings.tableOfContents));
      await tester.pumpAndSettle();
    }

    ListTile chapterTile(WidgetTester tester, Chapter chapter) {
      return tester.widget<ListTile>(
        find.widgetWithText(ListTile, chapter.summary.title),
      );
    }

    testWidgets('目录抽屉列出全部章节，并标出当前章', (tester) async {
      await pumpPage(tester, createEnvironment());

      await openContents(tester);

      expect(find.byType(Drawer), findsOneWidget);
      expect(chapterTile(tester, firstChapter).selected, isTrue);
      expect(chapterTile(tester, secondChapter).selected, isFalse);
      expect(chapterTile(tester, thirdChapter).selected, isFalse);
    });

    testWidgets('点选章节后跳到该章开头，收起抽屉并保存进度', (tester) async {
      final environment = createEnvironment(
        savedPosition: positionIn(0, midParagraphAnchor),
      );
      await pumpPage(tester, environment);
      await openContents(tester);

      await tester.tap(
        find.widgetWithText(ListTile, thirdChapter.summary.title),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(appBarTitle(tester), thirdChapter.summary.title);
      expect(scrollView(tester).chapter, thirdChapter);
      expect(scrollView(tester).initialAnchor, chapterStartAnchor);
      expect(scrollPosition(tester).pixels, 0);
      expect(
        environment.progressRepository.savedPositions,
        contains(positionIn(2, chapterStartAnchor)),
      );
    });

    testWidgets('读到一半时从目录再点当前章，回到这一章的开头', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      scrollPosition(tester).jumpTo(600);
      await tester.pumpAndSettle();
      await openContents(tester);

      await tester.tap(
        find.widgetWithText(ListTile, firstChapter.summary.title),
      );
      await tester.pumpAndSettle();

      expect(scrollPosition(tester).pixels, 0);
    });
  });

  group('设置', () {
    testWidgets('设置入口以底部面板弹出阅读设置', (tester) async {
      await pumpPage(tester, createEnvironment());

      await tester.tap(find.byTooltip(ReaderStrings.settingsTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(ReaderSettingsSheet), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('翻阅方式改为翻页时换用翻页视图，并从刚才读到的位置开始', (tester) async {
      final environment = createEnvironment(
        savedPosition: positionIn(0, midParagraphAnchor),
      );
      await pumpPage(tester, environment);
      scrollPosition(tester).jumpTo(scrollPosition(tester).pixels + 300);
      await tester.pumpAndSettle();
      environment.scheduler.elapse();
      final latestAnchor =
          environment.progressRepository.savedPositions.last.anchor;

      await environment.updateSettings(
        (settings) => settings.copyWith(pageTurnMode: PageTurnMode.paged),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScrollChapterView), findsNothing);
      final pagedView = tester.widget<PagedChapterView>(
        find.byType(PagedChapterView),
      );
      expect(pagedView.chapter, firstChapter);
      expect(pagedView.initialAnchor, latestAnchor);
      expect(latestAnchor.textOffset, greaterThan(midParagraphOffset));
      expect(pagedView.onPreviousChapterRequested, isNull);
      expect(pagedView.onNextChapterRequested, isNotNull);
    });

    testWidgets('从翻页切回滚动时，滚动视图定位到同一个锚点', (tester) async {
      final environment = createEnvironment(
        settings: defaultReaderSettings.copyWith(
          pageTurnMode: PageTurnMode.paged,
        ),
        savedPosition: positionIn(0, midParagraphAnchor),
      );
      await pumpPage(tester, environment);

      await environment.updateSettings(
        (settings) => settings.copyWith(pageTurnMode: PageTurnMode.scroll),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PagedChapterView), findsNothing);
      expectLineAtViewportTop(tester, longTranslation, midParagraphOffset);
    });
  });

  group('章末衔接', () {
    Future<void> scrollToChapterEnd(WidgetTester tester) async {
      final position = scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }

    Future<void> scrollToChapterTop(WidgetTester tester) async {
      scrollPosition(tester).jumpTo(0);
      await tester.pumpAndSettle();
    }

    testWidgets('第一章没有「上一章」入口，有「下一章」入口', (tester) async {
      await pumpPage(tester, createEnvironment());

      expect(scrollView(tester).onPreviousChapterRequested, isNull);
      expect(scrollView(tester).onNextChapterRequested, isNotNull);
      expect(find.text(ReaderStrings.previousChapter), findsNothing);
    });

    testWidgets('最后一章章末显示「已是最后一章」，没有「下一章」入口', (tester) async {
      await pumpPage(
        tester,
        createEnvironment(savedPosition: positionIn(2, chapterStartAnchor)),
      );

      expect(scrollView(tester).onNextChapterRequested, isNull);
      expect(find.text(ReaderStrings.lastChapterReached), findsOneWidget);
      expect(find.text(ReaderStrings.nextChapter), findsNothing);
    });

    testWidgets('在章末点「下一章」进入下一章的开头，并立即保存进度', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      await scrollToChapterEnd(tester);

      await tester.tap(find.text(ReaderStrings.nextChapter));
      await tester.pumpAndSettle();

      expect(appBarTitle(tester), secondChapter.summary.title);
      expect(scrollView(tester).chapter, secondChapter);
      expect(scrollView(tester).initialAnchor, chapterStartAnchor);
      expect(
        environment.progressRepository.savedPositions,
        contains(positionIn(1, chapterStartAnchor)),
      );
    });

    testWidgets('在章首点「上一章」回到上一章的末尾', (tester) async {
      final environment = createEnvironment(
        savedPosition: positionIn(1, chapterStartAnchor),
      );
      await pumpPage(tester, environment);
      await scrollToChapterTop(tester);

      await tester.tap(find.text(ReaderStrings.previousChapter));
      await tester.pumpAndSettle();

      final expectedAnchor = resolveChapterEndAnchor(
        firstChapter,
        BilingualDisplayMode.both,
      );
      final position = scrollPosition(tester);
      expect(appBarTitle(tester), firstChapter.summary.title);
      expect(scrollView(tester).initialAnchor, expectedAnchor);
      expect(position.pixels, position.maxScrollExtent);
      expect(position.maxScrollExtent, greaterThan(0));
      // 章末的最后一段完整地落在视口之内。
      final viewportRect = tester.getRect(find.byType(ScrollChapterView));
      final endingRect = tester.getRect(findFragmentOf(firstChapterEnding));
      expect(viewportRect.contains(endingRect.topLeft), isTrue);
      expect(viewportRect.contains(endingRect.bottomLeft), isTrue);
      expect(
        environment.progressRepository.savedPositions,
        contains(positionIn(0, expectedAnchor)),
      );
    });

    testWidgets('换章时先停止正在播放的句子', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();
      await scrollToChapterEnd(tester);
      environment.log.clear();

      await tester.tap(find.text(ReaderStrings.nextChapter));
      await tester.pumpAndSettle();

      expect(environment.log, ['stop', 'loadChapter:1']);
      expect(scrollView(tester).activeSentence, isNull);
    });
  });

  group('进度保存', () {
    testWidgets('滚动后按限速间隔保存视口顶部的锚点', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      environment.scheduler.elapse();
      environment.progressRepository.savedPositions.clear();

      scrollPosition(tester).jumpTo(600);
      await tester.pumpAndSettle();

      expect(environment.progressRepository.savedPositions, isEmpty);

      environment.scheduler.elapse();

      final savedPosition =
          environment.progressRepository.savedPositions.single;
      expect(savedPosition.chapterIndex, 0);
      expect(savedPosition.anchor.blockIndex, longBlockIndex);
      expect(savedPosition.anchor.side, TextSide.translation);
      expect(savedPosition.anchor.textOffset, greaterThan(0));
    });

    testWidgets('离开页面时保存最后一次位置并停止播放', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      await tapSentence(tester, openingTranslation, 1);
      await tester.pumpAndSettle();
      environment.scheduler.elapse();
      environment.progressRepository.savedPositions.clear();
      scrollPosition(tester).jumpTo(600);
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      final savedPosition =
          environment.progressRepository.savedPositions.single;
      expect(savedPosition.anchor.blockIndex, longBlockIndex);
      expect(environment.playbackService.stopCallCount, 1);
    });

    testWidgets('退出后重新进入，回到长段落内部读到的那一行', (tester) async {
      final environment = createEnvironment();
      await pumpPage(tester, environment);
      scrollPosition(tester).jumpTo(600);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      final savedAnchor =
          environment.progressRepository.savedPositions.last.anchor;

      await pumpPage(tester, environment);

      expect(savedAnchor.blockIndex, longBlockIndex);
      expectLineAtViewportTop(tester, longTranslation, savedAnchor.textOffset);
    });
  });
}

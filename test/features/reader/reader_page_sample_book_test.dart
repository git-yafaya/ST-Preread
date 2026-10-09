import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/data/mock/mock_audio_playback_service.dart';
import 'package:st_preread/data/mock/mock_book_repository.dart';
import 'package:st_preread/data/mock/mock_reader_settings_repository.dart';
import 'package:st_preread/data/mock/mock_reading_progress_repository.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';
import 'package:st_preread/features/reader/logic/chapter_anchors.dart';
import 'package:st_preread/features/reader/reader_page.dart';
import 'package:st_preread/features/reader/scroll/scroll_chapter_view.dart';

import '../../support/manual_playback_ticker.dart';
import 'support/text_layout_probes.dart';

/// 用示例书把阅读页整个走一遍。示例书覆盖了各种数据形态（样式叠加、样式跨句、
/// 句间空隙、emoji、没有句级数据的一面、插图、分隔线、长段落），
/// 这里只按「每一章、每一种显示方式」遍历，不依赖它具体的块下标。
void main() {
  late MockBookRepository bookRepository;
  late MockReadingProgressRepository progressRepository;
  late MockReaderSettingsRepository settingsRepository;
  late MockAudioPlaybackService playbackService;
  late String bookId;
  late List<ChapterSummary> chapters;

  setUp(() async {
    bookRepository = MockBookRepository();
    progressRepository = MockReadingProgressRepository();
    playbackService = MockAudioPlaybackService(ticker: ManualPlaybackTicker());
    addTearDown(bookRepository.dispose);
    addTearDown(playbackService.dispose);
    bookId = (await bookRepository.watchBooks().first).single.id;
    chapters = await bookRepository.listChapters(bookId);
  });

  Future<void> pumpPageAt(
    WidgetTester tester, {
    required int chapterIndex,
    required BilingualDisplayMode displayMode,
  }) async {
    settingsRepository = MockReaderSettingsRepository(
      initialSettings: defaultReaderSettings.copyWith(displayMode: displayMode),
    );
    addTearDown(settingsRepository.dispose);
    // 先卸掉上一轮的阅读页：它离开时会把自己读到的位置存下来，
    // 必须赶在这之后再写入这一轮要打开的章节。
    await tester.pumpWidget(const SizedBox());
    await progressRepository.savePosition(
      ReadingPosition(
        bookId: bookId,
        chapterIndex: chapterIndex,
        anchor: chapterStartAnchor,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(bookRepository),
          readingProgressRepositoryProvider.overrideWithValue(
            progressRepository,
          ),
          readerSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          audioPlaybackServiceProvider.overrideWithValue(playbackService),
        ],
        child: MaterialApp(home: ReaderPage(bookId: bookId)),
      ),
    );
    await tester.pumpAndSettle();
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

  testWidgets('示例书的每一章在三种显示方式下都能完整渲染并滚到章末', (tester) async {
    for (final displayMode in BilingualDisplayMode.values) {
      for (final summary in chapters) {
        await pumpPageAt(
          tester,
          chapterIndex: summary.index,
          displayMode: displayMode,
        );
        final position = scrollPosition(tester);
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();

        final reason = '${displayMode.name} / ${summary.title}';
        expect(tester.takeException(), isNull, reason: reason);
        expect(find.text(summary.title), findsOneWidget, reason: reason);
        expect(find.byType(ContentBlockView), findsWidgets, reason: reason);
      }
    }
  });

  testWidgets('每个文字片段画出来的文字与那一面的原文完全一致', (tester) async {
    for (final summary in chapters) {
      await pumpPageAt(
        tester,
        chapterIndex: summary.index,
        displayMode: BilingualDisplayMode.both,
      );

      final fragments = tester.widgetList<TextFragmentView>(
        find.byType(TextFragmentView),
      );
      expect(fragments, isNotEmpty);
      for (final fragment in fragments) {
        expect(
          paragraphOf(
            tester,
            findFragmentOf(fragment.sidedText),
          ).text.toPlainText(),
          fragment.sidedText.text,
        );
      }
    }
  });

  testWidgets('点示例书里每一句带语音的句子，被播放并高亮的都是这一句', (tester) async {
    for (final summary in chapters) {
      await pumpPageAt(
        tester,
        chapterIndex: summary.index,
        displayMode: BilingualDisplayMode.both,
      );
      final chapter = await bookRepository.loadChapter(bookId, summary.index);

      for (final (blockIndex, block) in chapter.blocks.indexed) {
        if (block is! ParagraphBlock) {
          continue;
        }
        for (final side in TextSide.values) {
          final sidedText = block.textOf(side);
          if (sidedText == null) {
            continue;
          }
          await _tapEveryVoicedSentence(
            tester,
            scrollPosition: scrollPosition(tester),
            sidedText: sidedText,
            blockIndex: blockIndex,
            side: side,
          );
        }
      }
    }
  });
}

/// 逐句点 [sidedText] 里带语音的句子，核对被播放（因而被高亮）的正是这一句。
///
/// 通过视图收到的 activeSentence 来核对，而不是在这里等播放状态流：
/// 在 testWidgets 里等一个流的事件，测试体会脱离受控的假时钟，之后的 pump 就再也回不来。
Future<void> _tapEveryVoicedSentence(
  WidgetTester tester, {
  required ScrollPosition scrollPosition,
  required SidedText sidedText,
  required int blockIndex,
  required TextSide side,
}) async {
  for (final (sentenceIndex, sentence) in sidedText.sentences.indexed) {
    if (!sentence.hasAudio) {
      continue;
    }
    await _scrollToViewportCenter(
      tester,
      scrollPosition: scrollPosition,
      sidedText: sidedText,
      textOffset: sentence.startOffset,
    );
    await tapSentence(tester, sidedText, sentenceIndex);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ScrollChapterView>(find.byType(ScrollChapterView))
          .activeSentence,
      SentenceRef(
        blockIndex: blockIndex,
        side: side,
        sentenceIndex: sentenceIndex,
      ),
      reason: '第 $blockIndex 块 ${side.name} 第 $sentenceIndex 句',
    );
  }
}

/// 把 [sidedText] 第 [textOffset] 个字符所在的行滚到视口中部（长段落里的句子可能在屏幕之外）。
Future<void> _scrollToViewportCenter(
  WidgetTester tester, {
  required ScrollPosition scrollPosition,
  required SidedText sidedText,
  required int textOffset,
}) async {
  final lineTop = globalLineTopOf(
    tester,
    findFragmentOf(sidedText),
    textOffset,
  );
  final viewportCenter = tester
      .getRect(find.byType(ScrollChapterView))
      .center
      .dy;
  final targetPixels = scrollPosition.pixels + lineTop - viewportCenter;
  scrollPosition.jumpTo(
    targetPixels.clamp(
      scrollPosition.minScrollExtent,
      scrollPosition.maxScrollExtent,
    ),
  );
  await tester.pumpAndSettle();
}

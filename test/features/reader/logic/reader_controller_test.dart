import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_progress_constants.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/data/mock/mock_playback_timing.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/logic/chapter_anchors.dart';
import 'package:st_preread/features/reader/logic/reader_controller.dart';
import 'package:st_preread/features/reader/logic/reader_state.dart';

import '../support/reader_fixtures.dart';
import '../support/reader_test_environment.dart';

void main() {
  // 第 0 章以一个双语段落结尾（用于章末锚点）；第 1 章有两面都带语音的段落；第 2 章只有分隔线。
  final firstChapterLastParagraph = buildParagraph(
    id: 'first-chapter-end',
    source: buildPlainSidedText('原文结尾共八个字'),
    translation: buildPlainSidedText('译文结尾'),
  );
  final voicedTranslation = buildSidedText(const [
    FixtureSentence('旁白。'),
    FixtureSentence.voiced('“第一句对白。”'),
    FixtureSentence.voiced('“第二句对白。”'),
  ], audioFileStem: 'translation');
  final voicedSource = buildSidedText(const [
    FixtureSentence.voiced('「台詞」'),
  ], audioFileStem: 'source');
  final chapters = [
    buildChapter(
      index: 0,
      blocks: [
        buildParagraph(id: 'opening', translation: voicedTranslation),
        firstChapterLastParagraph,
      ],
    ),
    buildChapter(
      index: 1,
      blocks: [
        buildParagraph(source: voicedSource, translation: voicedTranslation),
      ],
    ),
    buildChapter(index: 2, blocks: const [DividerBlock(id: 'divider')]),
  ];

  const firstVoicedSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.translation,
    sentenceIndex: 1,
  );
  const secondVoicedSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.translation,
    sentenceIndex: 2,
  );
  const sourceSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.source,
    sentenceIndex: 0,
  );
  const midParagraphAnchor = ReadingAnchor(
    blockIndex: 0,
    side: TextSide.translation,
    textOffset: 5,
  );

  // 夹具里的语音没有给出区间，假播放器按兜底时长播放；拨这么多下一定播完。
  final ticksToFinishAnyClip =
      MockPlaybackTiming.fallbackClipDuration.inMicroseconds ~/
          MockPlaybackTiming.tickInterval.inMicroseconds +
      1;

  late ReaderTestEnvironment environment;
  late ProviderContainer container;

  ReaderTestEnvironment createEnvironment({
    ReaderSettings settings = defaultReaderSettings,
    ReadingPosition? savedPosition,
  }) {
    final created = ReaderTestEnvironment(
      chapters: chapters,
      settings: settings,
      savedPosition: savedPosition,
    );
    addTearDown(created.dispose);
    return created;
  }

  ReadingPosition positionIn(int chapterIndex, ReadingAnchor anchor) {
    return ReadingPosition(
      bookId: fixtureBookId,
      chapterIndex: chapterIndex,
      anchor: anchor,
    );
  }

  /// 打开阅读页的状态并等它加载完。
  Future<ReaderController> openReader({String bookId = fixtureBookId}) async {
    container = ProviderContainer(overrides: environment.overrides);
    addTearDown(container.dispose);
    // 自动销毁的状态需要有人监听才会保持存活，这里代替界面。
    container.listen(readerControllerProvider(bookId), (_, _) {});
    await pumpEventQueue();
    return container.read(readerControllerProvider(bookId).notifier);
  }

  ReaderState readState({String bookId = fixtureBookId}) {
    return container.read(readerControllerProvider(bookId));
  }

  ReaderReady readReadyState() => readState() as ReaderReady;

  setUp(() {
    environment = createEnvironment();
  });

  group('打开', () {
    test('首次打开落在第一章开头，并带上全书目录', () async {
      await openReader();

      final readyState = readReadyState();
      expect(readyState.currentChapterIndex, 0);
      expect(readyState.initialAnchor, chapterStartAnchor);
      expect(readyState.chapters.map((summary) => summary.index), [0, 1, 2]);
    });

    test('有进度时恢复到上次的章节与锚点', () async {
      environment = createEnvironment(
        savedPosition: positionIn(1, midParagraphAnchor),
      );

      await openReader();

      final readyState = readReadyState();
      expect(readyState.currentChapterIndex, 1);
      expect(readyState.initialAnchor, midParagraphAnchor);
    });

    test('加载完成之前是加载中状态', () async {
      container = ProviderContainer(overrides: environment.overrides);
      addTearDown(container.dispose);

      expect(
        container.read(readerControllerProvider(fixtureBookId)),
        isA<ReaderLoading>(),
      );
    });

    test('找不到书时给出对应的失败原因', () async {
      await openReader(bookId: 'unknown-book');

      final state = readState(bookId: 'unknown-book');
      expect(state, isA<ReaderFailure>());
      expect((state as ReaderFailure).reason, ReaderFailureReason.bookNotFound);
    });

    test('找不到章节时给出对应的失败原因', () async {
      environment.bookRepository.missingChapterIndexes.add(0);

      await openReader();

      expect(
        (readState() as ReaderFailure).reason,
        ReaderFailureReason.chapterNotFound,
      );
    });

    test('书里没有章节时给出对应的失败原因', () async {
      environment = ReaderTestEnvironment(chapters: const []);
      addTearDown(environment.dispose);

      await openReader();

      expect(
        (readState() as ReaderFailure).reason,
        ReaderFailureReason.emptyBook,
      );
    });

    test('其他读取异常归为一般的加载失败', () async {
      environment.bookRepository.listChaptersError = const FormatException();

      await openReader();

      expect(
        (readState() as ReaderFailure).reason,
        ReaderFailureReason.unknown,
      );
    });

    test('失败后重试可以重新加载出来', () async {
      environment.bookRepository.listChaptersError = const FormatException();
      final controller = await openReader();
      environment.bookRepository.listChaptersError = null;

      await controller.retry();

      expect(readReadyState().currentChapterIndex, 0);
    });
  });

  group('点句播放', () {
    test('点一句带语音的句子，播放它的语音', () async {
      final controller = await openReader();

      final outcome = await controller.toggleSentencePlayback(
        firstVoicedSentence,
      );

      expect(outcome, SentenceTapOutcome.started);
      expect(environment.playbackService.playRequests, [
        (
          sentence: firstVoicedSentence,
          clip: voicedTranslation.sentences[1].audio!,
        ),
      ]);
    });

    test('再点正在播的同一句是停止，不会重新播放', () async {
      final controller = await openReader();
      await controller.toggleSentencePlayback(firstVoicedSentence);

      final outcome = await controller.toggleSentencePlayback(
        firstVoicedSentence,
      );

      expect(outcome, SentenceTapOutcome.stopped);
      expect(environment.playbackService.playRequests, hasLength(1));
      expect(environment.playbackService.stopCallCount, 1);
    });

    test('暂停中点同一句也是停止', () async {
      final controller = await openReader();
      await controller.toggleSentencePlayback(firstVoicedSentence);
      await environment.playbackService.pause();
      await pumpEventQueue();

      final outcome = await controller.toggleSentencePlayback(
        firstVoicedSentence,
      );

      expect(outcome, SentenceTapOutcome.stopped);
    });

    test('点另一句是改播那一句', () async {
      final controller = await openReader();
      await controller.toggleSentencePlayback(firstVoicedSentence);

      final outcome = await controller.toggleSentencePlayback(
        secondVoicedSentence,
      );

      expect(outcome, SentenceTapOutcome.started);
      expect(
        environment.playbackService.playRequests.map(
          (request) => request.sentence,
        ),
        [firstVoicedSentence, secondVoicedSentence],
      );
    });

    test('这一句自然播完之后再点它，是重新播放', () async {
      final controller = await openReader();
      await controller.toggleSentencePlayback(firstVoicedSentence);
      environment.playbackService.ticker.tick(times: ticksToFinishAnyClip);
      await pumpEventQueue();

      final outcome = await controller.toggleSentencePlayback(
        firstVoicedSentence,
      );

      expect(outcome, SentenceTapOutcome.started);
      expect(environment.playbackService.stopCallCount, 0);
    });

    test('句子没有语音时不调用播放服务', () async {
      final controller = await openReader();

      final outcome = await controller.toggleSentencePlayback(
        const SentenceRef(
          blockIndex: 0,
          side: TextSide.translation,
          sentenceIndex: 0,
        ),
      );

      expect(outcome, SentenceTapOutcome.ignored);
      expect(environment.playbackService.playRequests, isEmpty);
    });

    test('播放失败时告知界面给出提示', () async {
      final controller = await openReader();
      environment.playbackService.shouldFailToPlay = true;

      final outcome = await controller.toggleSentencePlayback(
        firstVoicedSentence,
      );

      expect(outcome, SentenceTapOutcome.failed);
    });

    test('播放失败后再点同一句仍然是尝试播放', () async {
      final controller = await openReader();
      environment.playbackService.shouldFailToPlay = true;
      await controller.toggleSentencePlayback(firstVoicedSentence);
      environment.playbackService.shouldFailToPlay = false;

      final outcome = await controller.toggleSentencePlayback(
        firstVoicedSentence,
      );

      expect(outcome, SentenceTapOutcome.started);
    });
  });

  group('显示方式变化', () {
    Future<ReaderController> openSecondChapter() {
      environment = createEnvironment(
        savedPosition: positionIn(1, chapterStartAnchor),
      );
      return openReader();
    }

    test('在播句子所在的面不再显示时停止播放', () async {
      final controller = await openSecondChapter();
      await controller.toggleSentencePlayback(sourceSentence);

      await environment.updateSettings(
        (settings) => settings.copyWith(
          displayMode: BilingualDisplayMode.translationOnly,
        ),
      );
      await pumpEventQueue();

      expect(environment.playbackService.stopCallCount, 1);
    });

    test('在播句子所在的面仍然显示时继续播放', () async {
      final controller = await openSecondChapter();
      await controller.toggleSentencePlayback(firstVoicedSentence);

      await environment.updateSettings(
        (settings) => settings.copyWith(
          displayMode: BilingualDisplayMode.translationOnly,
        ),
      );
      await pumpEventQueue();

      expect(environment.playbackService.stopCallCount, 0);
    });

    test('没有在播的句子时改显示方式不会调用停止', () async {
      await openSecondChapter();

      await environment.updateSettings(
        (settings) =>
            settings.copyWith(displayMode: BilingualDisplayMode.sourceOnly),
      );
      await pumpEventQueue();

      expect(environment.playbackService.stopCallCount, 0);
    });
  });

  group('换章', () {
    test('换章时先停止播放，再加载目标章', () async {
      final controller = await openReader();
      await controller.toggleSentencePlayback(firstVoicedSentence);
      environment.log.clear();

      await controller.goToNextChapter();

      expect(environment.log, ['stop', 'loadChapter:1']);
    });

    test('进下一章落在章首', () async {
      final controller = await openReader();

      await controller.goToNextChapter();

      final readyState = readReadyState();
      expect(readyState.currentChapterIndex, 1);
      expect(readyState.initialAnchor, chapterStartAnchor);
    });

    test('回上一章落在章末：对照显示时是末段原文的最后一个字符', () async {
      environment = createEnvironment(
        savedPosition: positionIn(1, chapterStartAnchor),
      );
      final controller = await openReader();

      await controller.goToPreviousChapter();

      final readyState = readReadyState();
      expect(readyState.currentChapterIndex, 0);
      expect(
        readyState.initialAnchor,
        ReadingAnchor(
          blockIndex: 1,
          side: TextSide.source,
          textOffset: firstChapterLastParagraph.source!.text.length - 1,
        ),
      );
    });

    test('回上一章的章末锚点跟随当前的显示方式', () async {
      environment = createEnvironment(
        settings: defaultReaderSettings.copyWith(
          displayMode: BilingualDisplayMode.translationOnly,
        ),
        savedPosition: positionIn(1, chapterStartAnchor),
      );
      final controller = await openReader();

      await controller.goToPreviousChapter();

      expect(
        readReadyState().initialAnchor,
        ReadingAnchor(
          blockIndex: 1,
          side: TextSide.translation,
          textOffset: firstChapterLastParagraph.translation!.text.length - 1,
        ),
      );
    });

    test('换章后立即保存新位置，不等视图回报也不等限速间隔', () async {
      final controller = await openReader();

      await controller.goToNextChapter();

      expect(environment.progressRepository.savedPositions, [
        positionIn(1, chapterStartAnchor),
      ]);
    });

    test('换章前把当前章还没保存的位置先存下', () async {
      final controller = await openReader();
      controller.reportAnchor(midParagraphAnchor);

      await controller.goToNextChapter();

      expect(environment.progressRepository.savedPositions, [
        positionIn(0, midParagraphAnchor),
        positionIn(1, chapterStartAnchor),
      ]);
      expect(environment.scheduler.activeTimerCount, 0);
    });

    test('第一章没有上一章，请求上一章不做任何事', () async {
      final controller = await openReader();
      environment.log.clear();

      await controller.goToPreviousChapter();

      expect(readReadyState().previousChapterIndex, isNull);
      expect(readReadyState().nextChapterIndex, 1);
      expect(environment.log, isEmpty);
    });

    test('最后一章没有下一章，请求下一章不做任何事', () async {
      environment = createEnvironment(
        savedPosition: positionIn(2, chapterStartAnchor),
      );
      final controller = await openReader();
      environment.log.clear();

      await controller.goToNextChapter();

      expect(readReadyState().nextChapterIndex, isNull);
      expect(readReadyState().previousChapterIndex, 1);
      expect(environment.log, isEmpty);
    });

    test('目录跳转落在目标章的章首并保存', () async {
      final controller = await openReader();

      await controller.openChapterFromContents(2);

      final readyState = readReadyState();
      expect(readyState.currentChapterIndex, 2);
      expect(readyState.initialAnchor, chapterStartAnchor);
      expect(
        environment.progressRepository.savedPositions.last,
        positionIn(2, chapterStartAnchor),
      );
    });

    test('从目录再点当前章，也会产生一次新的定位请求', () async {
      final controller = await openReader();
      final serialBefore = readReadyState().navigationSerial;

      await controller.openChapterFromContents(0);

      expect(readReadyState().navigationSerial, greaterThan(serialBefore));
      expect(readReadyState().initialAnchor, chapterStartAnchor);
    });

    test('目标章加载失败时进入失败状态', () async {
      final controller = await openReader();
      environment.bookRepository.missingChapterIndexes.add(1);

      await controller.goToNextChapter();

      expect(
        (readState() as ReaderFailure).reason,
        ReaderFailureReason.chapterNotFound,
      );
    });
  });

  group('进度保存', () {
    test('视图回报锚点后按限速间隔保存，不立即写入', () async {
      final controller = await openReader();

      controller.reportAnchor(midParagraphAnchor);

      expect(environment.progressRepository.savedPositions, isEmpty);
      expect(environment.scheduler.requestedDelays, [
        ReaderProgressConstants.saveInterval,
      ]);

      environment.scheduler.elapse();

      expect(environment.progressRepository.savedPositions, [
        positionIn(0, midParagraphAnchor),
      ]);
    });

    test('离开页面时把最后一次位置存下，并停止播放', () async {
      final controller = await openReader();
      controller.reportAnchor(midParagraphAnchor);

      container.dispose();

      expect(environment.progressRepository.savedPositions, [
        positionIn(0, midParagraphAnchor),
      ]);
      expect(environment.playbackService.stopCallCount, 1);
    });
  });

  group('切换翻阅方式', () {
    test('新视图从最近回报的锚点开始，而不是进入这一章时的位置', () async {
      final controller = await openReader();
      final serialBefore = readReadyState().navigationSerial;
      controller.reportAnchor(midParagraphAnchor);

      await environment.updateSettings(
        (settings) => settings.copyWith(pageTurnMode: PageTurnMode.paged),
      );
      await pumpEventQueue();

      final readyState = readReadyState();
      expect(readyState.initialAnchor, midParagraphAnchor);
      expect(readyState.navigationSerial, greaterThan(serialBefore));
    });

    test('只改字号不会产生新的定位请求', () async {
      await openReader();
      final serialBefore = readReadyState().navigationSerial;

      await environment.updateSettings(
        (settings) => settings.copyWith(fontScale: 1.4),
      );
      await pumpEventQueue();

      expect(readReadyState().navigationSerial, serialBefore);
    });
  });
}

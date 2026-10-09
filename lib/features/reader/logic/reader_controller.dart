import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/reader_progress_constants.dart';
import '../../../core/constants/reader_setting_defaults.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/domain.dart';
import 'chapter_anchors.dart';
import 'reader_state.dart';
import 'sentence_queries.dart';
import 'throttled_progress_saver.dart';

/// 进度保存限速用的延时调度；测试里换成可手动触发的实现，不必真实等待。
final progressSaveSchedulerProvider = Provider<DelayedCallScheduler>(
  (ref) => Timer.new,
);

/// 一本书的阅读页状态与动作，参数为书的 id。离开阅读页后自动销毁。
final readerControllerProvider = NotifierProvider.autoDispose
    .family<ReaderController, ReaderState, String>(ReaderController.new);

/// 点一句话之后发生了什么。
enum SentenceTapOutcome {
  /// 开始播放这一句。
  started,

  /// 点的正是在播（或暂停中）的那一句，已停止。
  stopped,

  /// 语音无法播放，界面应给出提示。
  failed,

  /// 没有可播的语音，或正在换章，未做任何事。
  ignored,
}

/// 把加载时抛出的异常归类成界面能解释的原因。
ReaderFailureReason failureReasonOf(Exception error) {
  return switch (error) {
    BookNotFoundException() => ReaderFailureReason.bookNotFound,
    ChapterNotFoundException() => ReaderFailureReason.chapterNotFound,
    _ => ReaderFailureReason.unknown,
  };
}

/// 阅读页的编排：加载与换章、进度保存、点句播放。
class ReaderController extends Notifier<ReaderState> {
  ReaderController(this.bookId);

  final String bookId;

  late BookRepository _bookRepository;
  late ReadingProgressRepository _progressRepository;
  late AudioPlaybackService _playbackService;
  late ThrottledProgressSaver _progressSaver;

  List<ChapterSummary> _chapters = const [];

  /// 视图最近一次回报的锚点。不放进状态里，免得每滚过一行都重建界面。
  ReadingAnchor _latestAnchor = chapterStartAnchor;
  SentenceRef? _activeSentence;
  int _navigationSerial = 0;

  /// 最近一次加载的编号。加载是异步的，用户可能在它完成前又发起一次，
  /// 靠编号认出并丢弃过期的结果。
  int _latestLoadId = 0;
  bool _isLoading = false;

  @override
  ReaderState build() {
    _bookRepository = ref.watch(bookRepositoryProvider);
    _progressRepository = ref.watch(readingProgressRepositoryProvider);
    _playbackService = ref.watch(audioPlaybackServiceProvider);
    _progressSaver = ThrottledProgressSaver(
      interval: ReaderProgressConstants.saveInterval,
      savePosition: _progressRepository.savePosition,
      scheduleDelayedCall: ref.watch(progressSaveSchedulerProvider),
    );
    ref.listen(
      playbackStateProvider,
      (_, playbackState) => _activeSentence = playbackState.value?.sentence,
      fireImmediately: true,
    );
    ref.listen(readerSettingsProvider, _handleSettingsChanged);
    ref.onDispose(_leavePage);
    unawaited(_openAtSavedPosition());
    return const ReaderLoading();
  }

  /// 加载失败后重新打开。
  Future<void> retry() {
    state = const ReaderLoading();
    return _openAtSavedPosition();
  }

  /// 从目录跳到第 [chapterIndex] 章，落在章首。
  Future<void> openChapterFromContents(int chapterIndex) {
    return _changeChapter(chapterIndex, (_) => chapterStartAnchor);
  }

  /// 进下一章，落在章首；已是最后一章时不做任何事。
  Future<void> goToNextChapter() async {
    final nextChapterIndex = _readyState?.nextChapterIndex;
    if (nextChapterIndex != null) {
      await _changeChapter(nextChapterIndex, (_) => chapterStartAnchor);
    }
  }

  /// 回上一章，落在章末（接着往回读）；已是第一章时不做任何事。
  Future<void> goToPreviousChapter() async {
    final previousChapterIndex = _readyState?.previousChapterIndex;
    if (previousChapterIndex != null) {
      await _changeChapter(
        previousChapterIndex,
        (chapter) => resolveChapterEndAnchor(chapter, _displayMode),
      );
    }
  }

  /// 视图回报当前阅读锚点；进度按限速保存。
  void reportAnchor(ReadingAnchor anchor) {
    final readyState = _readyState;
    // 换章途中旧视图还可能回报一次，那已经不是要记的位置了。
    if (readyState == null || _isLoading) {
      return;
    }
    _latestAnchor = anchor;
    _progressSaver.schedule(
      ReadingPosition(
        bookId: bookId,
        chapterIndex: readyState.currentChapterIndex,
        anchor: anchor,
      ),
    );
  }

  /// 点句播放：点的正是在播（或暂停中）的那一句就停止，否则改播这一句。
  Future<SentenceTapOutcome> toggleSentencePlayback(
    SentenceRef sentence,
  ) async {
    final readyState = _readyState;
    if (readyState == null || _isLoading) {
      return SentenceTapOutcome.ignored;
    }
    if (sentence == _activeSentence) {
      await _stopPlayback();
      return SentenceTapOutcome.stopped;
    }
    final clip = findAudioClip(readyState.chapter, sentence);
    if (clip == null) {
      return SentenceTapOutcome.ignored;
    }
    return _play(sentence, clip);
  }

  Future<SentenceTapOutcome> _play(SentenceRef sentence, AudioClip clip) async {
    try {
      await _playbackService.play(sentence: sentence, clip: clip);
    } on AudioPlaybackFailedException {
      return SentenceTapOutcome.failed;
    }
    // 播放状态经由流异步送达；先记下来，紧接着再点同一句才能认出是「停止」。
    _activeSentence = sentence;
    return SentenceTapOutcome.started;
  }

  Future<void> _stopPlayback() async {
    await _playbackService.stop();
    _activeSentence = null;
  }

  ReaderReady? get _readyState {
    final currentState = state;
    return currentState is ReaderReady ? currentState : null;
  }

  BilingualDisplayMode get _displayMode {
    final settings = ref.read(readerSettingsProvider).value;
    return (settings ?? defaultReaderSettings).displayMode;
  }

  Future<void> _openAtSavedPosition() async {
    final loadId = _beginLoad();
    try {
      final chapters = await _bookRepository.listChapters(bookId);
      if (chapters.isEmpty) {
        _showFailure(loadId, ReaderFailureReason.emptyBook);
        return;
      }
      final startingPosition = resolveStartingPosition(
        bookId: bookId,
        chapters: chapters,
        savedPosition: await _progressRepository.loadPosition(bookId),
      );
      final chapter = await _bookRepository.loadChapter(
        bookId,
        startingPosition.chapterIndex,
      );
      if (_isStale(loadId)) {
        return;
      }
      _chapters = chapters;
      _showChapter(chapter, startingPosition.anchor);
    } on Exception catch (error) {
      _showFailure(loadId, failureReasonOf(error));
    } finally {
      _endLoad(loadId);
    }
  }

  /// 换到第 [chapterIndex] 章，落点由 [resolveAnchor] 根据加载到的章节决定。
  Future<void> _changeChapter(
    int chapterIndex,
    ReadingAnchor Function(Chapter chapter) resolveAnchor,
  ) async {
    final loadId = _beginLoad();
    // 万一目标章加载失败，至少当前章读到的位置已经存下了。
    _progressSaver.flush();
    try {
      // 播放服务不认识章节；不先停掉，旧章的句子定位会被新章拿去高亮。
      await _stopPlayback();
      final chapter = await _bookRepository.loadChapter(bookId, chapterIndex);
      if (_isStale(loadId)) {
        return;
      }
      final anchor = resolveAnchor(chapter);
      _showChapter(chapter, anchor);
      // 不等视图回报：用户换章后立刻退出，也要回到新的一章。
      _progressSaver.saveNow(
        ReadingPosition(
          bookId: bookId,
          chapterIndex: chapterIndex,
          anchor: anchor,
        ),
      );
    } on Exception catch (error) {
      _showFailure(loadId, failureReasonOf(error));
    } finally {
      _endLoad(loadId);
    }
  }

  int _beginLoad() {
    _isLoading = true;
    return ++_latestLoadId;
  }

  void _endLoad(int loadId) {
    if (loadId == _latestLoadId) {
      _isLoading = false;
    }
  }

  /// 这次加载期间又发起了新的加载，或页面已经离开。
  bool _isStale(int loadId) => loadId != _latestLoadId || !ref.mounted;

  void _showChapter(Chapter chapter, ReadingAnchor anchor) {
    _latestAnchor = anchor;
    state = ReaderReady(
      chapters: _chapters,
      chapter: chapter,
      initialAnchor: anchor,
      navigationSerial: ++_navigationSerial,
    );
  }

  void _showFailure(int loadId, ReaderFailureReason reason) {
    if (!_isStale(loadId)) {
      state = ReaderFailure(reason);
    }
  }

  void _handleSettingsChanged(
    AsyncValue<ReaderSettings>? previous,
    AsyncValue<ReaderSettings> next,
  ) {
    final settings = next.value;
    if (settings == null) {
      return;
    }
    final previousSettings = previous?.value;
    if (previousSettings?.displayMode != settings.displayMode) {
      _stopIfActiveSentenceHidden(settings.displayMode);
    }
    final isPageTurnModeChanged =
        previousSettings != null &&
        previousSettings.pageTurnMode != settings.pageTurnMode;
    if (isPageTurnModeChanged) {
      _repositionViewAtLatestAnchor();
    }
  }

  void _stopIfActiveSentenceHidden(BilingualDisplayMode displayMode) {
    final readyState = _readyState;
    final activeSentence = _activeSentence;
    if (readyState == null || activeSentence == null) {
      return;
    }
    final isStillDisplayed = isSentenceDisplayed(
      chapter: readyState.chapter,
      sentence: activeSentence,
      displayMode: displayMode,
    );
    if (!isStillDisplayed) {
      unawaited(_stopPlayback());
    }
  }

  /// 滚动与翻页是两个视图，切换后新视图要从用户刚才读到的地方开始，
  /// 而不是回到进入这一章时的位置。
  void _repositionViewAtLatestAnchor() {
    final readyState = _readyState;
    if (readyState == null) {
      return;
    }
    state = readyState.copyWith(
      initialAnchor: _latestAnchor,
      navigationSerial: ++_navigationSerial,
    );
  }

  void _leavePage() {
    _progressSaver.flush();
    unawaited(_playbackService.stop());
  }
}

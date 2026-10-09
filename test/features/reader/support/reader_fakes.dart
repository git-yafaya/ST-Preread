import 'dart:async';

import 'package:st_preread/data/mock/mock_audio_playback_service.dart';
import 'package:st_preread/domain/domain.dart';

import '../../../support/manual_playback_ticker.dart';

/// 只提供阅读页用得到的章节读取；调用顺序记进 [log]，便于断言「先停再加载」。
class FakeBookRepository implements BookRepository {
  FakeBookRepository({
    required this.bookId,
    required this.chapters,
    List<String>? log,
  }) : log = log ?? [];

  final String bookId;
  final List<Chapter> chapters;
  final List<String> log;

  /// 不为 null 时，读取目录要等它完成，用来停在「加载中」。
  Completer<void>? listChaptersGate;

  /// 不为 null 时，读取目录直接抛出它。
  Exception? listChaptersError;

  /// 这些章节下标读取时抛 ChapterNotFoundException。
  final Set<int> missingChapterIndexes = {};

  @override
  Future<List<ChapterSummary>> listChapters(String bookId) async {
    await listChaptersGate?.future;
    final error = listChaptersError;
    if (error != null) {
      throw error;
    }
    if (bookId != this.bookId) {
      throw BookNotFoundException(bookId);
    }
    return [for (final chapter in chapters) chapter.summary];
  }

  @override
  Future<Chapter> loadChapter(String bookId, int chapterIndex) async {
    log.add('loadChapter:$chapterIndex');
    final isMissing =
        chapterIndex < 0 ||
        chapterIndex >= chapters.length ||
        missingChapterIndexes.contains(chapterIndex);
    if (isMissing) {
      throw ChapterNotFoundException(
        bookId: bookId,
        chapterIndex: chapterIndex,
      );
    }
    return chapters[chapterIndex];
  }

  @override
  Stream<List<Book>> watchBooks() => throw UnimplementedError();

  @override
  Future<Book> importBook(String sourcePath) => throw UnimplementedError();

  @override
  Future<void> deleteBook(String bookId) => throw UnimplementedError();
}

/// 记录每一次保存的进度仓库。
class RecordingProgressRepository implements ReadingProgressRepository {
  RecordingProgressRepository({ReadingPosition? savedPosition})
    : _storedPosition = savedPosition;

  ReadingPosition? _storedPosition;

  /// 按保存顺序排列的全部位置。
  final List<ReadingPosition> savedPositions = [];

  @override
  Future<ReadingPosition?> loadPosition(String bookId) async {
    return _storedPosition;
  }

  @override
  Future<void> savePosition(ReadingPosition position) async {
    _storedPosition = position;
    savedPositions.add(position);
  }
}

/// 记录调用的播放服务：状态机沿用假播放器（时间手动拨动），外加调用记录与可控的播放失败。
class RecordingPlaybackService implements AudioPlaybackService {
  RecordingPlaybackService({List<String>? log}) : log = log ?? [];

  final List<String> log;
  final ManualPlaybackTicker ticker = ManualPlaybackTicker();
  late final MockAudioPlaybackService _delegate = MockAudioPlaybackService(
    ticker: ticker,
  );

  final List<({SentenceRef sentence, AudioClip clip})> playRequests = [];
  int stopCallCount = 0;

  /// 为 true 时 play 抛 AudioPlaybackFailedException，状态回到 idle。
  bool shouldFailToPlay = false;

  @override
  Stream<PlaybackState> watchState() => _delegate.watchState();

  @override
  Future<void> play({
    required SentenceRef sentence,
    required AudioClip clip,
  }) async {
    log.add('play');
    playRequests.add((sentence: sentence, clip: clip));
    if (shouldFailToPlay) {
      await _delegate.stop();
      throw AudioPlaybackFailedException(clip: clip);
    }
    await _delegate.play(sentence: sentence, clip: clip);
  }

  @override
  Future<void> pause() => _delegate.pause();

  @override
  Future<void> resume() => _delegate.resume();

  @override
  Future<void> stop() {
    log.add('stop');
    stopCallCount++;
    return _delegate.stop();
  }

  Future<void> dispose() => _delegate.dispose();
}

/// 手动触发的延时调度：测试决定「时间到了」，不依赖真实等待。
class ManualDelayedCallScheduler {
  final List<_ManualTimer> _timers = [];

  /// 历次调度传入的延时。
  final List<Duration> requestedDelays = [];

  int get activeTimerCount => _timers.where((timer) => timer.isActive).length;

  Timer schedule(Duration delay, void Function() callback) {
    requestedDelays.add(delay);
    final timer = _ManualTimer(callback);
    _timers.add(timer);
    return timer;
  }

  /// 让所有还没取消的延时到期。
  void elapse() {
    for (final timer in _timers.toList()) {
      timer.fire();
    }
  }
}

class _ManualTimer implements Timer {
  _ManualTimer(this._callback);

  final void Function() _callback;

  @override
  bool isActive = true;

  @override
  int get tick => 0;

  @override
  void cancel() {
    isActive = false;
  }

  void fire() {
    if (!isActive) {
      return;
    }
    isActive = false;
    _callback();
  }
}

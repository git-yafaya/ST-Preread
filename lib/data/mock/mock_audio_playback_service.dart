import 'dart:math' as math;

import '../../core/constants/mock_playback_timing.dart';
import '../../core/errors/domain_exceptions.dart';
import '../../domain/domain.dart';
import 'latest_value_broadcaster.dart';
import 'playback_ticker.dart';

/// 播放队列中的一项：句子定位与推算出的时长。
typedef _QueueEntry = ({SentenceRef sentence, Duration duration});

/// 不发声的假播放器：按句子长度推算时长，随时间源逐句推进。
class MockAudioPlaybackService implements AudioPlaybackService {
  MockAudioPlaybackService({PlaybackTicker? ticker})
    : _ticker = ticker ?? TimerPlaybackTicker();

  final PlaybackTicker _ticker;
  final LatestValueBroadcaster<PlaybackState> _state =
      LatestValueBroadcaster<PlaybackState>(const PlaybackState.idle());

  List<_QueueEntry> _queue = const [];

  /// 当前句在队列中的下标；idle 时为 null。
  int? _currentQueueIndex;

  @override
  Stream<PlaybackState> watchState() => _state.watch();

  @override
  Future<void> loadChapter(Chapter chapter, TextSide side) async {
    _stopPlayback();
    _queue = [
      for (final sentence in listPlayableSentences(chapter, side))
        (sentence: sentence, duration: _estimateDuration(chapter, sentence)),
    ];
  }

  @override
  Future<void> playFrom(SentenceRef sentence) async {
    final queueIndex = _queue.indexWhere((entry) => entry.sentence == sentence);
    if (queueIndex < 0) {
      throw SentenceNotPlayableException(sentence);
    }
    _enterSentence(queueIndex, PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    if (_state.value.status != PlaybackStatus.playing) {
      return;
    }
    _ticker.stop();
    _state.emit(_state.value.copyWith(status: PlaybackStatus.paused));
  }

  @override
  Future<void> resume() async {
    if (_state.value.status != PlaybackStatus.paused) {
      return;
    }
    _state.emit(_state.value.copyWith(status: PlaybackStatus.playing));
    _ticker.start(MockPlaybackTiming.tickInterval, _advancePosition);
  }

  @override
  Future<void> skipToNextSentence() async {
    final currentQueueIndex = _currentQueueIndex;
    if (currentQueueIndex == null) {
      return;
    }
    _moveToQueueIndex(currentQueueIndex + 1);
  }

  @override
  Future<void> skipToPreviousSentence() async {
    final currentQueueIndex = _currentQueueIndex;
    if (currentQueueIndex == null) {
      return;
    }
    _moveToQueueIndex(math.max(currentQueueIndex - 1, 0));
  }

  @override
  Future<void> stop() async => _stopPlayback();

  /// 释放时间源与状态流；之后不应再使用本实例。
  Future<void> dispose() {
    _ticker.stop();
    return _state.close();
  }

  Duration _estimateDuration(Chapter chapter, SentenceRef sentenceRef) {
    final paragraph = chapter.blocks[sentenceRef.blockIndex] as ParagraphBlock;
    final sentences = paragraph.textOf(sentenceRef.side)?.sentences ?? const [];
    final characterCount = sentences[sentenceRef.sentenceIndex].length;
    return MockPlaybackTiming.durationPerCharacter * characterCount;
  }

  void _advancePosition() {
    final currentQueueIndex = _currentQueueIndex;
    if (currentQueueIndex == null) {
      return;
    }
    final nextPosition =
        _state.value.position + MockPlaybackTiming.tickInterval;
    if (nextPosition < _queue[currentQueueIndex].duration) {
      _state.emit(_state.value.copyWith(position: nextPosition));
      return;
    }
    _moveToQueueIndex(currentQueueIndex + 1);
  }

  /// 换到队列中的另一句并保持原有的播放 / 暂停状态；越过队尾则停止。
  void _moveToQueueIndex(int queueIndex) {
    if (queueIndex >= _queue.length) {
      _stopPlayback();
      return;
    }
    _enterSentence(queueIndex, _state.value.status);
  }

  void _enterSentence(int queueIndex, PlaybackStatus status) {
    final entry = _queue[queueIndex];
    _currentQueueIndex = queueIndex;
    _state.emit(
      PlaybackState(
        status: status,
        sentence: entry.sentence,
        position: Duration.zero,
        duration: entry.duration,
      ),
    );
    _synchronizeTicker(status);
  }

  /// 每进入一句都重新起一轮计时，让新句子从完整的一个间隔开始计。
  void _synchronizeTicker(PlaybackStatus status) {
    if (status == PlaybackStatus.playing) {
      _ticker.start(MockPlaybackTiming.tickInterval, _advancePosition);
      return;
    }
    _ticker.stop();
  }

  void _stopPlayback() {
    _ticker.stop();
    _currentQueueIndex = null;
    if (_state.value != const PlaybackState.idle()) {
      _state.emit(const PlaybackState.idle());
    }
  }
}

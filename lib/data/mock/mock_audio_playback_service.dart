import '../../domain/domain.dart';
import 'latest_value_broadcaster.dart';
import 'mock_playback_timing.dart';
import 'playback_ticker.dart';

/// 不发声的假播放器：一次只播一句，按语音片段的时长推进位置，到时长即回到 idle。
class MockAudioPlaybackService implements AudioPlaybackService {
  MockAudioPlaybackService({PlaybackTicker? ticker})
    : _ticker = ticker ?? TimerPlaybackTicker();

  final PlaybackTicker _ticker;
  final LatestValueBroadcaster<PlaybackState> _state =
      LatestValueBroadcaster<PlaybackState>(const PlaybackState.idle());

  /// 当前这一轮计时的序号，每次开始或停止计时都加一。
  /// 计时回调带着自己那一轮的序号，对不上就说明它属于已被打断的旧句子，必须丢弃：
  /// 时间源即使在停掉之后又迟到地回调一次，也不能让旧句子再发出状态。
  int _tickingRound = 0;

  @override
  Stream<PlaybackState> watchState() => _state.watch();

  @override
  Future<void> play({
    required SentenceRef sentence,
    required AudioClip clip,
  }) async {
    _state.emit(
      PlaybackState(
        status: PlaybackStatus.playing,
        sentence: sentence,
        position: Duration.zero,
        duration: _durationOf(clip),
      ),
    );
    _startTicking();
  }

  @override
  Future<void> pause() async {
    if (_state.value.status != PlaybackStatus.playing) {
      return;
    }
    _stopTicking();
    _state.emit(_state.value.copyWith(status: PlaybackStatus.paused));
  }

  @override
  Future<void> resume() async {
    if (_state.value.status != PlaybackStatus.paused) {
      return;
    }
    _state.emit(_state.value.copyWith(status: PlaybackStatus.playing));
    _startTicking();
  }

  @override
  Future<void> stop() async {
    if (_state.value.status == PlaybackStatus.idle) {
      return;
    }
    _returnToIdle();
  }

  /// 释放时间源与状态流；之后不应再使用本实例。
  Future<void> dispose() {
    _stopTicking();
    return _state.close();
  }

  /// 假播放器不读文件，时长只能来自片段自带的区间。
  Duration _durationOf(AudioClip clip) {
    final end = clip.end;
    if (end == null) {
      return MockPlaybackTiming.fallbackClipDuration;
    }
    return end - (clip.start ?? Duration.zero);
  }

  void _startTicking() {
    final round = ++_tickingRound;
    _ticker.start(
      MockPlaybackTiming.tickInterval,
      () => _advancePosition(round),
    );
  }

  void _stopTicking() {
    _tickingRound++;
    _ticker.stop();
  }

  void _advancePosition(int round) {
    if (round != _tickingRound) {
      return;
    }
    final current = _state.value;
    final nextPosition = current.position + MockPlaybackTiming.tickInterval;
    final duration = current.duration;
    if (duration != null && nextPosition >= duration) {
      _returnToIdle();
      return;
    }
    _state.emit(current.copyWith(position: nextPosition));
  }

  void _returnToIdle() {
    _stopTicking();
    _state.emit(const PlaybackState.idle());
  }
}

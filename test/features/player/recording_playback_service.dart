import 'dart:async';

import 'package:st_preread/domain/domain.dart';

/// 由测试直接指定状态、并记下被调用了哪些控制方法的播放服务。
///
/// 用它可以摆出假播放器摆不出来的状态（如时长未知），
/// 也能在不依赖状态机的情况下断言播放条到底调用了什么。
class RecordingPlaybackService implements AudioPlaybackService {
  /// 传入 null 表示「订阅后迟迟没有收到任何状态」。
  RecordingPlaybackService({PlaybackState? initialState})
    : _currentState = initialState;

  final StreamController<PlaybackState> _updates =
      StreamController<PlaybackState>.broadcast();
  PlaybackState? _currentState;

  /// 按调用顺序记录的控制方法名。
  final List<String> controlCalls = [];

  void emit(PlaybackState state) {
    _currentState = state;
    _updates.add(state);
  }

  @override
  Stream<PlaybackState> watchState() {
    return Stream<PlaybackState>.multi((subscriber) {
      final currentState = _currentState;
      if (currentState != null) {
        subscriber.add(currentState);
      }
      final subscription = _updates.stream.listen(subscriber.add);
      subscriber.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> play({
    required SentenceRef sentence,
    required AudioClip clip,
  }) async {
    controlCalls.add('play');
  }

  @override
  Future<void> pause() async {
    controlCalls.add('pause');
  }

  @override
  Future<void> resume() async {
    controlCalls.add('resume');
  }

  @override
  Future<void> stop() async {
    controlCalls.add('stop');
  }

  Future<void> dispose() => _updates.close();
}

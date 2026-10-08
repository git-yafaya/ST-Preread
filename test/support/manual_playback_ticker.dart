import 'package:st_preread/data/mock/playback_ticker.dart';

/// 由测试手动拨动的时间源：不依赖真实时间，播放推进完全可控。
class ManualPlaybackTicker implements PlaybackTicker {
  /// 历次 start 传入的回调。保留已被取代或停掉的回调，
  /// 是为了让测试能模拟「旧一轮计时迟到地又回调了一次」。
  final List<void Function()> _startedCallbacks = [];

  void Function()? _onTick;

  /// 最近一次 start 传入的间隔。
  Duration? lastInterval;

  bool get isRunning => _onTick != null;

  @override
  void start(Duration interval, void Function() onTick) {
    lastInterval = interval;
    _onTick = onTick;
    _startedCallbacks.add(onTick);
  }

  @override
  void stop() {
    _onTick = null;
  }

  /// 模拟流逝 [times] 个间隔；未在运行时什么也不发生，与真实定时器一致。
  void tick({int times = 1}) {
    for (var count = 0; count < times; count++) {
      _onTick?.call();
    }
  }

  /// 让所有已经不是当前一轮的旧回调各触发一次，模拟迟到的计时事件。
  void fireStaleCallbacks() {
    final staleCallbacks = _startedCallbacks
        .where((callback) => !identical(callback, _onTick))
        .toList();
    for (final staleCallback in staleCallbacks) {
      staleCallback();
    }
  }
}

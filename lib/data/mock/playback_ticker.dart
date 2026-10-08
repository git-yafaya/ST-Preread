import 'dart:async';

/// 假播放器的时间源。
///
/// 抽成接口是为了让测试可以手动拨动时间，不必真实等待。
abstract interface class PlaybackTicker {
  /// 开始按 [interval] 周期性回调 [onTick]；已在运行时先停掉上一轮。
  void start(Duration interval, void Function() onTick);

  void stop();
}

/// 基于系统定时器的时间源，供应用实际运行时使用。
class TimerPlaybackTicker implements PlaybackTicker {
  Timer? _timer;

  @override
  void start(Duration interval, void Function() onTick) {
    stop();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

import 'package:st_preread/data/mock/playback_ticker.dart';

/// 由测试手动拨动的时间源：不依赖真实时间，播放推进完全可控。
class ManualPlaybackTicker implements PlaybackTicker {
  void Function()? _onTick;

  /// 最近一次 start 传入的间隔。
  Duration? lastInterval;

  bool get isRunning => _onTick != null;

  @override
  void start(Duration interval, void Function() onTick) {
    lastInterval = interval;
    _onTick = onTick;
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
}

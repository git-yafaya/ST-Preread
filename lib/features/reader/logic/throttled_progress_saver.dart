import 'dart:async';

import '../../../domain/domain.dart';

/// 过一段时间后调用一次 [callback]；抽成函数类型是为了让测试可以手动拨动时间。
typedef DelayedCallScheduler = Timer Function(
  Duration delay,
  void Function() callback,
);

/// 保存一个阅读位置。
typedef ReadingPositionSaver = Future<void> Function(ReadingPosition position);

/// 给进度保存限速：滚动时锚点每换一行就变一次，没必要每次都写。
///
/// 一个间隔内无论收到多少次位置，都只在间隔结束时保存最后一次；
/// 换章、离开页面这类不能丢的时刻可以绕过限速立即保存。
class ThrottledProgressSaver {
  ThrottledProgressSaver({
    required this.interval,
    required this.savePosition,
    required this.scheduleDelayedCall,
  });

  final Duration interval;
  final ReadingPositionSaver savePosition;
  final DelayedCallScheduler scheduleDelayedCall;

  ReadingPosition? _pendingPosition;
  Timer? _timer;

  /// 记下最新位置，最迟在一个 [interval] 之后保存。
  void schedule(ReadingPosition position) {
    _pendingPosition = position;
    _timer ??= scheduleDelayedCall(interval, flush);
  }

  /// 立即保存 [position]，并丢弃还没来得及保存的旧位置。
  void saveNow(ReadingPosition position) {
    _pendingPosition = position;
    flush();
  }

  /// 有尚未保存的位置就立即保存；没有则什么也不做。
  void flush() {
    _timer?.cancel();
    _timer = null;
    final position = _pendingPosition;
    if (position == null) {
      return;
    }
    _pendingPosition = null;
    unawaited(savePosition(position));
  }
}

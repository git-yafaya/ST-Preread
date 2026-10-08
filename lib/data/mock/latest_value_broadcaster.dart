import 'dart:async';

/// 保存最新值的广播源：新订阅者先立即收到当前值，再收到后续变化。
///
/// 普通广播流不会向后来的订阅者补发已有的值，
/// 而界面随时可能开始订阅，必须一订阅就拿到当前状态。
class LatestValueBroadcaster<T> {
  LatestValueBroadcaster(T initialValue) : _value = initialValue;

  final StreamController<T> _updates = StreamController<T>.broadcast();
  T _value;

  T get value => _value;

  void emit(T newValue) {
    _value = newValue;
    _updates.add(newValue);
  }

  Stream<T> watch() {
    return Stream<T>.multi((subscriber) {
      subscriber.add(_value);
      final subscription = _updates.stream.listen(
        subscriber.add,
        onDone: subscriber.close,
      );
      subscriber.onCancel = subscription.cancel;
    });
  }

  Future<void> close() => _updates.close();
}

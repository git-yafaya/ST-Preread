import 'dart:async';

import 'package:st_preread/domain/domain.dart';

/// 记下每次保存内容的设置仓库，并能摆出「迟迟读不到」「读取失败」两种情形。
class RecordingReaderSettingsRepository implements ReaderSettingsRepository {
  /// [initialSettings] 为 null 表示订阅后迟迟收不到设置。
  RecordingReaderSettingsRepository({ReaderSettings? initialSettings})
    : _currentSettings = initialSettings;

  final StreamController<ReaderSettings> _updates =
      StreamController<ReaderSettings>.broadcast();
  ReaderSettings? _currentSettings;

  /// 非 null 时，新的订阅收到的是这个错误而不是设置。
  Exception? loadFailure;

  /// 按保存顺序记录的设置。
  final List<ReaderSettings> savedSettings = [];

  /// 不经过 saveSettings 直接换掉当前设置，模拟「后来读到了」。
  void provideSettings(ReaderSettings settings) {
    _currentSettings = settings;
    _updates.add(settings);
  }

  @override
  Stream<ReaderSettings> watchSettings() {
    return Stream<ReaderSettings>.multi((subscriber) {
      final failure = loadFailure;
      if (failure != null) {
        subscriber.addError(failure);
        return;
      }
      final currentSettings = _currentSettings;
      if (currentSettings != null) {
        subscriber.add(currentSettings);
      }
      final subscription = _updates.stream.listen(subscriber.add);
      subscriber.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> saveSettings(ReaderSettings settings) async {
    savedSettings.add(settings);
    provideSettings(settings);
  }

  Future<void> dispose() => _updates.close();
}

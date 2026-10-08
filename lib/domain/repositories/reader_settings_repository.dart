import '../entities/reader_settings.dart';

/// 阅读设置的存取。
abstract interface class ReaderSettingsRepository {
  /// 订阅后立即收到当前设置，之后每次保存再推送。
  Stream<ReaderSettings> watchSettings();

  Future<void> saveSettings(ReaderSettings settings);
}

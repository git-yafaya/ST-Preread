import '../../core/constants/reader_setting_limits.dart';
import '../../domain/domain.dart';
import 'latest_value_broadcaster.dart';

/// 只在内存里保存设置的假实现：本次运行内有效，重启后恢复默认值。
class MockReaderSettingsRepository implements ReaderSettingsRepository {
  MockReaderSettingsRepository({
    ReaderSettings initialSettings = defaultSettings,
  }) : _settings = LatestValueBroadcaster<ReaderSettings>(initialSettings);

  static const ReaderSettings defaultSettings = ReaderSettings(
    fontScale: ReaderSettingLimits.defaultFontScale,
    themeMode: ReaderThemeMode.system,
    pageTurnMode: PageTurnMode.scroll,
    displayMode: BilingualDisplayMode.both,
  );

  final LatestValueBroadcaster<ReaderSettings> _settings;

  @override
  Stream<ReaderSettings> watchSettings() => _settings.watch();

  @override
  Future<void> saveSettings(ReaderSettings settings) async {
    _settings.emit(settings);
  }

  Future<void> dispose() => _settings.close();
}

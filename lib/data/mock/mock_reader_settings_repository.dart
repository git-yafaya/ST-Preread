import '../../domain/domain.dart';
import 'latest_value_broadcaster.dart';

/// 只在内存里保存设置的假实现：本次运行内有效，重启后恢复为 [initialSettings]。
class MockReaderSettingsRepository implements ReaderSettingsRepository {
  /// 默认设置由绑定处传入：数据层只依赖领域层，不自己决定应用的默认值。
  MockReaderSettingsRepository({required ReaderSettings initialSettings})
    : _settings = LatestValueBroadcaster<ReaderSettings>(initialSettings);

  final LatestValueBroadcaster<ReaderSettings> _settings;

  @override
  Stream<ReaderSettings> watchSettings() => _settings.watch();

  @override
  Future<void> saveSettings(ReaderSettings settings) async {
    _settings.emit(settings);
  }

  Future<void> dispose() => _settings.close();
}

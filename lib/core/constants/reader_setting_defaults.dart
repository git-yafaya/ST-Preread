import '../../domain/entities/reader_settings.dart';
import 'reader_setting_limits.dart';

/// 首次启动、尚未保存过任何设置时使用的阅读设置。
///
/// 放在 core 而不是某个仓库实现里，这样换用别的存储实现时默认值不必跟着搬。
const ReaderSettings defaultReaderSettings = ReaderSettings(
  fontScale: ReaderSettingLimits.defaultFontScale,
  themeMode: ReaderThemeMode.system,
  pageTurnMode: PageTurnMode.scroll,
  displayMode: BilingualDisplayMode.both,
);

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/constants/reader_setting_limits.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  test('默认阅读设置：默认字号、跟随系统、滚动、双语对照', () {
    expect(
      defaultReaderSettings,
      const ReaderSettings(
        fontScale: ReaderSettingLimits.defaultFontScale,
        themeMode: ReaderThemeMode.system,
        pageTurnMode: PageTurnMode.scroll,
        displayMode: BilingualDisplayMode.both,
      ),
    );
  });
}

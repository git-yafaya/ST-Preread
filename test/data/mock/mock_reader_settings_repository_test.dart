import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_limits.dart';
import 'package:st_preread/data/mock/mock_reader_settings_repository.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  group('MockReaderSettingsRepository', () {
    test('初始为默认设置', () async {
      final repository = MockReaderSettingsRepository();
      addTearDown(repository.dispose);

      final settings = await repository.watchSettings().first;

      expect(settings, MockReaderSettingsRepository.defaultSettings);
      expect(settings.fontScale, ReaderSettingLimits.defaultFontScale);
      expect(settings.themeMode, ReaderThemeMode.system);
    });

    test('可以指定初始设置', () async {
      final initialSettings = MockReaderSettingsRepository.defaultSettings
          .copyWith(pageTurnMode: PageTurnMode.paged);
      final repository = MockReaderSettingsRepository(
        initialSettings: initialSettings,
      );
      addTearDown(repository.dispose);

      expect(await repository.watchSettings().first, initialSettings);
    });

    test('保存后推送新设置，之后的订阅者也拿到新设置', () async {
      final repository = MockReaderSettingsRepository();
      final received = <ReaderSettings>[];
      final subscription = repository.watchSettings().listen(received.add);
      addTearDown(subscription.cancel);
      addTearDown(repository.dispose);
      final enlarged = MockReaderSettingsRepository.defaultSettings.copyWith(
        fontScale: ReaderSettingLimits.maxFontScale,
      );

      await repository.saveSettings(enlarged);
      await pumpEventQueue();

      expect(received, [
        MockReaderSettingsRepository.defaultSettings,
        enlarged,
      ]);
      expect(await repository.watchSettings().first, enlarged);
    });
  });
}

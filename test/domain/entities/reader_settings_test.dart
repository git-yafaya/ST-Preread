import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const settings = ReaderSettings(
    fontScale: 1.2,
    themeMode: ReaderThemeMode.dark,
    pageTurnMode: PageTurnMode.paged,
    displayMode: BilingualDisplayMode.translationOnly,
  );

  group('ReaderSettings', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameSettings = ReaderSettings(
        fontScale: 1.2,
        themeMode: ReaderThemeMode.dark,
        pageTurnMode: PageTurnMode.paged,
        displayMode: BilingualDisplayMode.translationOnly,
      );
      expect(settings, sameSettings);
      expect(settings.hashCode, sameSettings.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(settings.copyWith(fontScale: 1.3), isNot(settings));
      expect(
        settings.copyWith(themeMode: ReaderThemeMode.light),
        isNot(settings),
      );
      expect(
        settings.copyWith(pageTurnMode: PageTurnMode.scroll),
        isNot(settings),
      );
      expect(
        settings.copyWith(displayMode: BilingualDisplayMode.both),
        isNot(settings),
      );
    });

    test('copyWith 只替换传入的字段', () {
      final enlarged = settings.copyWith(fontScale: 1.5);
      expect(enlarged.fontScale, 1.5);
      expect(enlarged.themeMode, ReaderThemeMode.dark);
      expect(enlarged.pageTurnMode, PageTurnMode.paged);
      expect(enlarged.displayMode, BilingualDisplayMode.translationOnly);
      expect(settings.copyWith(), settings);
    });
  });
}

/// 各设置项的取值对应的显示文案。
library;

import '../../core/constants/settings_strings.dart';
import '../../domain/domain.dart';

String readerThemeModeLabel(ReaderThemeMode themeMode) {
  return switch (themeMode) {
    ReaderThemeMode.system => SettingsStrings.themeModeSystem,
    ReaderThemeMode.light => SettingsStrings.themeModeLight,
    ReaderThemeMode.dark => SettingsStrings.themeModeDark,
  };
}

String pageTurnModeLabel(PageTurnMode pageTurnMode) {
  return switch (pageTurnMode) {
    PageTurnMode.scroll => SettingsStrings.pageTurnModeScroll,
    PageTurnMode.paged => SettingsStrings.pageTurnModePaged,
  };
}

String bilingualDisplayModeLabel(BilingualDisplayMode displayMode) {
  return switch (displayMode) {
    BilingualDisplayMode.both => SettingsStrings.displayModeBoth,
    BilingualDisplayMode.translationOnly =>
      SettingsStrings.displayModeTranslationOnly,
    BilingualDisplayMode.sourceOnly => SettingsStrings.displayModeSourceOnly,
  };
}

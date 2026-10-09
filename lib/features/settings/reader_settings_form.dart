import 'package:flutter/material.dart';

import '../../core/constants/settings_layout_constants.dart';
import '../../core/constants/settings_strings.dart';
import '../../domain/domain.dart';
import 'font_scale_setting.dart';
import 'reader_setting_labels.dart';
import 'segmented_setting.dart';

/// 四项阅读设置的表单。
///
/// 自己不保存任何状态：显示传入的 [settings]，每次改动把完整的新设置交给
/// [onSettingsChanged]，由外层保存后再传回来。
class ReaderSettingsForm extends StatelessWidget {
  const ReaderSettingsForm({
    required this.settings,
    required this.onSettingsChanged,
    super.key,
  });

  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    const sectionGap = SizedBox(height: SettingsLayoutConstants.sectionSpacing);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFontScaleSetting(),
        sectionGap,
        _buildThemeModeSetting(),
        sectionGap,
        _buildPageTurnModeSetting(),
        sectionGap,
        _buildDisplayModeSetting(),
      ],
    );
  }

  Widget _buildFontScaleSetting() {
    return FontScaleSetting(
      fontScale: settings.fontScale,
      onFontScaleChanged: (fontScale) =>
          onSettingsChanged(settings.copyWith(fontScale: fontScale)),
    );
  }

  Widget _buildThemeModeSetting() {
    return SegmentedSetting<ReaderThemeMode>(
      title: SettingsStrings.themeModeTitle,
      options: ReaderThemeMode.values,
      labelOf: readerThemeModeLabel,
      selectedOption: settings.themeMode,
      onOptionSelected: (themeMode) =>
          onSettingsChanged(settings.copyWith(themeMode: themeMode)),
    );
  }

  Widget _buildPageTurnModeSetting() {
    return SegmentedSetting<PageTurnMode>(
      title: SettingsStrings.pageTurnModeTitle,
      options: PageTurnMode.values,
      labelOf: pageTurnModeLabel,
      selectedOption: settings.pageTurnMode,
      onOptionSelected: (pageTurnMode) =>
          onSettingsChanged(settings.copyWith(pageTurnMode: pageTurnMode)),
    );
  }

  Widget _buildDisplayModeSetting() {
    return SegmentedSetting<BilingualDisplayMode>(
      title: SettingsStrings.displayModeTitle,
      options: BilingualDisplayMode.values,
      labelOf: bilingualDisplayModeLabel,
      selectedOption: settings.displayMode,
      onOptionSelected: (displayMode) =>
          onSettingsChanged(settings.copyWith(displayMode: displayMode)),
    );
  }
}

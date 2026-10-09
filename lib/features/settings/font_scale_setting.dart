import 'package:flutter/material.dart';

import '../../core/constants/reader_setting_limits.dart';
import '../../core/constants/settings_strings.dart';
import 'font_scale_steps.dart';
import 'setting_section.dart';

/// 字号设置：滑块用于大幅调整，两端的按钮用于一格一格地微调。
class FontScaleSetting extends StatelessWidget {
  const FontScaleSetting({
    required this.fontScale,
    required this.onFontScaleChanged,
    super.key,
  });

  final double fontScale;
  final ValueChanged<double> onFontScaleChanged;

  @override
  Widget build(BuildContext context) {
    // 存下来的值万一不在范围内（如旧版本留下的数据），滑块会直接断言失败，
    // 所以显示前先收敛一次。
    final shownFontScale = snapFontScale(fontScale);
    return SettingSection(
      title: SettingsStrings.fontScaleTitle,
      trailing: Text(formatFontScale(shownFontScale)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: SettingsStrings.decreaseFontScaleTooltip,
            onPressed: canDecreaseFontScale(shownFontScale)
                ? () => onFontScaleChanged(decreaseFontScale(shownFontScale))
                : null,
          ),
          Expanded(child: _buildSlider(shownFontScale)),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: SettingsStrings.increaseFontScaleTooltip,
            onPressed: canIncreaseFontScale(shownFontScale)
                ? () => onFontScaleChanged(increaseFontScale(shownFontScale))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(double shownFontScale) {
    return Semantics(
      label: SettingsStrings.fontScaleTitle,
      child: Slider(
        value: shownFontScale,
        min: ReaderSettingLimits.minFontScale,
        max: ReaderSettingLimits.maxFontScale,
        divisions: fontScaleDivisions(),
        label: formatFontScale(shownFontScale),
        semanticFormatterCallback: formatFontScale,
        onChanged: (rawFontScale) =>
            onFontScaleChanged(snapFontScale(rawFontScale)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'setting_section.dart';

/// 在几个互斥选项里单选的一项设置。
class SegmentedSetting<OptionT> extends StatelessWidget {
  const SegmentedSetting({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selectedOption,
    required this.onOptionSelected,
    super.key,
  });

  final String title;
  final List<OptionT> options;
  final String Function(OptionT option) labelOf;
  final OptionT selectedOption;
  final ValueChanged<OptionT> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return SettingSection(
      title: title,
      child: SegmentedButton<OptionT>(
        segments: [
          for (final option in options)
            ButtonSegment<OptionT>(value: option, label: Text(labelOf(option))),
        ],
        selected: {selectedOption},
        // 选中态已由底色区分；不显示对勾，三个四字选项在窄屏上才排得下。
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onOptionSelected(selection.single),
      ),
    );
  }
}

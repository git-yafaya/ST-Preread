import 'package:flutter/material.dart';

import '../../core/constants/settings_layout_constants.dart';

/// 一项设置：标题在上，控件在下，控件占满整行。
class SettingSection extends StatelessWidget {
  const SettingSection({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;

  /// 标题行右侧的补充信息，如当前数值。
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: titleStyle),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: SettingsLayoutConstants.titleToControlSpacing),
        child,
      ],
    );
  }
}

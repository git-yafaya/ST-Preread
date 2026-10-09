import 'package:flutter/material.dart';

import '../../../core/constants/reader_layout_constants.dart';

/// 正文中的分隔线块。
class DividerBlockView extends StatelessWidget {
  const DividerBlockView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: ReaderLayoutConstants.dividerVerticalPadding,
      ),
      child: Divider(height: ReaderLayoutConstants.dividerHeight),
    );
  }
}

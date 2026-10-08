import 'package:flutter/material.dart';

import '../../core/constants/placeholder_strings.dart';
import '../../domain/domain.dart';

/// 正文中的插图块。占位实现，待插图功能替换。
class IllustrationBlockView extends StatelessWidget {
  const IllustrationBlockView({required this.block, super.key});

  final IllustrationBlock block;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(PlaceholderStrings.illustrationBlockView));
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/placeholder_strings.dart';

/// 精简播放条。占位实现，待播放条功能替换。
class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(PlaceholderStrings.playerBar));
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/placeholder_strings.dart';

/// 底部播放条。占位实现，待播放条功能替换。
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    required this.isPlayable,
    required this.onPlayRequested,
    super.key,
  });

  /// 本章是否有可播放的句子；为 false 时整条显示禁用态。
  final bool isPlayable;

  /// idle 状态下按播放键时回调。播放条不知道读者读到哪里，
  /// 所以起播位置交给阅读页决定。
  final VoidCallback onPlayRequested;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(PlaceholderStrings.playerBar));
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/placeholder_strings.dart';
import '../../../domain/domain.dart';

/// 滚动模式的章节视图。占位实现，待滚动模式功能替换。
class ScrollChapterView extends StatelessWidget {
  const ScrollChapterView({
    required this.chapter,
    required this.displayMode,
    required this.initialBlockIndex,
    required this.activeSentence,
    required this.onBlockVisible,
    required this.onSentenceTap,
    super.key,
  });

  final Chapter chapter;
  final BilingualDisplayMode displayMode;

  /// 进入时定位到的块（进度恢复 / 目录跳转）。
  final int initialBlockIndex;

  /// 正在朗读的句子；视图负责高亮它，并在它变化时把它带入可视区。
  final SentenceRef? activeSentence;

  /// 当前阅读到的块变化时回调，阅读页据此保存进度。
  final ValueChanged<int> onBlockVisible;

  /// 点到某一句时回调，阅读页据此从该句开始播放。
  final ValueChanged<SentenceRef> onSentenceTap;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(PlaceholderStrings.scrollChapterView));
  }
}

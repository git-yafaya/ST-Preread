import 'package:flutter/material.dart';

import '../../../core/constants/placeholder_strings.dart';
import '../../../domain/domain.dart';

/// 翻页模式的章节视图。占位实现，待翻页模式功能替换。
class PagedChapterView extends StatelessWidget {
  const PagedChapterView({
    required this.chapter,
    required this.displayMode,
    required this.initialAnchor,
    required this.activeSentence,
    required this.onAnchorChanged,
    required this.onSentenceTap,
    required this.onPreviousChapterRequested,
    required this.onNextChapterRequested,
    super.key,
  });

  final Chapter chapter;
  final BilingualDisplayMode displayMode;

  /// 进入时定位到的锚点（进度恢复；目录跳转时为该章开头）。
  final ReadingAnchor initialAnchor;

  /// 正在播放或暂停中的句子，用于高亮；没有则为 null。
  final SentenceRef? activeSentence;

  /// 当前阅读锚点变化时回调，阅读页据此保存进度。
  final ValueChanged<ReadingAnchor> onAnchorChanged;

  /// 点到一句带语音的句子时回调；点到无语音的句子或句间空隙不回调。
  final ValueChanged<SentenceRef> onSentenceTap;

  /// 用户在第一页继续向前翻时回调；为 null 表示没有上一章。
  final VoidCallback? onPreviousChapterRequested;

  /// 用户在最后一页继续向后翻时回调；为 null 表示没有下一章。
  final VoidCallback? onNextChapterRequested;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(PlaceholderStrings.pagedChapterView));
  }
}

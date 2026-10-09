import 'package:flutter/material.dart';

import '../../../core/constants/reader_layout_constants.dart';
import '../../../core/constants/reader_strings.dart';

/// 章首的「上一章」入口。
class PreviousChapterEntry extends StatelessWidget {
  const PreviousChapterEntry({required this.onRequested, super.key});

  final VoidCallback onRequested;

  @override
  Widget build(BuildContext context) {
    return _ChapterBoundaryArea(
      child: TextButton.icon(
        onPressed: onRequested,
        icon: const Icon(Icons.keyboard_arrow_up),
        label: const Text(ReaderStrings.previousChapter),
      ),
    );
  }
}

/// 章末的「下一章」入口；没有下一章时改为一行不可点的提示文字。
class NextChapterEntry extends StatelessWidget {
  const NextChapterEntry({required this.onRequested, super.key});

  /// 为 null 表示已是最后一章。
  final VoidCallback? onRequested;

  @override
  Widget build(BuildContext context) {
    final onRequested = this.onRequested;
    if (onRequested == null) {
      return _ChapterBoundaryArea(child: _buildLastChapterNotice(context));
    }
    return _ChapterBoundaryArea(
      child: FilledButton.tonalIcon(
        onPressed: onRequested,
        icon: const Icon(Icons.keyboard_arrow_down),
        label: const Text(ReaderStrings.nextChapter),
      ),
    );
  }

  Widget _buildLastChapterNotice(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      ReaderStrings.lastChapterReached,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ChapterBoundaryArea extends StatelessWidget {
  const _ChapterBoundaryArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ReaderLayoutConstants.chapterBoundaryEntryVerticalPadding,
      ),
      child: Center(child: child),
    );
  }
}

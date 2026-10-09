import 'package:flutter/material.dart';

import '../../../core/constants/reader_layout_constants.dart';
import '../../../core/constants/reader_strings.dart';
import '../../../domain/domain.dart';

/// 章节目录抽屉：列出全书章节，标出当前章，点选后跳转。
class ChapterListDrawer extends StatelessWidget {
  const ChapterListDrawer({
    required this.chapters,
    required this.currentChapterIndex,
    required this.onChapterSelected,
    super.key,
  });

  final List<ChapterSummary> chapters;

  /// 当前章的章节下标（ChapterSummary.index）。
  final int currentChapterIndex;

  /// 点选某一章时回调，参数为它的章节下标。
  final ValueChanged<int> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(
                ReaderLayoutConstants.drawerHeaderPadding,
              ),
              child: Text(
                ReaderStrings.tableOfContents,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: ReaderLayoutConstants.dividerHeight),
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, position) =>
                    _buildChapterTile(context, chapters[position]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterTile(BuildContext context, ChapterSummary summary) {
    final isCurrent = summary.index == currentChapterIndex;
    return ListTile(
      title: Text(summary.title),
      selected: isCurrent,
      trailing: isCurrent ? const Icon(Icons.menu_book_outlined) : null,
      onTap: () {
        // 先收起抽屉再跳转，正文才不会被抽屉挡着换章。
        Navigator.of(context).pop();
        onChapterSelected(summary.index);
      },
    );
  }
}

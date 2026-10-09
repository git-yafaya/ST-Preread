import 'package:flutter/material.dart';

import '../../../core/constants/bookshelf_layout_constants.dart';
import '../../../core/constants/bookshelf_strings.dart';
import '../../../domain/domain.dart';
import 'book_cover.dart';

/// 书架上的一张书籍卡片：封面在上，书名、作者、章节数在下。
///
/// 只负责展示与把手势转成回调，不接触任何状态，便于单独测试。
class BookCard extends StatelessWidget {
  const BookCard({
    required this.book,
    required this.onOpen,
    required this.onDeleteRequested,
    this.isBeingDeleted = false,
    super.key,
  });

  final Book book;
  final VoidCallback onOpen;

  /// 用户通过长按或菜单表示想删除这本书；是否真的删除由调用方确认。
  final VoidCallback onDeleteRequested;

  /// 正在删除的书不再响应任何操作，避免打开一本马上就不存在的书。
  final bool isBeingDeleted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isBeingDeleted
          ? BookshelfLayoutConstants.deletingCardOpacity
          : BookshelfLayoutConstants.normalCardOpacity,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isBeingDeleted ? null : onOpen,
          onLongPress: isBeingDeleted ? null : onDeleteRequested,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: BookCover(coverImagePath: book.coverImagePath)),
              _BookCardInfo(
                book: book,
                onDeleteRequested: isBeingDeleted ? null : onDeleteRequested,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCardInfo extends StatelessWidget {
  const _BookCardInfo({required this.book, required this.onDeleteRequested});

  final Book book;
  final VoidCallback? onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: BookshelfLayoutConstants.cardInfoPaddingStart,
        top: BookshelfLayoutConstants.cardInfoPaddingVertical,
        bottom: BookshelfLayoutConstants.cardInfoPaddingVertical,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _BookCardTexts(book: book)),
          _BookCardMenuButton(onDeleteSelected: onDeleteRequested),
        ],
      ),
    );
  }
}

class _BookCardTexts extends StatelessWidget {
  const _BookCardTexts({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final author = book.author;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: BookshelfLayoutConstants.cardInfoLineSpacing,
      children: [
        Text(
          book.title,
          maxLines: BookshelfLayoutConstants.bookTitleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        if (author != null)
          Text(
            author,
            maxLines: BookshelfLayoutConstants.bookAuthorMaxLines,
            overflow: TextOverflow.ellipsis,
            style: secondaryStyle,
          ),
        Text(
          BookshelfStrings.chapterCount(book.chapterCount),
          style: secondaryStyle,
        ),
      ],
    );
  }
}

/// 卡片上的菜单。长按不易被发现，菜单给出一个看得见的删除入口。
class _BookCardMenuButton extends StatelessWidget {
  const _BookCardMenuButton({required this.onDeleteSelected});

  /// 为 null 时菜单不可用。
  final VoidCallback? onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: BookshelfStrings.bookMenuTooltip,
      enabled: onDeleteSelected != null,
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: onDeleteSelected,
          child: const Text(BookshelfStrings.deleteAction),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/bookshelf_layout_constants.dart';
import '../../../domain/domain.dart';
import 'bookshelf_book_tile.dart';

/// 以网格展示书架上的书。
class BookGrid extends StatelessWidget {
  const BookGrid({required this.books, super.key});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        BookshelfLayoutConstants.gridPadding,
        BookshelfLayoutConstants.gridPadding,
        BookshelfLayoutConstants.gridPadding,
        BookshelfLayoutConstants.gridBottomPadding,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: BookshelfLayoutConstants.gridMaxCardWidth,
        childAspectRatio: BookshelfLayoutConstants.cardAspectRatio,
        mainAxisSpacing: BookshelfLayoutConstants.gridSpacing,
        crossAxisSpacing: BookshelfLayoutConstants.gridSpacing,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        // 以书的 id 作 key：书被删除后其余卡片的状态不会错位到别的书上。
        return BookshelfBookTile(key: ValueKey(book.id), book: book);
      },
    );
  }
}

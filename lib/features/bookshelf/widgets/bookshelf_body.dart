import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bookshelf_strings.dart';
import '../bookshelf_providers.dart';
import 'book_grid.dart';
import 'bookshelf_empty_view.dart';
import 'bookshelf_error_view.dart';

/// 书架页的主体：按书籍列表的读取状态显示加载中、出错、空书架或书籍网格。
class BookshelfBody extends ConsumerWidget {
  const BookshelfBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(bookshelfBooksProvider)) {
      AsyncData(value: final books) when books.isEmpty =>
        const BookshelfEmptyView(),
      AsyncData(value: final books) => BookGrid(books: books),
      AsyncError() => BookshelfErrorView(
        onRetry: () => ref.invalidate(bookshelfBooksProvider),
      ),
      AsyncLoading() => const Center(
        child: CircularProgressIndicator(
          semanticsLabel: BookshelfStrings.loadingBooks,
        ),
      ),
    };
  }
}

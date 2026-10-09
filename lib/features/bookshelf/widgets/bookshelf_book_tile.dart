import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../domain/domain.dart';
import '../book_deletion_controller.dart';
import 'book_card.dart';
import 'delete_book_dialog.dart';

/// 把一张书籍卡片接到书架的状态与动作上：点开进入阅读页，删除前先确认。
class BookshelfBookTile extends ConsumerWidget {
  const BookshelfBookTile({required this.book, super.key});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBeingDeleted = ref.watch(
      bookDeletionControllerProvider.select(
        (deletionState) => deletionState.isDeleting(book.id),
      ),
    );
    return BookCard(
      book: book,
      isBeingDeleted: isBeingDeleted,
      // 用 push 而不是 go：阅读页叠在书架之上，返回键才能回到书架。
      onOpen: () => context.push(AppRoutes.readerLocation(book.id)),
      onDeleteRequested: () => _confirmAndDelete(context, ref),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    // 先取出控制器：确认框关闭时这张卡片可能已不在界面上，那时不能再用 ref。
    final deletionController = ref.read(
      bookDeletionControllerProvider.notifier,
    );
    final isConfirmed = await showDeleteBookConfirmation(context, book);
    if (isConfirmed) {
      await deletionController.deleteBook(book);
    }
  }
}

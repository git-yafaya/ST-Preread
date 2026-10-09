import 'package:flutter/material.dart';

import '../../../core/constants/bookshelf_strings.dart';
import '../../../domain/domain.dart';

/// 弹出删除确认框；只有用户明确点了「删除」才返回 true。
///
/// 点对话框外部或按返回键关闭都算取消：删除不可撤销，不能靠误触完成。
Future<bool> showDeleteBookConfirmation(BuildContext context, Book book) async {
  final isConfirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => DeleteBookDialog(book: book),
  );
  return isConfirmed ?? false;
}

/// 删除书籍前的二次确认框。
class DeleteBookDialog extends StatelessWidget {
  const DeleteBookDialog({required this.book, super.key});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(BookshelfStrings.deleteConfirmationTitle),
      content: Text(BookshelfStrings.deleteConfirmationMessage(book.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(BookshelfStrings.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(BookshelfStrings.deleteAction),
        ),
      ],
    );
  }
}

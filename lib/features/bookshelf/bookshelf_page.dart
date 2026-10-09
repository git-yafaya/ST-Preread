import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/bookshelf_strings.dart';
import 'book_deletion_controller.dart';
import 'book_import_controller.dart';
import 'bookshelf_notices.dart';
import 'widgets/bookshelf_body.dart';
import 'widgets/import_book_button.dart';

/// 书架页：展示已导入的书籍，并提供导入与删除的入口。
class BookshelfPage extends ConsumerWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(bookImportControllerProvider, (previousState, importState) {
      _showNotice(context, describeBookImportState(importState));
    });
    ref.listen(
      bookDeletionControllerProvider.select(
        (deletionState) => deletionState.latestOutcome,
      ),
      (previousOutcome, outcome) {
        if (outcome != null) {
          _showNotice(context, describeBookDeletionOutcome(outcome));
        }
      },
    );
    return Scaffold(
      appBar: AppBar(title: const Text(BookshelfStrings.pageTitle)),
      body: const BookshelfBody(),
      floatingActionButton: const ImportBookButton(),
    );
  }

  void _showNotice(BuildContext context, String? message) {
    if (message == null) {
      return;
    }
    // 先收起上一条：连续操作时只保留最新结果，不让旧提示排队逐条播放。
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

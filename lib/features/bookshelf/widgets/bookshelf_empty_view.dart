import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bookshelf_strings.dart';
import '../book_import_controller.dart';
import 'bookshelf_status_view.dart';

/// 空书架：说明现状，并给出一个直接导入的按钮引导用户添加第一本书。
class BookshelfEmptyView extends ConsumerWidget {
  const BookshelfEmptyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isImporting = ref.watch(
      bookImportControllerProvider.select(
        (importState) => importState.isInProgress,
      ),
    );
    return BookshelfStatusView(
      icon: Icons.auto_stories_outlined,
      title: BookshelfStrings.emptyTitle,
      message: BookshelfStrings.emptyMessage,
      action: FilledButton.tonal(
        onPressed: isImporting
            ? null
            : ref.read(bookImportControllerProvider.notifier).importBook,
        child: const Text(BookshelfStrings.emptyImportAction),
      ),
    );
  }
}

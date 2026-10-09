import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bookshelf_layout_constants.dart';
import '../../../core/constants/bookshelf_strings.dart';
import '../book_import_controller.dart';

/// 书架页的导入入口。导入进行中时显示进度并停止响应点击。
class ImportBookButton extends ConsumerWidget {
  const ImportBookButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isImporting = ref.watch(
      bookImportControllerProvider.select(
        (importState) => importState.isInProgress,
      ),
    );
    return FloatingActionButton.extended(
      onPressed: isImporting
          ? null
          : ref.read(bookImportControllerProvider.notifier).importBook,
      icon: isImporting
          ? const _ImportProgressIndicator()
          : const Icon(Icons.add),
      label: Text(
        isImporting
            ? BookshelfStrings.importInProgress
            : BookshelfStrings.importAction,
      ),
    );
  }
}

class _ImportProgressIndicator extends StatelessWidget {
  const _ImportProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: BookshelfLayoutConstants.importProgressIndicatorSize,
      child: CircularProgressIndicator(
        strokeWidth:
            BookshelfLayoutConstants.importProgressIndicatorStrokeWidth,
      ),
    );
  }
}

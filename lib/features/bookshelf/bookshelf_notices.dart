import '../../core/constants/bookshelf_strings.dart';
import 'book_deletion_controller.dart';
import 'book_import_controller.dart';

/// 导入状态对应的提示文案；不需要提示的状态返回 null。
String? describeBookImportState(BookImportState state) {
  return switch (state) {
    BookImportIdle() || BookImportInProgress() => null,
    BookImportSucceeded(:final book) => BookshelfStrings.importSucceeded(
      book.title,
    ),
    BookImportFailed() => BookshelfStrings.importFailed,
  };
}

/// 删除结果对应的提示文案。
String describeBookDeletionOutcome(BookDeletionOutcome outcome) {
  return switch (outcome) {
    BookDeletionSucceeded(:final book) => BookshelfStrings.deleteSucceeded(
      book.title,
    ),
    BookDeletionFailed(:final book) => BookshelfStrings.deleteFailed(
      book.title,
    ),
  };
}

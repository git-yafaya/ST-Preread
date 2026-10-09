import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/bookshelf_import_constants.dart';
import '../../core/providers/providers.dart';
import '../../domain/domain.dart';

/// 导入动作的状态。
///
/// 结果也作为状态保留，页面监听状态变化来弹出提示，
/// 不必在异步间隙之后再去使用可能已经失效的界面上下文。
sealed class BookImportState {
  const BookImportState();

  bool get isInProgress => this is BookImportInProgress;
}

/// 还没有导入过，或上一次导入的结果已无需关注。
final class BookImportIdle extends BookImportState {
  const BookImportIdle();
}

final class BookImportInProgress extends BookImportState {
  const BookImportInProgress();
}

final class BookImportSucceeded extends BookImportState {
  const BookImportSucceeded(this.book);

  final Book book;
}

final class BookImportFailed extends BookImportState {
  const BookImportFailed(this.error);

  /// 书库报告的原始错误，仅用于排查，不直接展示给用户。
  final Object error;
}

/// 负责执行导入，并保证同一时间只有一次导入在进行。
class BookImportController extends Notifier<BookImportState> {
  @override
  BookImportState build() => const BookImportIdle();

  /// 已有导入在进行时直接忽略，防止连续点击导入出多本书。
  Future<void> importBook() async {
    if (state.isInProgress) {
      return;
    }
    state = const BookImportInProgress();
    final outcome = await _runImport();
    // 导入完成前页面连同容器可能已被销毁，此时不能再写状态。
    if (ref.mounted) {
      state = outcome;
    }
  }

  Future<BookImportState> _runImport() async {
    try {
      final book = await ref
          .read(bookRepositoryProvider)
          .importBook(BookshelfImportConstants.placeholderSourcePath);
      return BookImportSucceeded(book);
    } on Exception catch (error) {
      return BookImportFailed(error);
    }
  }
}

final bookImportControllerProvider =
    NotifierProvider<BookImportController, BookImportState>(
      BookImportController.new,
    );

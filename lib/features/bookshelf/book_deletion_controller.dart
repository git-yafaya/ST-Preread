import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../domain/domain.dart';

/// 一次删除的结果。
sealed class BookDeletionOutcome {
  const BookDeletionOutcome(this.book);

  final Book book;
}

final class BookDeletionSucceeded extends BookDeletionOutcome {
  const BookDeletionSucceeded(super.book);
}

final class BookDeletionFailed extends BookDeletionOutcome {
  const BookDeletionFailed(super.book, this.error);

  /// 书库报告的原始错误，仅用于排查，不直接展示给用户。
  final Object error;
}

/// 删除动作的状态。
class BookDeletionState {
  const BookDeletionState({
    required this.deletingBookIds,
    required this.latestOutcome,
  });

  const BookDeletionState.initial()
    : deletingBookIds = const {},
      latestOutcome = null;

  /// 正在删除的书。不同的书可以同时删除，所以是集合而不是单个 id。
  final Set<String> deletingBookIds;

  /// 最近一次完成的删除；还没有删除过时为 null。
  final BookDeletionOutcome? latestOutcome;

  bool isDeleting(String bookId) => deletingBookIds.contains(bookId);
}

/// 负责执行删除，并保证同一本书不会被重复删除。
///
/// 二次确认属于界面交互，由调用方在调用 [deleteBook] 之前完成。
class BookDeletionController extends Notifier<BookDeletionState> {
  @override
  BookDeletionState build() => const BookDeletionState.initial();

  /// 这本书已经在删除时直接忽略：重复删除只会得到「找不到书」的错误提示。
  Future<void> deleteBook(Book book) async {
    if (state.isDeleting(book.id)) {
      return;
    }
    _markDeleting(book.id);
    final outcome = await _runDeletion(book);
    // 删除完成前页面连同容器可能已被销毁，此时不能再写状态。
    if (ref.mounted) {
      _finishDeleting(outcome);
    }
  }

  Future<BookDeletionOutcome> _runDeletion(Book book) async {
    try {
      await ref.read(bookRepositoryProvider).deleteBook(book.id);
      return BookDeletionSucceeded(book);
    } on Exception catch (error) {
      return BookDeletionFailed(book, error);
    }
  }

  void _markDeleting(String bookId) {
    state = BookDeletionState(
      deletingBookIds: Set.unmodifiable({...state.deletingBookIds, bookId}),
      latestOutcome: state.latestOutcome,
    );
  }

  void _finishDeleting(BookDeletionOutcome outcome) {
    state = BookDeletionState(
      deletingBookIds: Set.unmodifiable(
        state.deletingBookIds.difference({outcome.book.id}),
      ),
      latestOutcome: outcome,
    );
  }
}

final bookDeletionControllerProvider =
    NotifierProvider<BookDeletionController, BookDeletionState>(
      BookDeletionController.new,
    );

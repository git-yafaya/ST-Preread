import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/bookshelf/book_deletion_controller.dart';

import 'support/book_fixtures.dart';
import 'support/fake_book_repository.dart';

void main() {
  final firstBook = buildBook(id: 'first', title: '第一本');
  final secondBook = buildBook(id: 'second', title: '第二本');
  late FakeBookRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeBookRepository(
      initialBooks: [firstBook, secondBook],
      bookToImport: buildBook(id: 'imported'),
    );
    addTearDown(repository.dispose);
    container = ProviderContainer(
      overrides: [bookRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  BookDeletionState readState() {
    return container.read(bookDeletionControllerProvider);
  }

  BookDeletionController readController() {
    return container.read(bookDeletionControllerProvider.notifier);
  }

  group('BookDeletionController', () {
    test('一开始没有正在删除的书，也没有结果', () {
      expect(readState().deletingBookIds, isEmpty);
      expect(readState().latestOutcome, isNull);
    });

    test('删除时把这本书的 id 交给书库', () async {
      await readController().deleteBook(firstBook);

      expect(repository.deletedBookIds, [firstBook.id]);
    });

    test('删除成功后结果带着被删的书，且不再标记为删除中', () async {
      await readController().deleteBook(firstBook);

      expect(
        readState().latestOutcome,
        isA<BookDeletionSucceeded>().having(
          (outcome) => outcome.book,
          'book',
          firstBook,
        ),
      );
      expect(readState().isDeleting(firstBook.id), isFalse);
    });

    test('删除失败后结果带着这本书与书库报告的错误，且不再标记为删除中', () async {
      const failure = BookNotFoundException('first');
      repository.deleteFailure = failure;

      await readController().deleteBook(firstBook);

      expect(
        readState().latestOutcome,
        isA<BookDeletionFailed>()
            .having((outcome) => outcome.book, 'book', firstBook)
            .having((outcome) => outcome.error, 'error', same(failure)),
      );
      expect(readState().isDeleting(firstBook.id), isFalse);
    });

    test('删除进行中只标记这一本书，重复删除同一本会被忽略', () async {
      final deleteGate = Completer<void>();
      repository.deleteGate = deleteGate;

      final firstDeletion = readController().deleteBook(firstBook);
      expect(readState().isDeleting(firstBook.id), isTrue);
      expect(readState().isDeleting(secondBook.id), isFalse);

      await readController().deleteBook(firstBook);
      expect(repository.deletedBookIds, [firstBook.id]);

      deleteGate.complete();
      await firstDeletion;
      expect(readState().deletingBookIds, isEmpty);
    });

    test('一本书还在删除时可以同时删除另一本', () async {
      final deleteGate = Completer<void>();
      repository.deleteGate = deleteGate;

      final firstDeletion = readController().deleteBook(firstBook);
      final secondDeletion = readController().deleteBook(secondBook);
      expect(readState().deletingBookIds, {firstBook.id, secondBook.id});

      deleteGate.complete();
      await Future.wait([firstDeletion, secondDeletion]);

      expect(repository.deletedBookIds, [firstBook.id, secondBook.id]);
      expect(readState().deletingBookIds, isEmpty);
    });

    test('正在删除的书的集合不可被外部修改', () {
      expect(
        () => readState().deletingBookIds.add(firstBook.id),
        throwsUnsupportedError,
      );
    });

    test('容器在删除完成前被销毁时不再写状态，也不抛错', () async {
      final deleteGate = Completer<void>();
      repository.deleteGate = deleteGate;
      final pendingDeletion = readController().deleteBook(firstBook);

      container.dispose();
      deleteGate.complete();

      await expectLater(pendingDeletion, completes);
    });
  });
}

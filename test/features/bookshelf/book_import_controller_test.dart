import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/bookshelf_import_constants.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/features/bookshelf/book_import_controller.dart';

import 'support/book_fixtures.dart';
import 'support/fake_book_repository.dart';

void main() {
  final importedBook = buildBook(id: 'imported', title: '新导入的书');
  late FakeBookRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeBookRepository(
      initialBooks: [],
      bookToImport: importedBook,
    );
    addTearDown(repository.dispose);
    container = ProviderContainer(
      overrides: [bookRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  BookImportState readState() => container.read(bookImportControllerProvider);

  BookImportController readController() {
    return container.read(bookImportControllerProvider.notifier);
  }

  group('BookImportController', () {
    test('一开始处于空闲', () {
      expect(readState(), isA<BookImportIdle>());
      expect(readState().isInProgress, isFalse);
    });

    test('导入时把占位来源路径交给书库', () async {
      await readController().importBook();

      expect(repository.importedSourcePaths, [
        BookshelfImportConstants.placeholderSourcePath,
      ]);
    });

    test('导入成功后状态带着导入的那本书', () async {
      await readController().importBook();

      expect(
        readState(),
        isA<BookImportSucceeded>().having(
          (state) => state.book,
          'book',
          importedBook,
        ),
      );
    });

    test('导入失败后状态带着书库报告的错误', () async {
      final failure = Exception('导出物无法识别');
      repository.importFailure = failure;

      await readController().importBook();

      expect(
        readState(),
        isA<BookImportFailed>().having(
          (state) => state.error,
          'error',
          same(failure),
        ),
      );
    });

    test('导入进行中状态为进行中，此时再次导入会被忽略', () async {
      final importGate = Completer<void>();
      repository.importGate = importGate;

      final firstImport = readController().importBook();
      expect(readState().isInProgress, isTrue);

      await readController().importBook();
      expect(repository.importedSourcePaths, hasLength(1));

      importGate.complete();
      await firstImport;
      expect(readState(), isA<BookImportSucceeded>());
    });

    test('上一次导入结束后可以再次导入', () async {
      repository.importFailure = Exception('导出物无法识别');
      await readController().importBook();
      repository.importFailure = null;

      await readController().importBook();

      expect(repository.importedSourcePaths, hasLength(2));
      expect(readState(), isA<BookImportSucceeded>());
    });

    test('容器在导入完成前被销毁时不再写状态，也不抛错', () async {
      final importGate = Completer<void>();
      repository.importGate = importGate;
      final pendingImport = readController().importBook();

      container.dispose();
      importGate.complete();

      await expectLater(pendingImport, completes);
    });
  });
}

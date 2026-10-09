import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/bookshelf_strings.dart';
import 'package:st_preread/features/bookshelf/book_deletion_controller.dart';
import 'package:st_preread/features/bookshelf/book_import_controller.dart';
import 'package:st_preread/features/bookshelf/bookshelf_notices.dart';

import 'support/book_fixtures.dart';

void main() {
  final book = buildBook(title: '雨夜来客');

  group('describeBookImportState', () {
    test('空闲与进行中不需要提示', () {
      expect(describeBookImportState(const BookImportIdle()), isNull);
      expect(describeBookImportState(const BookImportInProgress()), isNull);
    });

    test('成功时提示里带书名', () {
      final notice = describeBookImportState(BookImportSucceeded(book));

      expect(notice, BookshelfStrings.importSucceeded('雨夜来客'));
      expect(notice, contains('雨夜来客'));
    });

    test('失败时给出导入失败的提示，不暴露原始错误', () {
      final notice = describeBookImportState(
        BookImportFailed(Exception('内部细节')),
      );

      expect(notice, BookshelfStrings.importFailed);
      expect(notice, isNot(contains('内部细节')));
    });
  });

  group('describeBookDeletionOutcome', () {
    test('成功时提示里带书名', () {
      final notice = describeBookDeletionOutcome(BookDeletionSucceeded(book));

      expect(notice, BookshelfStrings.deleteSucceeded('雨夜来客'));
      expect(notice, contains('雨夜来客'));
    });

    test('失败时提示里带书名，与成功的提示不同，不暴露原始错误', () {
      final notice = describeBookDeletionOutcome(
        BookDeletionFailed(book, Exception('内部细节')),
      );

      expect(notice, BookshelfStrings.deleteFailed('雨夜来客'));
      expect(notice, contains('雨夜来客'));
      expect(notice, isNot(BookshelfStrings.deleteSucceeded('雨夜来客')));
      expect(notice, isNot(contains('内部细节')));
    });
  });

  group('BookshelfStrings 带参数的文案', () {
    test('章节数文案里带具体数字', () {
      expect(BookshelfStrings.chapterCount(12), contains('12'));
      expect(
        BookshelfStrings.chapterCount(1),
        isNot(BookshelfStrings.chapterCount(2)),
      );
    });

    test('删除确认文案里带书名', () {
      expect(
        BookshelfStrings.deleteConfirmationMessage('雨夜来客'),
        contains('雨夜来客'),
      );
    });
  });
}

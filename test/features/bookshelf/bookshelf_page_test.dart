import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/bookshelf_import_constants.dart';
import 'package:st_preread/core/constants/bookshelf_strings.dart';
import 'package:st_preread/data/mock/mock_book_repository.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/bookshelf/widgets/book_card.dart';
import 'package:st_preread/features/bookshelf/widgets/book_cover.dart';
import 'package:st_preread/features/bookshelf/widgets/bookshelf_empty_view.dart';
import 'package:st_preread/features/bookshelf/widgets/bookshelf_error_view.dart';
import 'package:st_preread/features/bookshelf/widgets/delete_book_dialog.dart';

import 'support/book_fixtures.dart';
import 'support/bookshelf_test_app.dart';
import 'support/fake_book_repository.dart';

void main() {
  final existingBook = buildBook(id: 'existing', title: '已有的书');
  final importedBook = buildBook(id: 'imported', title: '新导入的书');

  /// [initialBooks] 为 null 表示书架还没读出来。
  FakeBookRepository buildFakeRepository({List<Book>? initialBooks}) {
    final repository = FakeBookRepository(
      initialBooks: initialBooks,
      bookToImport: importedBook,
    );
    addTearDown(repository.dispose);
    return repository;
  }

  MockBookRepository buildMockRepository({required int initialBookCount}) {
    final repository = MockBookRepository(initialBookCount: initialBookCount);
    addTearDown(repository.dispose);
    return repository;
  }

  final importButton = find.byType(FloatingActionButton);
  final confirmDeleteButton = find.widgetWithText(
    FilledButton,
    BookshelfStrings.deleteAction,
  );

  Future<void> requestDeletionFromMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip(BookshelfStrings.bookMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(BookshelfStrings.deleteAction));
    await tester.pumpAndSettle();
  }

  group('读取状态', () {
    testWidgets('书架还没读出来时显示加载中', (tester) async {
      await pumpBookshelf(tester, buildFakeRepository());

      expect(
        find.bySemanticsLabel(BookshelfStrings.loadingBooks),
        findsOneWidget,
      );
      expect(find.byType(BookshelfEmptyView), findsNothing);
      expect(find.byType(BookCard), findsNothing);
    });

    testWidgets('书架读出来后加载中消失', (tester) async {
      final repository = buildFakeRepository();
      await pumpBookshelf(tester, repository);

      repository.publishBooks([existingBook]);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(BookshelfStrings.loadingBooks),
        findsNothing,
      );
      expect(find.text(existingBook.title), findsOneWidget);
    });

    testWidgets('读取失败时显示出错说明，重试成功后显示书架', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook])
        ..watchFailure = Exception('读不到书架');
      await pumpBookshelf(tester, repository);

      expect(find.text(BookshelfStrings.loadFailedTitle), findsOneWidget);
      expect(find.byType(BookCard), findsNothing);

      repository.watchFailure = null;
      await tester.tap(find.text(BookshelfStrings.retryAction));
      await tester.pumpAndSettle();

      expect(find.byType(BookshelfErrorView), findsNothing);
      expect(find.text(existingBook.title), findsOneWidget);
    });

    testWidgets('重试仍然失败时停在出错说明', (tester) async {
      final repository = buildFakeRepository()
        ..watchFailure = Exception('读不到书架');
      await pumpBookshelf(tester, repository);

      await tester.tap(find.text(BookshelfStrings.retryAction));
      await tester.pumpAndSettle();

      expect(find.text(BookshelfStrings.loadFailedTitle), findsOneWidget);
    });
  });

  group('空书架', () {
    testWidgets('说明书架为空并引导导入', (tester) async {
      await pumpBookshelf(tester, buildMockRepository(initialBookCount: 0));

      expect(find.text(BookshelfStrings.emptyTitle), findsOneWidget);
      expect(find.text(BookshelfStrings.emptyMessage), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, BookshelfStrings.emptyImportAction),
        findsOneWidget,
      );
      expect(find.byType(BookCard), findsNothing);
    });

    testWidgets('点空书架上的导入按钮后书架出现新书', (tester) async {
      await pumpBookshelf(tester, buildMockRepository(initialBookCount: 0));

      await tester.tap(find.text(BookshelfStrings.emptyImportAction));
      await tester.pumpAndSettle();

      expect(find.byType(BookshelfEmptyView), findsNothing);
      expect(find.byType(BookCard), findsOneWidget);
    });

    testWidgets('导入进行中时空书架上的导入按钮不可点', (tester) async {
      final repository = buildFakeRepository(initialBooks: [])
        ..importGate = Completer<void>();
      await pumpBookshelf(tester, repository);

      await tester.tap(find.text(BookshelfStrings.emptyImportAction));
      await tester.pump();

      final emptyStateButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, BookshelfStrings.emptyImportAction),
      );
      expect(emptyStateButton.onPressed, isNull);
    });
  });

  group('展示书籍', () {
    testWidgets('每本书显示书名、作者、章节数与占位封面', (tester) async {
      final book = buildBook(title: '雨夜来客', author: '某作者', chapterCount: 12);
      await pumpBookshelf(tester, buildFakeRepository(initialBooks: [book]));

      final card = find.byType(BookCard);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('雨夜来客')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('某作者')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text(BookshelfStrings.chapterCount(12)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.byType(BookCoverPlaceholder)),
        findsOneWidget,
      );
    });

    testWidgets('书架上的每一本书都有一张卡片', (tester) async {
      final books = [
        buildBook(id: 'first', title: '第一本'),
        buildBook(id: 'second', title: '第二本'),
        buildBook(id: 'third', title: '第三本'),
      ];
      await pumpBookshelf(tester, buildFakeRepository(initialBooks: books));

      expect(find.byType(BookCard), findsNWidgets(books.length));
      for (final book in books) {
        expect(find.text(book.title), findsOneWidget);
      }
    });

    testWidgets('显示内存假书库自带的示例书', (tester) async {
      final repository = buildMockRepository(initialBookCount: 1);
      // 测试体运行在假时钟里，直接 await 书库的流不会有结果，要放到真实的异步环境里取。
      final sampleBooks = await tester.runAsync(
        () => repository.watchBooks().first,
      );
      final sampleBook = sampleBooks!.single;

      await pumpBookshelf(tester, repository);

      expect(find.text(sampleBook.title), findsOneWidget);
      expect(
        find.text(BookshelfStrings.chapterCount(sampleBook.chapterCount)),
        findsOneWidget,
      );
    });
  });

  group('打开书籍', () {
    testWidgets('点一本书进入这本书的阅读路由', (tester) async {
      // id 里带路径分隔符与空格，路径拼错或漏转义时这里就会对不上。
      final book = buildBook(id: '我的书/第 1 版', title: '带特殊字符的书');
      await pumpBookshelf(tester, buildFakeRepository(initialBooks: [book]));

      await tester.tap(find.text(book.title));
      await tester.pumpAndSettle();

      expect(
        tester.widget<OpenedBookProbe>(find.byType(OpenedBookProbe)).bookId,
        book.id,
      );
    });

    testWidgets('从阅读路由返回后回到书架', (tester) async {
      await pumpBookshelf(
        tester,
        buildFakeRepository(initialBooks: [existingBook]),
      );
      await tester.tap(find.text(existingBook.title));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(OpenedBookProbe), findsNothing);
      expect(find.text(existingBook.title), findsOneWidget);
    });
  });

  group('导入', () {
    testWidgets('导入成功后书架出现新书并提示', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook]);
      await pumpBookshelf(tester, repository);

      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsNWidgets(2));
      expect(find.text(importedBook.title), findsOneWidget);
      expect(
        find.text(BookshelfStrings.importSucceeded(importedBook.title)),
        findsOneWidget,
      );
      expect(repository.importedSourcePaths, [
        BookshelfImportConstants.placeholderSourcePath,
      ]);
    });

    testWidgets('内存假书库下导入后多出一本书', (tester) async {
      await pumpBookshelf(tester, buildMockRepository(initialBookCount: 1));

      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsNWidgets(2));
    });

    testWidgets('导入进行中显示进度，再点也不会重复导入', (tester) async {
      final importGate = Completer<void>();
      final repository = buildFakeRepository(initialBooks: [existingBook])
        ..importGate = importGate;
      await pumpBookshelf(tester, repository);

      await tester.tap(importButton);
      await tester.pump();

      expect(find.text(BookshelfStrings.importInProgress), findsOneWidget);
      expect(
        find.descendant(
          of: importButton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      await tester.tap(importButton);
      await tester.pump();

      expect(repository.importedSourcePaths, hasLength(1));

      importGate.complete();
      await tester.pumpAndSettle();

      expect(find.text(BookshelfStrings.importInProgress), findsNothing);
      expect(find.text(BookshelfStrings.importAction), findsOneWidget);
      expect(find.text(importedBook.title), findsOneWidget);
    });

    testWidgets('导入失败时提示，书架不变，之后可以再次导入', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook])
        ..importFailure = Exception('导出物无法识别');
      await pumpBookshelf(tester, repository);

      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(find.text(BookshelfStrings.importFailed), findsOneWidget);
      expect(find.byType(BookCard), findsOneWidget);

      repository.importFailure = null;
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(find.text(BookshelfStrings.importFailed), findsNothing);
      expect(find.text(importedBook.title), findsOneWidget);
    });
  });

  group('删除', () {
    testWidgets('从卡片菜单选择删除后先弹出确认框，此时还没有删除', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook]);
      await pumpBookshelf(tester, repository);

      await requestDeletionFromMenu(tester);

      expect(find.byType(DeleteBookDialog), findsOneWidget);
      expect(
        find.text(
          BookshelfStrings.deleteConfirmationMessage(existingBook.title),
        ),
        findsOneWidget,
      );
      expect(repository.deletedBookIds, isEmpty);
    });

    testWidgets('长按卡片同样弹出确认框', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook]);
      await pumpBookshelf(tester, repository);

      await tester.longPress(find.text(existingBook.title));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteBookDialog), findsOneWidget);
      expect(repository.deletedBookIds, isEmpty);
    });

    testWidgets('确认后删除这本书，书从书架消失并提示', (tester) async {
      final keptBook = buildBook(id: 'kept', title: '留下的书');
      final repository = buildFakeRepository(
        initialBooks: [existingBook, keptBook],
      );
      await pumpBookshelf(tester, repository);

      await tester.longPress(find.text(existingBook.title));
      await tester.pumpAndSettle();
      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();

      expect(repository.deletedBookIds, [existingBook.id]);
      expect(find.byType(DeleteBookDialog), findsNothing);
      expect(find.text(existingBook.title), findsNothing);
      expect(find.text(keptBook.title), findsOneWidget);
      expect(
        find.text(BookshelfStrings.deleteSucceeded(existingBook.title)),
        findsOneWidget,
      );
    });

    testWidgets('取消后不删除', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook]);
      await pumpBookshelf(tester, repository);
      await requestDeletionFromMenu(tester);

      await tester.tap(find.text(BookshelfStrings.cancelAction));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteBookDialog), findsNothing);
      expect(repository.deletedBookIds, isEmpty);
      expect(find.text(existingBook.title), findsOneWidget);
    });

    testWidgets('点确认框外部关闭也不删除', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook]);
      await pumpBookshelf(tester, repository);
      await requestDeletionFromMenu(tester);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.byType(DeleteBookDialog), findsNothing);
      expect(repository.deletedBookIds, isEmpty);
      expect(find.text(existingBook.title), findsOneWidget);
    });

    testWidgets('删除失败时提示，书仍在书架上', (tester) async {
      final repository = buildFakeRepository(initialBooks: [existingBook])
        ..deleteFailure = const BookNotFoundException('existing');
      await pumpBookshelf(tester, repository);
      await requestDeletionFromMenu(tester);

      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();

      expect(
        find.text(BookshelfStrings.deleteFailed(existingBook.title)),
        findsOneWidget,
      );
      expect(find.byType(BookCard), findsOneWidget);
    });

    testWidgets('删除进行中这本书不能再打开', (tester) async {
      final deleteGate = Completer<void>();
      final repository = buildFakeRepository(initialBooks: [existingBook])
        ..deleteGate = deleteGate;
      await pumpBookshelf(tester, repository);
      await requestDeletionFromMenu(tester);
      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text(existingBook.title));
      await tester.pumpAndSettle();

      expect(find.byType(OpenedBookProbe), findsNothing);
      expect(
        tester.widget<BookCard>(find.byType(BookCard)).isBeingDeleted,
        isTrue,
      );

      deleteGate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsNothing);
    });

    testWidgets('删掉最后一本书后回到空书架', (tester) async {
      await pumpBookshelf(tester, buildMockRepository(initialBookCount: 1));
      await requestDeletionFromMenu(tester);

      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsNothing);
      expect(find.text(BookshelfStrings.emptyTitle), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/bookshelf_strings.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/bookshelf/widgets/book_card.dart';
import 'package:st_preread/features/bookshelf/widgets/book_cover.dart';

import '../support/book_fixtures.dart';

void main() {
  late int openCount;
  late int deleteRequestCount;

  setUp(() {
    openCount = 0;
    deleteRequestCount = 0;
  });

  Future<void> pumpCard(
    WidgetTester tester,
    Book book, {
    bool isBeingDeleted = false,
    double textScaleFactor = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        // 在这里放大字号，模拟用户在系统里调大了字体。
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScaleFactor,
          maxScaleFactor: textScaleFactor,
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            // 接近 360 宽的手机上两列网格里一张卡片的大小。
            child: SizedBox(
              width: 158,
              height: 287,
              child: BookCard(
                book: book,
                isBeingDeleted: isBeingDeleted,
                onOpen: () => openCount++,
                onDeleteRequested: () => deleteRequestCount++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('BookCard 展示', () {
    testWidgets('显示书名、作者、章节数与封面', (tester) async {
      await pumpCard(
        tester,
        buildBook(title: '雨夜来客', author: '某作者', chapterCount: 7),
      );

      expect(find.text('雨夜来客'), findsOneWidget);
      expect(find.text('某作者'), findsOneWidget);
      expect(find.text(BookshelfStrings.chapterCount(7)), findsOneWidget);
      expect(find.byType(BookCover), findsOneWidget);
    });

    testWidgets('没有作者时不显示作者一行，其余照常', (tester) async {
      await pumpCard(
        tester,
        buildBook(title: '无名之书', author: null, chapterCount: 2),
      );

      final shownTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();
      expect(shownTexts, ['无名之书', BookshelfStrings.chapterCount(2)]);
    });

    testWidgets('很长的书名与作者不会撑破卡片', (tester) async {
      await pumpCard(
        tester,
        buildBook(title: '很长的书名' * 20, author: '很长的作者名' * 20),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('字号放大一倍时很长的书名与作者也不会撑破卡片', (tester) async {
      await pumpCard(
        tester,
        buildBook(title: '很长的书名' * 20, author: '很长的作者名' * 20),
        textScaleFactor: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('BookCard 操作', () {
    testWidgets('点卡片触发打开', (tester) async {
      final book = buildBook();
      await pumpCard(tester, book);

      await tester.tap(find.text(book.title));

      expect(openCount, 1);
      expect(deleteRequestCount, 0);
    });

    testWidgets('长按卡片触发删除请求而不是打开', (tester) async {
      final book = buildBook();
      await pumpCard(tester, book);

      await tester.longPress(find.text(book.title));

      expect(deleteRequestCount, 1);
      expect(openCount, 0);
    });

    testWidgets('从菜单选择删除触发删除请求', (tester) async {
      await pumpCard(tester, buildBook());

      await tester.tap(find.byTooltip(BookshelfStrings.bookMenuTooltip));
      await tester.pumpAndSettle();
      expect(deleteRequestCount, 0);

      await tester.tap(find.text(BookshelfStrings.deleteAction));
      await tester.pumpAndSettle();

      expect(deleteRequestCount, 1);
      expect(openCount, 0);
    });

    testWidgets('正在删除时点按、长按、菜单都不响应', (tester) async {
      final book = buildBook();
      await pumpCard(tester, book, isBeingDeleted: true);

      await tester.tap(find.text(book.title));
      await tester.longPress(find.text(book.title));
      await tester.tap(find.byTooltip(BookshelfStrings.bookMenuTooltip));
      await tester.pumpAndSettle();

      expect(openCount, 0);
      expect(deleteRequestCount, 0);
      expect(find.text(BookshelfStrings.deleteAction), findsNothing);
    });
  });
}

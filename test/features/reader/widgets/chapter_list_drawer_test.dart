import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_strings.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/widgets/chapter_list_drawer.dart';

import '../support/reader_fixtures.dart';

void main() {
  // 章节下标故意不从 0 开始，确认回调与「当前章」用的是章节下标而不是列表位置。
  const chapters = [
    ChapterSummary(bookId: fixtureBookId, index: 5, title: '序章'),
    ChapterSummary(bookId: fixtureBookId, index: 6, title: '正文'),
    ChapterSummary(bookId: fixtureBookId, index: 7, title: '尾声'),
  ];

  late List<int> selectedChapterIndexes;

  setUp(() {
    selectedChapterIndexes = [];
  });

  Future<void> pumpOpenDrawer(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: ChapterListDrawer(
            chapters: chapters,
            currentChapterIndex: 6,
            onChapterSelected: selectedChapterIndexes.add,
          ),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('列出全部章节与「目录」标题', (tester) async {
    await pumpOpenDrawer(tester);

    expect(find.text(ReaderStrings.tableOfContents), findsOneWidget);
    for (final summary in chapters) {
      expect(find.text(summary.title), findsOneWidget);
    }
  });

  testWidgets('只有当前章被标为选中', (tester) async {
    await pumpOpenDrawer(tester);

    final selectedTitles = [
      for (final summary in chapters)
        if (tester
            .widget<ListTile>(find.widgetWithText(ListTile, summary.title))
            .selected)
          summary.title,
    ];

    expect(selectedTitles, ['正文']);
  });

  testWidgets('点选章节时回调它的章节下标，并收起抽屉', (tester) async {
    await pumpOpenDrawer(tester);

    await tester.tap(find.text('尾声'));
    await tester.pumpAndSettle();

    expect(selectedChapterIndexes, [7]);
    expect(find.byType(ChapterListDrawer), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/illustration/illustration_block_view.dart';
import 'package:st_preread/features/reader/content/content.dart';

import '../support/reader_fixtures.dart';

void main() {
  Future<void> pumpBlock(WidgetTester tester, ContentBlock block) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ContentBlockView(
              block: block,
              blockIndex: 0,
              displayMode: BilingualDisplayMode.both,
              textTheme: ReaderTextTheme.fromTheme(
                Theme.of(context),
                fontScale: 1,
              ),
              activeSentence: null,
              onSentenceTap: null,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('段落块渲染成段落', (tester) async {
    final paragraph = buildParagraph(translation: buildPlainSidedText('一段文字'));

    await pumpBlock(tester, paragraph);

    expect(
      tester
          .widget<ParagraphBlockView>(find.byType(ParagraphBlockView))
          .paragraph,
      paragraph,
    );
  });

  testWidgets('分隔线块渲染成一条分隔线', (tester) async {
    await pumpBlock(tester, const DividerBlock(id: 'divider'));

    expect(find.byType(DividerBlockView), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(ParagraphBlockView), findsNothing);
  });

  testWidgets('插图块交给插图组件渲染', (tester) async {
    const illustration = IllustrationBlock(
      id: 'illustration',
      imagePath: 'missing.png',
      caption: '说明',
    );

    await pumpBlock(tester, illustration);

    expect(
      tester
          .widget<IllustrationBlockView>(find.byType(IllustrationBlockView))
          .block,
      illustration,
    );
  });
}

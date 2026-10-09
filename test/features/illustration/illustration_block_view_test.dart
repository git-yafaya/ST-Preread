import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/illustration_layout_constants.dart';
import 'package:st_preread/core/constants/illustration_strings.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/illustration/illustration_block_view.dart';
import 'package:st_preread/features/illustration/illustration_figure.dart';
import 'package:st_preread/features/illustration/illustration_placeholder.dart';

import 'missing_file_overrides.dart';

void main() {
  const missingImagePath = '/books/sample/images/missing.png';
  const caption = '雨夜的车站';
  const longCaption =
      '这是一段很长很长的说明文字，用来确认说明再长也不会把插图块撑破父级给的高度。'
      '这是一段很长很长的说明文字，用来确认说明再长也不会把插图块撑破父级给的高度。'
      '这是一段很长很长的说明文字，用来确认说明再长也不会把插图块撑破父级给的高度。';
  const availableWidth = 300.0;

  const blockWithCaption = IllustrationBlock(
    id: 'illustration-with-caption',
    imagePath: missingImagePath,
    caption: caption,
  );
  const blockWithoutCaption = IllustrationBlock(
    id: 'illustration-without-caption',
    imagePath: missingImagePath,
    caption: null,
  );

  setUp(() {
    IOOverrides.global = MissingFileOverrides();
    addTearDown(() => IOOverrides.global = null);
  });

  /// 把插图块放进给定的父级里，并等图片加载失败的结果传回界面。
  Future<void> pumpInside(
    WidgetTester tester, {
    required Widget Function(Widget illustration) parentBuilder,
    required IllustrationBlock block,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: parentBuilder(IllustrationBlockView(block: block)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 模拟翻页模式：一页里留给插图的宽高都是定死的上限。
  Widget Function(Widget) boundedParent({required double maxHeight}) {
    return (illustration) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: availableWidth,
        maxHeight: maxHeight,
      ),
      child: illustration,
    );
  }

  /// 模拟滚动模式：宽度固定，高度不设上限。
  Widget scrollingParent(Widget illustration) {
    return SizedBox(
      width: availableWidth,
      child: SingleChildScrollView(child: illustration),
    );
  }

  Size blockSize(WidgetTester tester) {
    return tester.getSize(find.byType(IllustrationBlockView));
  }

  group('图片文件不存在', () {
    testWidgets('显示占位，不抛异常', (tester) async {
      await pumpInside(
        tester,
        parentBuilder: scrollingParent,
        block: blockWithoutCaption,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IllustrationPlaceholder), findsOneWidget);
      expect(find.text(IllustrationStrings.imageUnavailable), findsOneWidget);
    });

    testWidgets('按块里的路径读取本地文件', (tester) async {
      await pumpInside(
        tester,
        parentBuilder: scrollingParent,
        block: blockWithoutCaption,
      );

      final figure = tester.widget<IllustrationFigure>(
        find.byType(IllustrationFigure),
      );
      expect(figure.image, isA<FileImage>());
      expect((figure.image as FileImage).file.path, missingImagePath);
    });
  });

  group('说明文字', () {
    testWidgets('有说明时显示说明，并用它作图片的语义标签', (tester) async {
      await pumpInside(
        tester,
        parentBuilder: scrollingParent,
        block: blockWithCaption,
      );

      expect(find.text(caption), findsOneWidget);
      expect(find.bySemanticsLabel(caption), findsOneWidget);
      expect(
        find.bySemanticsLabel(IllustrationStrings.genericSemanticsLabel),
        findsNothing,
      );
    });

    testWidgets('没有说明时不显示说明，图片用通用语义标签', (tester) async {
      await pumpInside(
        tester,
        parentBuilder: scrollingParent,
        block: blockWithoutCaption,
      );

      expect(find.text(caption), findsNothing);
      expect(
        find.bySemanticsLabel(IllustrationStrings.genericSemanticsLabel),
        findsOneWidget,
      );
    });

    testWidgets('只有空白的说明按没有说明处理', (tester) async {
      await pumpInside(
        tester,
        parentBuilder: scrollingParent,
        block: blockWithCaption.copyWith(caption: () => '   '),
      );

      expect(
        find.bySemanticsLabel(IllustrationStrings.genericSemanticsLabel),
        findsOneWidget,
      );
    });
  });

  group('尺寸服从父级约束', () {
    testWidgets('高度不设上限时，宽度不超过可用宽度，高度不超过兜底上限', (tester) async {
      await pumpInside(
        tester,
        parentBuilder: scrollingParent,
        block: blockWithCaption,
      );

      expect(tester.takeException(), isNull);
      expect(blockSize(tester).width, lessThanOrEqualTo(availableWidth));
      expect(
        blockSize(tester).height,
        lessThanOrEqualTo(IllustrationLayoutConstants.maxHeightWhenUnbounded),
      );
    });

    testWidgets('高度有上限时不溢出，占位等比缩小', (tester) async {
      const pageHeight = 120.0;

      await pumpInside(
        tester,
        parentBuilder: boundedParent(maxHeight: pageHeight),
        block: blockWithCaption,
      );

      final placeholderSize = tester.getSize(
        find.byType(IllustrationPlaceholder),
      );
      expect(tester.takeException(), isNull);
      expect(blockSize(tester).height, lessThanOrEqualTo(pageHeight));
      expect(blockSize(tester).width, lessThanOrEqualTo(availableWidth));
      expect(
        placeholderSize.width / placeholderSize.height,
        closeTo(IllustrationLayoutConstants.placeholderAspectRatio, 0.01),
      );
    });

    testWidgets('高度有上限且说明很长时仍不溢出，图片保有大部分高度', (tester) async {
      const pageHeight = 200.0;

      await pumpInside(
        tester,
        parentBuilder: boundedParent(maxHeight: pageHeight),
        block: blockWithCaption.copyWith(caption: () => longCaption),
      );

      final placeholderHeight = tester
          .getSize(find.byType(IllustrationPlaceholder))
          .height;
      const minImageHeightFraction =
          1 - IllustrationLayoutConstants.captionMaxHeightFraction;
      expect(tester.takeException(), isNull);
      expect(blockSize(tester).height, lessThanOrEqualTo(pageHeight));
      expect(
        placeholderHeight,
        greaterThanOrEqualTo(pageHeight * minImageHeightFraction - 0.01),
      );
    });

    testWidgets('高度上限极小时也不溢出', (tester) async {
      const pageHeight = 16.0;

      await pumpInside(
        tester,
        parentBuilder: boundedParent(maxHeight: pageHeight),
        block: blockWithCaption.copyWith(caption: () => longCaption),
      );

      expect(tester.takeException(), isNull);
      expect(blockSize(tester).height, lessThanOrEqualTo(pageHeight));
    });

    testWidgets('父级把高度定死时填满该高度而不溢出', (tester) async {
      const pageHeight = 160.0;

      await pumpInside(
        tester,
        parentBuilder: (illustration) => SizedBox(
          width: availableWidth,
          height: pageHeight,
          child: illustration,
        ),
        block: blockWithCaption,
      );

      expect(tester.takeException(), isNull);
      expect(blockSize(tester), const Size(availableWidth, pageHeight));
    });
  });
}

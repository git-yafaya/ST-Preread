import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/illustration_layout_constants.dart';
import 'package:st_preread/core/constants/illustration_strings.dart';
import 'package:st_preread/features/illustration/illustration_figure.dart';
import 'package:st_preread/features/illustration/illustration_placeholder.dart';

import 'loaded_image_provider.dart';

void main() {
  const availableWidth = 300.0;
  const caption = '雨夜的车站';

  /// 生成一张指定像素尺寸的图片。解码由引擎在真实事件循环里完成，
  /// 所以要放进 runAsync；这里等的是「解码完成」这件事，不是一段时间。
  Future<ImageProvider> loadedImage(
    WidgetTester tester, {
    required int width,
    required int height,
  }) async {
    final ui.Image? image = await tester.runAsync(
      () => createTestImage(width: width, height: height),
    );
    addTearDown(image!.dispose);
    return LoadedImageProvider(image);
  }

  Future<void> pumpFigure(
    WidgetTester tester, {
    required ImageProvider image,
    required BoxConstraints parentConstraints,
    String? caption,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: parentConstraints,
                child: IllustrationFigure(image: image, caption: caption),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Size shownImageSize(WidgetTester tester) {
    return tester.getSize(find.byType(RawImage));
  }

  testWidgets('图片读出来后显示图片，不显示占位', (tester) async {
    final image = await loadedImage(tester, width: 200, height: 100);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: const BoxConstraints(maxWidth: availableWidth),
    );

    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(IllustrationPlaceholder), findsNothing);
  });

  testWidgets('比可用宽度宽的图按宽度等比缩小', (tester) async {
    final image = await loadedImage(tester, width: 600, height: 300);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: const BoxConstraints(maxWidth: availableWidth),
    );

    expect(shownImageSize(tester), const Size(availableWidth, 150));
  });

  testWidgets('高度有上限时，竖长图按高度等比缩小', (tester) async {
    const pageHeight = 200.0;
    final image = await loadedImage(tester, width: 200, height: 800);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: const BoxConstraints(
        maxWidth: availableWidth,
        maxHeight: pageHeight,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(shownImageSize(tester), const Size(50, pageHeight));
  });

  testWidgets('高度不设上限时，竖长图缩到兜底高度以内', (tester) async {
    const maxHeight = IllustrationLayoutConstants.maxHeightWhenUnbounded;
    final image = await loadedImage(tester, width: 200, height: 2000);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: const BoxConstraints(maxWidth: availableWidth),
    );

    expect(shownImageSize(tester), const Size(maxHeight / 10, maxHeight));
  });

  testWidgets('比可用空间小的图保持原尺寸，不放大', (tester) async {
    final image = await loadedImage(tester, width: 120, height: 60);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: const BoxConstraints(maxWidth: availableWidth),
    );

    expect(shownImageSize(tester), const Size(120, 60));
  });

  testWidgets('高度有上限且带说明时，图片与说明合起来不超过上限', (tester) async {
    const pageHeight = 200.0;
    final image = await loadedImage(tester, width: 200, height: 800);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: const BoxConstraints(
        maxWidth: availableWidth,
        maxHeight: pageHeight,
      ),
      caption: caption,
    );

    final imageSize = shownImageSize(tester);
    final captionHeight = tester.getSize(find.text(caption)).height;
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(IllustrationFigure)).height,
      lessThanOrEqualTo(pageHeight),
    );
    expect(imageSize.height + captionHeight, lessThanOrEqualTo(pageHeight));
    expect(imageSize.height / imageSize.width, closeTo(800 / 200, 0.01));
  });

  testWidgets('读出来的图片带语义标签：有说明用说明，没有用通用文案', (tester) async {
    final image = await loadedImage(tester, width: 200, height: 100);
    const parentConstraints = BoxConstraints(maxWidth: availableWidth);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: parentConstraints,
      caption: caption,
    );
    expect(find.bySemanticsLabel(caption), findsOneWidget);

    await pumpFigure(
      tester,
      image: image,
      parentConstraints: parentConstraints,
    );
    expect(
      find.bySemanticsLabel(IllustrationStrings.genericSemanticsLabel),
      findsOneWidget,
    );
  });
}

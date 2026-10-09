import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';

/// 渲染 [sidedText] 这一面文字的片段（按实例找，两面文字内容相同也不会混淆）。
Finder findFragmentOf(SidedText sidedText) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextFragmentView && identical(widget.sidedText, sidedText),
  );
}

/// 片段里实际排版文字的渲染对象。测试直接向文本布局取位置，
/// 不经过被测代码自己的定位方法，避免「用被测逻辑验证被测逻辑」。
RenderParagraph paragraphOf(WidgetTester tester, Finder fragment) {
  return tester.renderObject<RenderParagraph>(
    find.descendant(of: fragment, matching: find.byType(RichText)),
  );
}

/// 片段的富文本里各个分段的 TextSpan。
List<TextSpan> segmentSpansOf(WidgetTester tester, Finder fragment) {
  final richText = tester.widget<RichText>(
    find.descendant(of: fragment, matching: find.byType(RichText)),
  );
  return (richText.text as TextSpan).children!.cast<TextSpan>();
}

/// 片段内从第 [offsetInFragment] 个码元开始的那个字符的包围盒（片段自身坐标，占满行高）。
///
/// emoji 这样的字符占两个码元（代理对），只取前一半量不出包围盒，所以整对一起取。
Rect characterBoxOf(
  WidgetTester tester,
  Finder fragment,
  int offsetInFragment,
) {
  final paragraph = paragraphOf(tester, fragment);
  final codeUnit = paragraph.text.toPlainText().codeUnitAt(offsetInFragment);
  final isHighSurrogate = codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(
      baseOffset: offsetInFragment,
      extentOffset: offsetInFragment + (isHighSurrogate ? 2 : 1),
    ),
    boxHeightStyle: ui.BoxHeightStyle.max,
  );
  return boxes.first.toRect();
}

/// 片段内第 [offsetInFragment] 个码元所在字符的中心点（全局坐标）。
Offset globalCenterOfCharacter(
  WidgetTester tester,
  Finder fragment,
  int offsetInFragment,
) {
  final box = characterBoxOf(tester, fragment, offsetInFragment);
  return paragraphOf(tester, fragment).localToGlobal(box.center);
}

/// 片段内第 [offsetInFragment] 个码元所在那一行的行顶（全局纵坐标）。
double globalLineTopOf(
  WidgetTester tester,
  Finder fragment,
  int offsetInFragment,
) {
  final box = characterBoxOf(tester, fragment, offsetInFragment);
  return paragraphOf(tester, fragment).localToGlobal(box.topLeft).dy;
}

/// 点一下 [sidedText] 这一面的第 [sentenceIndex] 句（点它的第一个字符）。
/// 只适用于从头渲染整面文字的片段。
Future<void> tapSentence(
  WidgetTester tester,
  SidedText sidedText,
  int sentenceIndex,
) async {
  await tester.tapAt(
    globalCenterOfCharacter(
      tester,
      findFragmentOf(sidedText),
      sidedText.sentences[sentenceIndex].startOffset,
    ),
  );
  await tester.pump();
}

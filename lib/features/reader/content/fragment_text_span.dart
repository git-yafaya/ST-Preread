import 'package:flutter/painting.dart';

import '../../../domain/domain.dart';
import 'reader_text_theme.dart';
import 'side_highlight.dart';
import 'text_segment.dart';

/// 构建一面文字的切片 `[startOffset, endOffset)` 的富文本（[endOffset] 为 null 表示到结尾）。
///
/// 文字片段 Widget 用它渲染，分页算法用它配合 TextPainter 测量，
/// 两边拿到的是同一份样式，量出来的换行才和画出来的一致。
/// 调用方要保证切片的起止不落在一个字素簇中间。
TextSpan buildFragmentTextSpan({
  required SidedText sidedText,
  required ReaderTextTheme textTheme,
  required ParagraphStyle paragraphStyle,
  required TextRole role,
  required SideHighlight highlight,
  int startOffset = 0,
  int? endOffset,
}) {
  final segments = buildTextSegments(
    sidedText: sidedText,
    highlight: highlight,
    startOffset: startOffset,
    endOffset: endOffset,
  );
  return TextSpan(
    style: textTheme.blockStyleOf(paragraphStyle: paragraphStyle, role: role),
    children: [
      for (final segment in segments)
        TextSpan(
          text: sidedText.text.substring(
            segment.startOffset,
            segment.endOffset,
          ),
          style: textTheme.segmentStyleOf(segment),
        ),
    ],
  );
}

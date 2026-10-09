import 'package:flutter/widgets.dart';

import '../../../core/constants/reader_layout_constants.dart';
import '../../../domain/domain.dart';
import 'reader_text_theme.dart';

/// 段落块级样式里「文字之外」的装饰：目前只有引用段左侧的竖线与缩进。
///
/// 单独成一个组件，是因为翻页模式把段落拆成切片后，每个切片都要套上同样的装饰。
class ParagraphFrame extends StatelessWidget {
  const ParagraphFrame({
    required this.paragraphStyle,
    required this.textTheme,
    required this.child,
    super.key,
  });

  final ParagraphStyle paragraphStyle;
  final ReaderTextTheme textTheme;
  final Widget child;

  /// 装饰在水平方向占掉的宽度；分页测量文字时要先从可用宽度里减去它。
  static double horizontalInsetOf(ParagraphStyle paragraphStyle) {
    return switch (paragraphStyle) {
      ParagraphStyle.quote =>
        ReaderLayoutConstants.quoteBarWidth +
            ReaderLayoutConstants.quoteTextIndent,
      ParagraphStyle.body ||
      ParagraphStyle.heading1 ||
      ParagraphStyle.heading2 ||
      ParagraphStyle.heading3 => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (paragraphStyle != ParagraphStyle.quote) {
      return child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: textTheme.quoteBarColor,
            width: ReaderLayoutConstants.quoteBarWidth,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: horizontalInsetOf(paragraphStyle),
        ),
        child: child,
      ),
    );
  }
}

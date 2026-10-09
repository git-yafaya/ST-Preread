import 'package:flutter/material.dart';

import '../../../core/constants/bilingual_text_constants.dart';
import '../../../core/constants/reader_text_style_constants.dart';
import '../../../domain/domain.dart';
import 'text_segment.dart';

/// 一面文字在段落里的角色：主文正常显示，辅文缩小并减淡。
enum TextRole { primary, secondary }

/// 正文的全部文字样式与配色，由应用主题和字号倍数算出。
///
/// 渲染与分页的文本测量必须用同一份样式，否则量出来的换行位置和实际画出来的对不上；
/// 所以两种视图都从这里取样式，而不是各自拼 TextStyle。
@immutable
class ReaderTextTheme {
  const ReaderTextTheme._({
    required this.bodyStyle,
    required this.secondaryTextColor,
    required this.playableUnderlineColor,
    required this.activeSentenceHighlightColor,
    required this.companionHighlightColor,
    required this.inlineCodeBackgroundColor,
    required this.quoteBarColor,
  });

  /// [fontScale] 是阅读设置里的字号倍数；系统的字体缩放不在这里处理，
  /// 仍由 MediaQuery 的 TextScaler 在排版时叠加。
  factory ReaderTextTheme.fromTheme(
    ThemeData theme, {
    required double fontScale,
  }) {
    final colorScheme = theme.colorScheme;
    final baseStyle = theme.textTheme.bodyLarge ?? const TextStyle();
    return ReaderTextTheme._(
      bodyStyle: baseStyle.copyWith(
        fontSize: ReaderTextStyleConstants.bodyFontSize * fontScale,
        height: ReaderTextStyleConstants.bodyLineHeight,
        color: colorScheme.onSurface,
      ),
      secondaryTextColor: colorScheme.onSurface.withValues(
        alpha: ReaderTextStyleConstants.secondaryTextOpacity,
      ),
      playableUnderlineColor: colorScheme.primary.withValues(
        alpha: ReaderTextStyleConstants.playableUnderlineOpacity,
      ),
      activeSentenceHighlightColor: colorScheme.primary.withValues(
        alpha: ReaderTextStyleConstants.activeSentenceHighlightOpacity,
      ),
      companionHighlightColor: colorScheme.primary.withValues(
        alpha: ReaderTextStyleConstants.companionHighlightOpacity,
      ),
      inlineCodeBackgroundColor: colorScheme.surfaceContainerHighest,
      quoteBarColor: colorScheme.outlineVariant,
    );
  }

  /// 主文正文的样式，字号已乘上字号倍数。
  final TextStyle bodyStyle;
  final Color secondaryTextColor;
  final Color playableUnderlineColor;
  final Color activeSentenceHighlightColor;
  final Color companionHighlightColor;
  final Color inlineCodeBackgroundColor;
  final Color quoteBarColor;

  /// 主文正文的字号（已含字号倍数）。
  double get bodyFontSize =>
      bodyStyle.fontSize ?? ReaderTextStyleConstants.bodyFontSize;

  /// 一个文字片段的基准样式：块级样式与主文 / 辅文两层叠加的结果。
  TextStyle blockStyleOf({
    required ParagraphStyle paragraphStyle,
    required TextRole role,
  }) {
    final isHeading = _headingFontScales.containsKey(paragraphStyle);
    final isSecondary = role == TextRole.secondary;
    final roleFontScale = isSecondary
        ? BilingualTextConstants.secondaryTextFontScale
        : 1.0;
    return bodyStyle.copyWith(
      fontSize:
          bodyFontSize *
          (_headingFontScales[paragraphStyle] ?? 1) *
          roleFontScale,
      fontWeight: isHeading ? FontWeight.bold : null,
      height: isHeading ? ReaderTextStyleConstants.headingLineHeight : null,
      color: isSecondary ? secondaryTextColor : null,
    );
  }

  /// 一个分段在基准样式之上要改的属性；没有任何特殊样式时返回 null。
  TextStyle? segmentStyleOf(TextSegment segment) {
    final inlineStyles = segment.inlineStyles;
    final backgroundColor = _backgroundColorOf(segment);
    final decoration = _decorationOf(segment);
    if (inlineStyles.isEmpty && backgroundColor == null && decoration == null) {
      return null;
    }
    final hasStrikethrough = inlineStyles.contains(InlineStyle.strikethrough);
    final isCode = inlineStyles.contains(InlineStyle.code);
    return TextStyle(
      fontWeight: inlineStyles.contains(InlineStyle.bold)
          ? FontWeight.bold
          : null,
      fontStyle: inlineStyles.contains(InlineStyle.italic)
          ? FontStyle.italic
          : null,
      fontFamily: isCode ? ReaderTextStyleConstants.inlineCodeFontFamily : null,
      backgroundColor: backgroundColor,
      decoration: decoration,
      // 同一段文字的多条装饰线只能共用一种颜色。删除线是作者写下的内容，
      // 必须保持文字本身的颜色，所以两者重叠时下划线跟着用文字颜色。
      decorationColor: segment.isPlayable && !hasStrikethrough
          ? playableUnderlineColor
          : null,
      decorationThickness: segment.isPlayable
          ? ReaderTextStyleConstants.playableUnderlineThickness
          : null,
    );
  }

  /// 播放高亮盖过行内代码的底色：正在播哪一句比「这是代码」更需要一眼看到。
  Color? _backgroundColorOf(TextSegment segment) {
    return switch (segment.highlight) {
      SegmentHighlight.activeSentence => activeSentenceHighlightColor,
      SegmentHighlight.companion => companionHighlightColor,
      SegmentHighlight.none =>
        segment.inlineStyles.contains(InlineStyle.code)
            ? inlineCodeBackgroundColor
            : null,
    };
  }

  TextDecoration? _decorationOf(TextSegment segment) {
    final decorations = [
      if (segment.isPlayable) TextDecoration.underline,
      if (segment.inlineStyles.contains(InlineStyle.strikethrough))
        TextDecoration.lineThrough,
    ];
    if (decorations.isEmpty) {
      return null;
    }
    return TextDecoration.combine(decorations);
  }
}

const Map<ParagraphStyle, double> _headingFontScales = {
  ParagraphStyle.heading1: ReaderTextStyleConstants.heading1FontScale,
  ParagraphStyle.heading2: ReaderTextStyleConstants.heading2FontScale,
  ParagraphStyle.heading3: ReaderTextStyleConstants.heading3FontScale,
};

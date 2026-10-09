/// 阅读页正文的排版尺寸（逻辑像素）。滚动与翻页两种视图共用，保证两边的版心一致。
abstract final class ReaderLayoutConstants {
  static const double pageHorizontalPadding = 20;
  static const double pageVerticalPadding = 16;

  /// 相邻两个块之间的间距。
  static const double blockSpacing = 18;

  /// 对照显示时主文与辅文之间的间距：比块间距小，让同一段的两面看起来是一组。
  static const double secondaryTextSpacing = 6;

  static const double quoteBarWidth = 3;

  /// 引用段的竖线与文字之间的间距。
  static const double quoteTextIndent = 12;

  static const double dividerVerticalPadding = 8;

  /// 换章入口上下的留白：与正文拉开距离，避免滚动阅读时误触。
  static const double chapterBoundaryEntryVerticalPadding = 24;

  /// 判断「哪一行在视口顶部」时向下探的距离。
  /// 定位后行顶与视口顶部只在浮点误差内重合，不留余量会误判成上一行。
  static const double anchorProbeTolerance = 1;

  static const double drawerHeaderPadding = 16;

  static const double failureIconSize = 48;
  static const double failureContentSpacing = 16;
}

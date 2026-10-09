/// 书架页的尺寸与排版参数。长度单位均为逻辑像素。
abstract final class BookshelfLayoutConstants {
  /// 用「卡片最大宽度」而不是固定列数来决定网格列数：
  /// 手机竖屏得到两列，横屏与平板自动变多，不必为每种屏幕单独配置。
  static const double gridMaxCardWidth = 180;

  /// 卡片宽高比（宽 / 高）。高出的部分留给封面下方的书名、作者与章节数。
  static const double cardAspectRatio = 0.55;

  static const double gridSpacing = 12;
  static const double gridPadding = 16;

  /// 网格底部多留一段空白，让最后一行卡片能滚到悬浮的导入按钮上方。
  static const double gridBottomPadding = 96;

  static const double cardInfoPaddingStart = 12;
  static const double cardInfoPaddingVertical = 8;
  static const double cardInfoLineSpacing = 2;

  static const int bookTitleMaxLines = 2;
  static const int bookAuthorMaxLines = 1;

  static const double placeholderCoverIconSize = 48;

  /// 正在删除的卡片变淡，提示它暂时不可操作。
  static const double deletingCardOpacity = 0.5;
  static const double normalCardOpacity = 1;

  static const double statusViewPadding = 24;
  static const double statusViewIconSize = 72;
  static const double statusViewSpacing = 16;
  static const double statusViewMessageSpacing = 8;

  static const double importProgressIndicatorSize = 18;
  static const double importProgressIndicatorStrokeWidth = 2;
}

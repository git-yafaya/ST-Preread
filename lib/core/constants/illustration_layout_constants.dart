/// 插图块的尺寸。
abstract final class IllustrationLayoutConstants {
  /// 父级没有限制高度（如滚动阅读）时，整个插图块的最大高度：
  /// 竖长图不至于占满好几屏。
  static const double maxHeightWhenUnbounded = 480;

  /// 说明文字最多占用可用高度的比例，剩下的留给图片；
  /// 这样说明再长也不会把图片挤没，更不会撑破父级给的高度。
  static const double captionMaxHeightFraction = 0.4;

  static const double captionTopSpacing = 8;
  static const double imageCornerRadius = 8;

  /// 占位的宽高比。图片读不出来时无从得知原图比例，统一用横向 4:3。
  static const double placeholderAspectRatio = 4 / 3;
  static const double placeholderIconSize = 40;
  static const double placeholderPadding = 12;
  static const double placeholderIconToTextSpacing = 8;
}

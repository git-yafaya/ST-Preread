/// 精简播放条的尺寸与动画参数。
abstract final class PlayerLayoutConstants {
  /// 播放条出现与消失的过渡时长。
  static const Duration visibilityTransitionDuration = Duration(
    milliseconds: 200,
  );

  static const double elevation = 3;
  static const double progressTrackHeight = 4;
  static const double horizontalPadding = 16;
  static const double verticalPadding = 4;
}

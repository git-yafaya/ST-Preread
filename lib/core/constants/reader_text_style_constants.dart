/// 阅读页正文的文字样式参数。
abstract final class ReaderTextStyleConstants {
  /// 字号倍数为 1 时主文正文的字号。
  static const double bodyFontSize = 17;

  /// 正文行高倍数：中日文方块字排得密，行距宽一些才不费眼。
  static const double bodyLineHeight = 1.7;

  /// 标题行高倍数：标题字大，沿用正文行高会显得松散。
  static const double headingLineHeight = 1.4;

  static const double heading1FontScale = 1.5;
  static const double heading2FontScale = 1.3;
  static const double heading3FontScale = 1.15;

  /// 辅文颜色相对主文的不透明度。
  static const double secondaryTextOpacity = 0.62;

  /// 「这一句带语音」的下划线取主题主色的不透明度：
  /// 要淡到不干扰阅读，又要和文字本身颜色的删除线分得开。
  static const double playableUnderlineOpacity = 0.55;
  static const double playableUnderlineThickness = 1;

  /// 被播句子的高亮取主题主色的不透明度。
  static const double activeSentenceHighlightOpacity = 0.28;

  /// 对照显示时另一面整段的高亮，比被播句子更淡。
  static const double companionHighlightOpacity = 0.1;

  static const String inlineCodeFontFamily = 'monospace';
}

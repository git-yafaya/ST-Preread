/// 翻阅方式。
enum PageTurnMode { scroll, paged }

/// 阅读主题。
enum ReaderThemeMode { system, light, dark }

/// 双语显示方式。[both] 为译文为主、原文为辅，是默认方式。
enum BilingualDisplayMode { both, translationOnly, sourceOnly }

/// 阅读设置。
class ReaderSettings {
  const ReaderSettings({
    required this.fontScale,
    required this.themeMode,
    required this.pageTurnMode,
    required this.displayMode,
  });

  /// 相对默认字号的倍数；取值范围见 core 常量 ReaderSettingLimits。
  final double fontScale;
  final ReaderThemeMode themeMode;
  final PageTurnMode pageTurnMode;
  final BilingualDisplayMode displayMode;

  ReaderSettings copyWith({
    double? fontScale,
    ReaderThemeMode? themeMode,
    PageTurnMode? pageTurnMode,
    BilingualDisplayMode? displayMode,
  }) {
    return ReaderSettings(
      fontScale: fontScale ?? this.fontScale,
      themeMode: themeMode ?? this.themeMode,
      pageTurnMode: pageTurnMode ?? this.pageTurnMode,
      displayMode: displayMode ?? this.displayMode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderSettings &&
        other.fontScale == fontScale &&
        other.themeMode == themeMode &&
        other.pageTurnMode == pageTurnMode &&
        other.displayMode == displayMode;
  }

  @override
  int get hashCode =>
      Object.hash(fontScale, themeMode, pageTurnMode, displayMode);

  @override
  String toString() =>
      'ReaderSettings(fontScale: $fontScale, themeMode: ${themeMode.name}, '
      'pageTurnMode: ${pageTurnMode.name}, displayMode: ${displayMode.name})';
}

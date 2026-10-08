import 'package:flutter/material.dart';

import '../core/constants/app_theme_constants.dart';
import '../domain/domain.dart';

/// 构建指定明暗的 Material 3 主题；浅色与深色共用同一个种子色。
ThemeData buildAppTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(AppThemeConstants.seedColorValue),
      brightness: brightness,
    ),
  );
}

/// 领域层不依赖 Flutter，所以阅读主题在这里换算成框架的 ThemeMode。
ThemeMode toMaterialThemeMode(ReaderThemeMode readerThemeMode) {
  return switch (readerThemeMode) {
    ReaderThemeMode.system => ThemeMode.system,
    ReaderThemeMode.light => ThemeMode.light,
    ReaderThemeMode.dark => ThemeMode.dark,
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../core/providers/providers.dart';
import '../domain/domain.dart';
import 'app_router.dart';
import 'app_theme.dart';

/// 应用外壳：主题跟随阅读设置，页面由路由表决定。
class StPrereadApp extends ConsumerWidget {
  const StPrereadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 设置尚未读到时先跟随系统，避免启动瞬间出现错误的明暗。
    final readerThemeMode =
        ref.watch(readerSettingsProvider).value?.themeMode ??
        ReaderThemeMode.system;
    return MaterialApp.router(
      title: AppStrings.appTitle,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: toMaterialThemeMode(readerThemeMode),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

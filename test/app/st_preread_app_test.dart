import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:st_preread/app/mock_provider_bindings.dart';
import 'package:st_preread/app/st_preread_app.dart';
import 'package:st_preread/core/constants/app_routes.dart';
import 'package:st_preread/core/constants/app_strings.dart';
import 'package:st_preread/core/constants/placeholder_strings.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/data/mock/mock_reader_settings_repository.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/bookshelf/bookshelf_page.dart';
import 'package:st_preread/features/reader/reader_page.dart';

void main() {
  /// 传入 [settingsRepository] 时只绑定它：同一个 provider 不能在一个容器里
  /// 绑定两次，而这些用例也只用得到设置仓库。
  Future<void> pumpApp(
    WidgetTester tester, {
    MockReaderSettingsRepository? settingsRepository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: settingsRepository == null
            ? buildMockProviderBindings()
            : [
                readerSettingsRepositoryProvider.overrideWithValue(
                  settingsRepository,
                ),
              ],
        child: const StPrereadApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  MaterialApp findMaterialApp(WidgetTester tester) {
    return tester.widget<MaterialApp>(find.byType(MaterialApp));
  }

  void goTo(WidgetTester tester, String location) {
    GoRouter.of(tester.element(find.byType(Scaffold))).go(location);
  }

  group('启动', () {
    testWidgets('应用能启动并显示书架占位页', (tester) async {
      await pumpApp(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
      expect(find.text(PlaceholderStrings.bookshelfPage), findsOneWidget);
      expect(find.text(AppStrings.appTitle), findsOneWidget);
    });

    testWidgets('使用 Material 3 的浅色与深色主题', (tester) async {
      await pumpApp(tester);

      final materialApp = findMaterialApp(tester);
      expect(materialApp.theme?.useMaterial3, isTrue);
      expect(materialApp.theme?.colorScheme.brightness, Brightness.light);
      expect(materialApp.darkTheme?.colorScheme.brightness, Brightness.dark);
    });
  });

  group('路由', () {
    testWidgets('进入 /books/:bookId 显示对应书籍的阅读占位页', (tester) async {
      await pumpApp(tester);

      goTo(tester, AppRoutes.readerLocation('sample-book-1'));
      await tester.pumpAndSettle();

      expect(find.text(PlaceholderStrings.readerPage), findsOneWidget);
      expect(
        tester.widget<ReaderPage>(find.byType(ReaderPage)).bookId,
        'sample-book-1',
      );
    });

    testWidgets('书籍 id 含特殊字符时仍能原样传到阅读页', (tester) async {
      const bookId = '我的书/第 1 版';
      await pumpApp(tester);

      goTo(tester, AppRoutes.readerLocation(bookId));
      await tester.pumpAndSettle();

      expect(tester.widget<ReaderPage>(find.byType(ReaderPage)).bookId, bookId);
    });

    testWidgets('从阅读页可以回到书架页', (tester) async {
      await pumpApp(tester);
      goTo(tester, AppRoutes.readerLocation('sample-book-1'));
      await tester.pumpAndSettle();

      goTo(tester, AppRoutes.bookshelf);
      await tester.pumpAndSettle();

      expect(find.byType(BookshelfPage), findsOneWidget);
      expect(find.byType(ReaderPage), findsNothing);
    });
  });

  group('主题跟随阅读设置', () {
    testWidgets('默认设置下跟随系统', (tester) async {
      await pumpApp(tester);

      expect(findMaterialApp(tester).themeMode, ThemeMode.system);
    });

    testWidgets('设置为深色时应用使用深色主题', (tester) async {
      final settingsRepository = MockReaderSettingsRepository(
        initialSettings: MockReaderSettingsRepository.defaultSettings.copyWith(
          themeMode: ReaderThemeMode.dark,
        ),
      );
      addTearDown(settingsRepository.dispose);

      await pumpApp(tester, settingsRepository: settingsRepository);

      expect(findMaterialApp(tester).themeMode, ThemeMode.dark);
    });

    testWidgets('运行中修改设置后主题随之切换', (tester) async {
      final settingsRepository = MockReaderSettingsRepository();
      addTearDown(settingsRepository.dispose);
      await pumpApp(tester, settingsRepository: settingsRepository);

      await settingsRepository.saveSettings(
        MockReaderSettingsRepository.defaultSettings.copyWith(
          themeMode: ReaderThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(findMaterialApp(tester).themeMode, ThemeMode.light);
    });
  });
}

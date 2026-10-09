import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:st_preread/core/constants/app_routes.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/constants/reader_strings.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/data/mock/mock_reader_settings_repository.dart';
import 'package:st_preread/features/reader/widgets/reader_app_bar.dart';
import 'package:st_preread/features/settings/reader_settings_sheet.dart';

void main() {
  const bookshelfKey = Key('bookshelf');
  const drawerKey = Key('contents-drawer');
  const readerLocation = '/reader';

  Widget buildReaderScaffold({bool isContentsAvailable = true}) {
    return Scaffold(
      appBar: ReaderAppBar(
        title: '第一章',
        isContentsAvailable: isContentsAvailable,
      ),
      drawer: const Drawer(key: drawerKey),
    );
  }

  /// 设置面板要读取阅读设置，顶栏弹出它时外层必须有绑定了设置仓库的 ProviderScope，
  /// 与应用根部的搭建保持一致。
  Future<void> pumpWithSettingsRepository(WidgetTester tester) async {
    final settingsRepository = MockReaderSettingsRepository(
      initialSettings: defaultReaderSettings,
    );
    addTearDown(settingsRepository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
        child: MaterialApp(home: buildReaderScaffold()),
      ),
    );
  }

  /// 用真实的路由器承载顶栏：书架在 `/`，阅读页在 [readerLocation]。
  Future<GoRouter> pumpWithRouter(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: readerLocation,
      routes: [
        GoRoute(
          path: AppRoutes.bookshelf,
          builder: (context, state) => const Scaffold(key: bookshelfKey),
        ),
        GoRoute(
          path: readerLocation,
          builder: (context, state) => buildReaderScaffold(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapBack(WidgetTester tester) async {
    await tester.tap(find.byTooltip(ReaderStrings.backTooltip));
    await tester.pumpAndSettle();
  }

  group('标题与入口', () {
    testWidgets('显示标题', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildReaderScaffold()));

      expect(find.text('第一章'), findsOneWidget);
    });

    testWidgets('目录入口打开页内抽屉', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildReaderScaffold()));

      await tester.tap(find.byTooltip(ReaderStrings.tableOfContents));
      await tester.pumpAndSettle();

      expect(find.byKey(drawerKey), findsOneWidget);
    });

    testWidgets('目录还没加载出来时目录入口不可点', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: buildReaderScaffold(isContentsAvailable: false)),
      );

      await tester.tap(find.byTooltip(ReaderStrings.tableOfContents));
      await tester.pumpAndSettle();

      expect(find.byKey(drawerKey), findsNothing);
    });

    testWidgets('设置入口以底部面板弹出阅读设置', (tester) async {
      await pumpWithSettingsRepository(tester);

      await tester.tap(find.byTooltip(ReaderStrings.settingsTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(ReaderSettingsSheet), findsOneWidget);
    });
  });

  group('返回', () {
    testWidgets('阅读页是从书架进入的：返回键退回书架', (tester) async {
      final router = await pumpWithRouter(tester);
      router.go(AppRoutes.bookshelf);
      await tester.pumpAndSettle();
      router.push(readerLocation);
      await tester.pumpAndSettle();

      await tapBack(tester);

      expect(find.byKey(bookshelfKey), findsOneWidget);
      expect(find.byType(ReaderAppBar), findsNothing);
    });

    testWidgets('阅读页是被直接打开的、没有上一页：返回键改为去书架', (tester) async {
      await pumpWithRouter(tester);

      await tapBack(tester);

      expect(find.byKey(bookshelfKey), findsOneWidget);
      expect(find.byType(ReaderAppBar), findsNothing);
    });
  });
}

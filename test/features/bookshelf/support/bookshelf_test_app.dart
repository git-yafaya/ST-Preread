import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:st_preread/core/constants/app_routes.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/bookshelf/bookshelf_page.dart';

/// 顶替阅读页的探针：只记下路由交给它的书籍 id。
///
/// 书架的测试只关心「跳到了哪里」，不应依赖阅读页的实现。
class OpenedBookProbe extends StatelessWidget {
  const OpenedBookProbe({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar());
  }
}

/// 在与正式应用相同的路由路径下挂起书架页，书库换成 [repository]。
///
/// 不调用 pumpAndSettle：加载中与导入中的转圈动画永不停止，由各用例自行决定如何推进。
Future<void> pumpBookshelf(
  WidgetTester tester,
  BookRepository repository,
) async {
  final router = GoRouter(
    initialLocation: AppRoutes.bookshelf,
    routes: [
      GoRoute(
        path: AppRoutes.bookshelf,
        builder: (context, state) => const BookshelfPage(),
      ),
      GoRoute(
        path: AppRoutes.reader,
        builder: (context, state) => OpenedBookProbe(
          bookId: state.pathParameters[AppRoutes.bookIdParameter]!,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bookRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

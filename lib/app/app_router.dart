import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/bookshelf/bookshelf_page.dart';
import '../features/reader/reader_page.dart';

/// 应用的路由表。目录是阅读页内的抽屉，不单独设路由。
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.bookshelf,
    routes: [
      GoRoute(
        path: AppRoutes.bookshelf,
        builder: (context, state) => const BookshelfPage(),
      ),
      GoRoute(
        path: AppRoutes.reader,
        builder: (context, state) => ReaderPage(
          // 路径模式里声明了这个参数，匹配到本路由时它一定存在。
          bookId: state.pathParameters[AppRoutes.bookIdParameter]!,
        ),
      ),
    ],
  );
}

/// 路由器持有导航状态，必须在应用存续期间保持同一个实例，
/// 不能随界面重建而重新创建。
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

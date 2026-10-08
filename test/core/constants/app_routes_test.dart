import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('阅读页路径模式包含书籍 id 参数', () {
      expect(AppRoutes.bookshelf, '/');
      expect(AppRoutes.reader, '/books/:${AppRoutes.bookIdParameter}');
    });

    test('readerLocation 生成具体书籍的路径', () {
      expect(AppRoutes.readerLocation('sample-book-1'), '/books/sample-book-1');
    });

    test('readerLocation 转义会破坏路径结构的字符', () {
      final location = AppRoutes.readerLocation('我的书/第 1 版');
      expect(location.split('/'), hasLength(3));
      expect(location, isNot(contains(' ')));
      expect(Uri.decodeComponent(location.split('/').last), '我的书/第 1 版');
    });
  });
}

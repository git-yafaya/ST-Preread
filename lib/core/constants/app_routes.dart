/// 路由路径集中在这里，页面跳转时不手写路径字符串。
abstract final class AppRoutes {
  static const String bookshelf = '/';

  static const String bookIdParameter = 'bookId';

  static const String reader = '/books/:$bookIdParameter';

  /// 书籍 id 来自导出物，可能含有 `/`、空格等字符，必须转义后才能放进路径。
  static String readerLocation(String bookId) =>
      '/books/${Uri.encodeComponent(bookId)}';
}

/// 书架页面向用户的文案。
abstract final class BookshelfStrings {
  static const String pageTitle = '书架';

  static const String loadingBooks = '正在加载书架';

  static const String emptyTitle = '书架还是空的';
  static const String emptyMessage = '导入一本从 SillyTavern 导出的书，就可以开始阅读。';
  static const String emptyImportAction = '导入书籍';

  static const String loadFailedTitle = '书架加载失败';
  static const String loadFailedMessage = '暂时读不到已导入的书籍，请重试。';
  static const String retryAction = '重试';

  static const String importAction = '导入';
  static const String importInProgress = '正在导入…';
  static const String importFailed = '导入失败，请重试。';

  static const String bookMenuTooltip = '更多操作';
  static const String deleteAction = '删除';
  static const String cancelAction = '取消';
  static const String deleteConfirmationTitle = '删除书籍';

  static String chapterCount(int chapterCount) => '共 $chapterCount 章';

  static String importSucceeded(String bookTitle) => '已导入《$bookTitle》';

  static String deleteConfirmationMessage(String bookTitle) =>
      '确定删除《$bookTitle》吗？删除后需要重新导入才能再次阅读。';

  static String deleteSucceeded(String bookTitle) => '已删除《$bookTitle》';

  static String deleteFailed(String bookTitle) => '删除《$bookTitle》失败，请重试。';
}

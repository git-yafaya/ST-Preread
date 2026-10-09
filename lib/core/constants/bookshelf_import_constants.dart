/// 书架导入入口用到的常量。
abstract final class BookshelfImportConstants {
  /// 导入时传给书库的占位来源路径。
  ///
  /// 目前还没有文件选取：书库用的是内存假实现，它会忽略这个参数并追加一本示例书，
  /// 所以这里只需要一个能说明自身用途的固定值。
  /// 接入真实的文件选取后，应改为传入用户所选内容在本地的路径，并删除本常量。
  static const String placeholderSourcePath = 'placeholder-import-source';
}

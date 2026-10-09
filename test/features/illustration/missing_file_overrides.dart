import 'dart:io';

/// 让 `File(path)` 一律得到「不存在的文件」，并且立刻以异步错误的形式报出来。
///
/// 真实的文件读取要等系统线程返回，widget 测试的虚拟时钟推不动它；
/// 换成这个之后，「文件不存在」这条路径不需要任何真实等待。
final class MissingFileOverrides extends IOOverrides {
  @override
  File createFile(String path) => _MissingFile(path);
}

class _MissingFile implements File {
  _MissingFile(this.path);

  static const int _noSuchFileErrorCode = 2;

  @override
  final String path;

  @override
  Future<int> length() {
    return Future<int>.error(
      PathNotFoundException(
        path,
        const OSError('No such file or directory', _noSuchFileErrorCode),
      ),
    );
  }

  /// 图片加载只会问文件长度；其余成员用不到，被调用就说明假设不成立，直接报错。
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

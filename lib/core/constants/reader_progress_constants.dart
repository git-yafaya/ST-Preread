/// 阅读进度保存的时间参数。
abstract final class ReaderProgressConstants {
  /// 滚动时锚点变化很频繁，进度最多每隔这么久保存一次；
  /// 离开页面与换章时会立即保存，不受这个间隔限制。
  static const Duration saveInterval = Duration(seconds: 1);
}

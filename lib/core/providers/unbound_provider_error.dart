/// 读取了尚未绑定实现的 provider。
///
/// 这里的 provider 只负责声明，具体实现由应用外壳（或测试）通过
/// ProviderScope overrides 绑定；漏绑属于程序缺陷，所以用 Error 而不是 Exception，
/// 同时也避免被 Riverpod 当作可恢复的失败而自动重试。
class UnboundProviderError extends Error {
  UnboundProviderError(this.providerName);

  final String providerName;

  @override
  String toString() =>
      'UnboundProviderError: $providerName 尚未绑定实现，'
      '请在 ProviderScope 的 overrides 中提供。';
}

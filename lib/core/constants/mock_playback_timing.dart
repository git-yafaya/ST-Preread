/// 假播放器的计时参数（阶段 1 专用；接入真实音频后随假实现一起删除）。
abstract final class MockPlaybackTiming {
  /// 按句子字符数推算时长时，每个字符折算的时间。
  static const Duration durationPerCharacter = Duration(milliseconds: 150);

  /// 播放位置的刷新间隔。
  static const Duration tickInterval = Duration(milliseconds: 100);
}

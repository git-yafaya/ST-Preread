/// 假播放器与示例语音的计时参数。只属于假实现，接入真实音频后随它一起删除。
abstract final class MockPlaybackTiming {
  /// 示例语音按句子字符数推算时长时，每个字符折算的时间。
  static const Duration durationPerCharacter = Duration(milliseconds: 150);

  /// 播放位置的刷新间隔。
  static const Duration tickInterval = Duration(milliseconds: 100);

  /// 语音片段没有给出结束位置（表示播到文件结尾）时使用的时长：
  /// 假播放器不读文件，无从得知真实长度。
  static const Duration fallbackClipDuration = Duration(seconds: 3);
}

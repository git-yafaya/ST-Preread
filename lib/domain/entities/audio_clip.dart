import 'nullable_value_getter.dart';

/// 一段语音。
///
/// 用「文件 + 可选区间」表示，同时兼容「一句一个文件」
/// 和「一段 / 一楼一个文件、按时间线切分」两种导出方式。
/// [start] / [end] 相对所引用的文件；有值时必须非负且 start < end。
class AudioClip {
  const AudioClip({
    required this.filePath,
    required this.start,
    required this.end,
  });

  final String filePath;

  /// 为 null 表示从文件开头。
  final Duration? start;

  /// 为 null 表示到文件结尾。
  final Duration? end;

  AudioClip copyWith({
    String? filePath,
    NullableValueGetter<Duration>? start,
    NullableValueGetter<Duration>? end,
  }) {
    return AudioClip(
      filePath: filePath ?? this.filePath,
      start: start == null ? this.start : start(),
      end: end == null ? this.end : end(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AudioClip &&
        other.filePath == filePath &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(filePath, start, end);

  @override
  String toString() =>
      'AudioClip(filePath: $filePath, start: $start, end: $end)';
}

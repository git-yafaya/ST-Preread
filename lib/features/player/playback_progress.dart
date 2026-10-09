/// 播放进度的换算与显示格式。
library;

const int _percentScale = 100;
const int _secondsDigits = 2;

/// 已播比例，范围 0 ~ 1；时长未知或不是正数时无法算出比例，返回 null。
double? playbackProgressFraction({
  required Duration position,
  required Duration? duration,
}) {
  if (duration == null || duration <= Duration.zero) {
    return null;
  }
  final fraction = position.inMicroseconds / duration.inMicroseconds;
  // 播放器上报的位置可能略微超出时长（如解码器的尾部填充），进度条不能越界。
  return fraction.clamp(0.0, 1.0).toDouble();
}

/// 把比例显示成整数百分比，如 `42%`。
String formatProgressPercent(double fraction) {
  return '${(fraction * _percentScale).round()}%';
}

/// 把时长显示成 `分:秒`，如 `0:07`、`1:05`。一句语音不会长到需要显示小时。
String formatPlaybackTime(Duration time) {
  final nonNegativeTime = time.isNegative ? Duration.zero : time;
  final minutes = nonNegativeTime.inMinutes;
  final seconds = nonNegativeTime.inSeconds % Duration.secondsPerMinute;
  return '$minutes:${seconds.toString().padLeft(_secondsDigits, '0')}';
}

/// 播放条上的时间文字：时长已知时为 `已播 / 总长`，未知时只有已播时间。
String formatPlaybackTimeLabel({
  required Duration position,
  required Duration? duration,
  required String separator,
}) {
  final positionText = formatPlaybackTime(position);
  if (duration == null) {
    return positionText;
  }
  return '$positionText$separator${formatPlaybackTime(duration)}';
}

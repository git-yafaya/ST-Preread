import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/mock_playback_timing.dart';

void main() {
  test('计时参数都为正，且一个字符的时长不短于刷新间隔', () {
    expect(MockPlaybackTiming.tickInterval, greaterThan(Duration.zero));
    expect(MockPlaybackTiming.fallbackClipDuration, greaterThan(Duration.zero));
    expect(
      MockPlaybackTiming.durationPerCharacter,
      greaterThanOrEqualTo(MockPlaybackTiming.tickInterval),
    );
  });
}

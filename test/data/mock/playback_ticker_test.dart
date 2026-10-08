import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/playback_ticker.dart';

void main() {
  const interval = Duration(milliseconds: 100);

  // 用 testWidgets 是为了借用它的虚拟时钟：pump 推进的是假时间，不做真实等待。
  group('TimerPlaybackTicker', () {
    testWidgets('按间隔周期性回调，停止后不再回调', (tester) async {
      final ticker = TimerPlaybackTicker();
      var tickCount = 0;

      ticker.start(interval, () => tickCount++);
      await tester.pump(interval * 3);
      expect(tickCount, 3);

      ticker.stop();
      await tester.pump(interval * 3);
      expect(tickCount, 3);
    });

    testWidgets('再次 start 会取代上一轮计时', (tester) async {
      final ticker = TimerPlaybackTicker();
      var firstRoundTicks = 0;
      var secondRoundTicks = 0;

      ticker.start(interval, () => firstRoundTicks++);
      ticker.start(interval, () => secondRoundTicks++);
      await tester.pump(interval * 2);
      ticker.stop();

      expect(firstRoundTicks, 0);
      expect(secondRoundTicks, 2);
    });
  });
}

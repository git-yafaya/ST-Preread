import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/features/player/playback_progress.dart';

void main() {
  group('playbackProgressFraction', () {
    test('按已播时间与时长算出比例', () {
      final fraction = playbackProgressFraction(
        position: const Duration(seconds: 1),
        duration: const Duration(seconds: 4),
      );

      expect(fraction, 0.25);
    });

    test('时长未知时没有比例', () {
      final fraction = playbackProgressFraction(
        position: const Duration(seconds: 1),
        duration: null,
      );

      expect(fraction, isNull);
    });

    test('时长为零时没有比例，不会除以零', () {
      final fraction = playbackProgressFraction(
        position: Duration.zero,
        duration: Duration.zero,
      );

      expect(fraction, isNull);
    });

    test('位置超出时长时封顶为 1', () {
      final fraction = playbackProgressFraction(
        position: const Duration(seconds: 5),
        duration: const Duration(seconds: 4),
      );

      expect(fraction, 1.0);
    });

    test('位置为负时封底为 0', () {
      final fraction = playbackProgressFraction(
        position: const Duration(seconds: -1),
        duration: const Duration(seconds: 4),
      );

      expect(fraction, 0.0);
    });
  });

  group('formatProgressPercent', () {
    test('四舍五入成整数百分比', () {
      expect(formatProgressPercent(0), '0%');
      expect(formatProgressPercent(0.254), '25%');
      expect(formatProgressPercent(0.256), '26%');
      expect(formatProgressPercent(1), '100%');
    });
  });

  group('formatPlaybackTime', () {
    test('秒数不足两位时补零', () {
      expect(formatPlaybackTime(const Duration(seconds: 7)), '0:07');
    });

    test('超过一分钟时进位到分钟', () {
      expect(formatPlaybackTime(const Duration(seconds: 65)), '1:05');
    });

    test('不足一秒的部分舍去', () {
      expect(formatPlaybackTime(const Duration(milliseconds: 1999)), '0:01');
    });

    test('负数按零显示', () {
      expect(formatPlaybackTime(const Duration(seconds: -3)), '0:00');
    });
  });

  group('formatPlaybackTimeLabel', () {
    test('时长已知时显示已播时间与总时长', () {
      final label = formatPlaybackTimeLabel(
        position: const Duration(seconds: 3),
        duration: const Duration(seconds: 12),
        separator: ' / ',
      );

      expect(label, '0:03 / 0:12');
    });

    test('时长未知时只显示已播时间', () {
      final label = formatPlaybackTimeLabel(
        position: const Duration(seconds: 3),
        duration: null,
        separator: ' / ',
      );

      expect(label, '0:03');
    });
  });
}

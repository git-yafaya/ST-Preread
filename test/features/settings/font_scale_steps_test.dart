import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_limits.dart';
import 'package:st_preread/features/settings/font_scale_steps.dart';

void main() {
  const minFontScale = ReaderSettingLimits.minFontScale;
  const maxFontScale = ReaderSettingLimits.maxFontScale;
  const fontScaleStep = ReaderSettingLimits.fontScaleStep;

  group('snapFontScale', () {
    test('已在刻度上的值保持不变', () {
      expect(snapFontScale(minFontScale), minFontScale);
      expect(snapFontScale(maxFontScale), maxFontScale);
      expect(
        snapFontScale(ReaderSettingLimits.defaultFontScale),
        ReaderSettingLimits.defaultFontScale,
      );
    });

    test('不在刻度上的值收敛到最近的一格', () {
      final slightlyAboveStep = minFontScale + fontScaleStep * 1.2;
      final slightlyBelowStep = minFontScale + fontScaleStep * 1.8;

      expect(
        snapFontScale(slightlyAboveStep),
        closeTo(minFontScale + fontScaleStep, 1e-9),
      );
      expect(
        snapFontScale(slightlyBelowStep),
        closeTo(minFontScale + fontScaleStep * 2, 1e-9),
      );
    });

    test('消除浮点累加带来的尾数', () {
      // 1.1 + 0.1 在浮点下是 1.2000000000000002，而不是 1.2。
      const accumulatedFontScale = 1.1 + 0.1;

      expect(accumulatedFontScale, isNot(1.2));
      expect(snapFontScale(accumulatedFontScale), 1.2);
    });

    test('超出范围的值收敛到上下限', () {
      expect(snapFontScale(maxFontScale + 3), maxFontScale);
      expect(snapFontScale(minFontScale - 3), minFontScale);
    });
  });

  group('increaseFontScale 与 decreaseFontScale', () {
    test('各自移动一格', () {
      const startFontScale = ReaderSettingLimits.defaultFontScale;

      expect(
        increaseFontScale(startFontScale),
        closeTo(startFontScale + fontScaleStep, 1e-9),
      );
      expect(
        decreaseFontScale(startFontScale),
        closeTo(startFontScale - fontScaleStep, 1e-9),
      );
    });

    test('到达上下限后不再越过', () {
      expect(increaseFontScale(maxFontScale), maxFontScale);
      expect(decreaseFontScale(minFontScale), minFontScale);
    });

    test('从下限逐格增大，恰好走完所有分格到达上限', () {
      var fontScale = minFontScale;
      var stepCount = 0;
      while (canIncreaseFontScale(fontScale)) {
        fontScale = increaseFontScale(fontScale);
        stepCount++;
      }

      expect(fontScale, maxFontScale);
      expect(stepCount, fontScaleDivisions());
    });

    test('增大再减小回到原值，不留浮点误差', () {
      const startFontScale = ReaderSettingLimits.defaultFontScale;

      final roundTrip = decreaseFontScale(increaseFontScale(startFontScale));

      expect(roundTrip, startFontScale);
    });
  });

  group('canIncreaseFontScale 与 canDecreaseFontScale', () {
    test('在范围中间时两个方向都可以', () {
      const middleFontScale = ReaderSettingLimits.defaultFontScale;

      expect(canIncreaseFontScale(middleFontScale), isTrue);
      expect(canDecreaseFontScale(middleFontScale), isTrue);
    });

    test('在上限时不能再增大，在下限时不能再减小', () {
      expect(canIncreaseFontScale(maxFontScale), isFalse);
      expect(canDecreaseFontScale(maxFontScale), isTrue);
      expect(canDecreaseFontScale(minFontScale), isFalse);
      expect(canIncreaseFontScale(minFontScale), isTrue);
    });
  });

  group('fontScaleDivisions', () {
    test('相邻两格相差一个步长', () {
      final spanCoveredByDivisions = fontScaleDivisions() * fontScaleStep;

      expect(
        spanCoveredByDivisions,
        closeTo(maxFontScale - minFontScale, 1e-9),
      );
    });
  });

  group('formatFontScale', () {
    test('显示为整数百分比', () {
      expect(formatFontScale(1.0), '100%');
      expect(formatFontScale(0.8), '80%');
      expect(formatFontScale(1.3), '130%');
    });
  });
}

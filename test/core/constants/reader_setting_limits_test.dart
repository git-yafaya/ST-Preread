import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_limits.dart';

void main() {
  test('默认字号落在允许范围内，且范围与步长有效', () {
    expect(
      ReaderSettingLimits.minFontScale,
      lessThan(ReaderSettingLimits.maxFontScale),
    );
    expect(
      ReaderSettingLimits.defaultFontScale,
      inInclusiveRange(
        ReaderSettingLimits.minFontScale,
        ReaderSettingLimits.maxFontScale,
      ),
    );
    expect(ReaderSettingLimits.fontScaleStep, greaterThan(0));
  });
}

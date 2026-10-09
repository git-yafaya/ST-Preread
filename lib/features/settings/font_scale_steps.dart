/// 字号倍数在取值范围内按步长增减的规则与显示格式。
library;

import '../../core/constants/reader_setting_limits.dart';

const int _percentScale = 100;

/// 把任意倍数收敛到取值范围内、且落在步长刻度上的值。
///
/// 0.1 这样的步长无法用二进制浮点精确表示，逐步累加会得到 1.2000000000000002
/// 之类的值；统一换算成「第几格」再除回去，保存下来的才是干净、可比较的数。
double snapFontScale(double rawFontScale) {
  final stepsPerUnit = (1 / ReaderSettingLimits.fontScaleStep).round();
  final snappedFontScale = (rawFontScale * stepsPerUnit).round() / stepsPerUnit;
  return snappedFontScale
      .clamp(ReaderSettingLimits.minFontScale, ReaderSettingLimits.maxFontScale)
      .toDouble();
}

/// 增大一格；已到上限时原样返回上限。
double increaseFontScale(double fontScale) {
  return snapFontScale(fontScale + ReaderSettingLimits.fontScaleStep);
}

/// 减小一格；已到下限时原样返回下限。
double decreaseFontScale(double fontScale) {
  return snapFontScale(fontScale - ReaderSettingLimits.fontScaleStep);
}

bool canIncreaseFontScale(double fontScale) {
  return snapFontScale(fontScale) < ReaderSettingLimits.maxFontScale;
}

bool canDecreaseFontScale(double fontScale) {
  return snapFontScale(fontScale) > ReaderSettingLimits.minFontScale;
}

/// 滑块的分格数：相邻两格正好相差一个步长。
int fontScaleDivisions() {
  final range =
      ReaderSettingLimits.maxFontScale - ReaderSettingLimits.minFontScale;
  return (range / ReaderSettingLimits.fontScaleStep).round();
}

/// 把倍数显示成百分比，如 `120%`：比「1.2 倍」更接近用户对字号大小的直觉。
String formatFontScale(double fontScale) {
  return '${(fontScale * _percentScale).round()}%';
}

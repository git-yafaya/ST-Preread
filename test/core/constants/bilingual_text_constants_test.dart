import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/bilingual_text_constants.dart';

void main() {
  test('辅文比主文小，但不至于小到看不清', () {
    expect(BilingualTextConstants.secondaryTextFontScale, lessThan(1));
    expect(BilingualTextConstants.secondaryTextFontScale, greaterThan(0.5));
  });
}

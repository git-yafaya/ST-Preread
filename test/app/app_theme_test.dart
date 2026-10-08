import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/app/app_theme.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  group('buildAppTheme', () {
    test('使用 Material 3，明暗与传入的一致', () {
      for (final brightness in Brightness.values) {
        final theme = buildAppTheme(brightness);
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme.brightness, brightness);
      }
    });
  });

  group('toMaterialThemeMode', () {
    test('三种阅读主题一一对应到框架的主题模式', () {
      expect(toMaterialThemeMode(ReaderThemeMode.system), ThemeMode.system);
      expect(toMaterialThemeMode(ReaderThemeMode.light), ThemeMode.light);
      expect(toMaterialThemeMode(ReaderThemeMode.dark), ThemeMode.dark);
    });
  });
}

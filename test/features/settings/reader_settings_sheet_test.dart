import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/constants/reader_setting_limits.dart';
import 'package:st_preread/core/constants/settings_strings.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/settings/reader_settings_sheet.dart';

import 'recording_reader_settings_repository.dart';

void main() {
  const openSheetButtonLabel = '打开设置';

  final increaseButton = find.byTooltip(
    SettingsStrings.increaseFontScaleTooltip,
  );
  final decreaseButton = find.byTooltip(
    SettingsStrings.decreaseFontScaleTooltip,
  );

  RecordingReaderSettingsRepository createRepository({
    ReaderSettings? initialSettings = defaultReaderSettings,
  }) {
    final repository = RecordingReaderSettingsRepository(
      initialSettings: initialSettings,
    );
    addTearDown(repository.dispose);
    return repository;
  }

  Widget wrapWithApp(
    RecordingReaderSettingsRepository repository,
    Widget home,
  ) {
    return ProviderScope(
      // 读取失败时 Riverpod 默认会定时重试；测试里关掉，
      // 否则用例结束时还挂着定时器，而且重试时机也不该由真实时间决定。
      retry: (retryCount, error) => null,
      overrides: [
        readerSettingsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: home),
    );
  }

  /// 直接把面板铺在页面里，便于断言；加载动画会一直转，所以只推进一帧。
  Future<void> pumpSheet(
    WidgetTester tester,
    RecordingReaderSettingsRepository repository,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(repository, const Scaffold(body: ReaderSettingsSheet())),
    );
    await tester.pump();
  }

  Set<OptionT> selectedOptions<OptionT>(WidgetTester tester) {
    return tester
        .widget<SegmentedButton<OptionT>>(find.byType(SegmentedButton<OptionT>))
        .selected;
  }

  /// 按 tooltip 找到的是提示组件本身，可用与否要看包着它的按钮。
  bool isEnabled(WidgetTester tester, Finder buttonTooltip) {
    final iconButton = tester.widget<IconButton>(
      find.ancestor(of: buttonTooltip, matching: find.byType(IconButton)),
    );
    return iconButton.onPressed != null;
  }

  group('显示当前设置', () {
    testWidgets('四项都反映仓库里的值', (tester) async {
      final repository = createRepository(
        initialSettings: const ReaderSettings(
          fontScale: 1.3,
          themeMode: ReaderThemeMode.dark,
          pageTurnMode: PageTurnMode.paged,
          displayMode: BilingualDisplayMode.sourceOnly,
        ),
      );

      await pumpSheet(tester, repository);

      expect(find.text('130%'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 1.3);
      expect(selectedOptions<ReaderThemeMode>(tester), {ReaderThemeMode.dark});
      expect(selectedOptions<PageTurnMode>(tester), {PageTurnMode.paged});
      expect(selectedOptions<BilingualDisplayMode>(tester), {
        BilingualDisplayMode.sourceOnly,
      });
    });

    testWidgets('列出全部选项与各项标题', (tester) async {
      await pumpSheet(tester, createRepository());

      for (final label in [
        SettingsStrings.sheetTitle,
        SettingsStrings.fontScaleTitle,
        SettingsStrings.themeModeTitle,
        SettingsStrings.themeModeSystem,
        SettingsStrings.themeModeLight,
        SettingsStrings.themeModeDark,
        SettingsStrings.pageTurnModeTitle,
        SettingsStrings.pageTurnModeScroll,
        SettingsStrings.pageTurnModePaged,
        SettingsStrings.displayModeTitle,
        SettingsStrings.displayModeBoth,
        SettingsStrings.displayModeTranslationOnly,
        SettingsStrings.displayModeSourceOnly,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('仓库里的设置被别处改掉后，面板跟着刷新', (tester) async {
      final repository = createRepository();
      await pumpSheet(tester, repository);

      repository.provideSettings(
        defaultReaderSettings.copyWith(themeMode: ReaderThemeMode.light),
      );
      await tester.pumpAndSettle();

      expect(selectedOptions<ReaderThemeMode>(tester), {ReaderThemeMode.light});
    });

    testWidgets('存下的字号超出范围时按上限显示，不抛异常', (tester) async {
      final repository = createRepository(
        initialSettings: defaultReaderSettings.copyWith(fontScale: 5),
      );

      await pumpSheet(tester, repository);

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Slider>(find.byType(Slider)).value,
        ReaderSettingLimits.maxFontScale,
      );
    });
  });

  group('修改后保存', () {
    testWidgets('选择深色主题，仓库收到只改了主题的新设置', (tester) async {
      final repository = createRepository();
      await pumpSheet(tester, repository);

      await tester.tap(find.text(SettingsStrings.themeModeDark));
      await tester.pumpAndSettle();

      expect(repository.savedSettings, [
        defaultReaderSettings.copyWith(themeMode: ReaderThemeMode.dark),
      ]);
      expect(selectedOptions<ReaderThemeMode>(tester), {ReaderThemeMode.dark});
    });

    testWidgets('选择翻页，仓库收到只改了翻阅方式的新设置', (tester) async {
      final repository = createRepository();
      await pumpSheet(tester, repository);

      await tester.tap(find.text(SettingsStrings.pageTurnModePaged));
      await tester.pumpAndSettle();

      expect(repository.savedSettings, [
        defaultReaderSettings.copyWith(pageTurnMode: PageTurnMode.paged),
      ]);
      expect(selectedOptions<PageTurnMode>(tester), {PageTurnMode.paged});
    });

    testWidgets('选择只看译文、再选只看原文，仓库依次收到两次新设置', (tester) async {
      final repository = createRepository();
      await pumpSheet(tester, repository);

      await tester.tap(find.text(SettingsStrings.displayModeTranslationOnly));
      await tester.pumpAndSettle();
      await tester.tap(find.text(SettingsStrings.displayModeSourceOnly));
      await tester.pumpAndSettle();

      expect(repository.savedSettings, [
        defaultReaderSettings.copyWith(
          displayMode: BilingualDisplayMode.translationOnly,
        ),
        defaultReaderSettings.copyWith(
          displayMode: BilingualDisplayMode.sourceOnly,
        ),
      ]);
    });

    testWidgets('连续修改不同的项，后一次保存保留前一次的改动', (tester) async {
      final repository = createRepository();
      await pumpSheet(tester, repository);

      await tester.tap(find.text(SettingsStrings.themeModeLight));
      await tester.pumpAndSettle();
      await tester.tap(find.text(SettingsStrings.pageTurnModePaged));
      await tester.pumpAndSettle();

      expect(
        repository.savedSettings.last,
        defaultReaderSettings.copyWith(
          themeMode: ReaderThemeMode.light,
          pageTurnMode: PageTurnMode.paged,
        ),
      );
    });
  });

  group('字号', () {
    testWidgets('点增大与减小按钮各移动一个步长并保存', (tester) async {
      final repository = createRepository(
        initialSettings: defaultReaderSettings.copyWith(fontScale: 1.0),
      );
      await pumpSheet(tester, repository);

      await tester.tap(increaseButton);
      await tester.pumpAndSettle();
      await tester.tap(decreaseButton);
      await tester.pumpAndSettle();
      await tester.tap(decreaseButton);
      await tester.pumpAndSettle();

      expect(repository.savedSettings.map((saved) => saved.fontScale), [
        1.1,
        1.0,
        0.9,
      ]);
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('已到上限时增大按钮不可用，点了也不保存', (tester) async {
      final repository = createRepository(
        initialSettings: defaultReaderSettings.copyWith(
          fontScale: ReaderSettingLimits.maxFontScale,
        ),
      );
      await pumpSheet(tester, repository);

      await tester.tap(increaseButton);
      await tester.pumpAndSettle();

      expect(isEnabled(tester, increaseButton), isFalse);
      expect(isEnabled(tester, decreaseButton), isTrue);
      expect(repository.savedSettings, isEmpty);
    });

    testWidgets('已到下限时减小按钮不可用，点了也不保存', (tester) async {
      final repository = createRepository(
        initialSettings: defaultReaderSettings.copyWith(
          fontScale: ReaderSettingLimits.minFontScale,
        ),
      );
      await pumpSheet(tester, repository);

      await tester.tap(decreaseButton);
      await tester.pumpAndSettle();

      expect(isEnabled(tester, decreaseButton), isFalse);
      expect(isEnabled(tester, increaseButton), isTrue);
      expect(repository.savedSettings, isEmpty);
    });

    testWidgets('从上限前一格增大到上限后，按钮随即变为不可用', (tester) async {
      final repository = createRepository(
        initialSettings: defaultReaderSettings.copyWith(
          fontScale:
              ReaderSettingLimits.maxFontScale -
              ReaderSettingLimits.fontScaleStep,
        ),
      );
      await pumpSheet(tester, repository);

      await tester.tap(increaseButton);
      await tester.pumpAndSettle();

      expect(
        repository.savedSettings.single.fontScale,
        ReaderSettingLimits.maxFontScale,
      );
      expect(isEnabled(tester, increaseButton), isFalse);
    });

    testWidgets('把滑块拖过右端，保存的字号停在上限', (tester) async {
      final repository = createRepository();
      await pumpSheet(tester, repository);
      final dragBeyondRightEnd = Offset(
        tester.getSize(find.byType(Slider)).width * 2,
        0,
      );

      await tester.drag(find.byType(Slider), dragBeyondRightEnd);
      await tester.pumpAndSettle();

      expect(
        repository.savedSettings.last.fontScale,
        ReaderSettingLimits.maxFontScale,
      );
      expect(
        repository.savedSettings.every(
          (saved) => saved.fontScale <= ReaderSettingLimits.maxFontScale,
        ),
        isTrue,
      );
    });

    testWidgets('把滑块拖过左端，保存的字号停在下限', (tester) async {
      final repository = createRepository();
      await pumpSheet(tester, repository);
      final dragBeyondLeftEnd = Offset(
        -tester.getSize(find.byType(Slider)).width * 2,
        0,
      );

      await tester.drag(find.byType(Slider), dragBeyondLeftEnd);
      await tester.pumpAndSettle();

      expect(
        repository.savedSettings.last.fontScale,
        ReaderSettingLimits.minFontScale,
      );
      expect(
        repository.savedSettings.every(
          (saved) => saved.fontScale >= ReaderSettingLimits.minFontScale,
        ),
        isTrue,
      );
    });

    testWidgets('修改字号不影响其他三项', (tester) async {
      const initialSettings = ReaderSettings(
        fontScale: 1.0,
        themeMode: ReaderThemeMode.dark,
        pageTurnMode: PageTurnMode.paged,
        displayMode: BilingualDisplayMode.translationOnly,
      );
      final repository = createRepository(initialSettings: initialSettings);
      await pumpSheet(tester, repository);

      await tester.tap(increaseButton);
      await tester.pumpAndSettle();

      expect(repository.savedSettings, [
        initialSettings.copyWith(fontScale: 1.1),
      ]);
    });
  });

  group('加载中与出错', () {
    testWidgets('还没读到设置时显示加载提示，不显示任何设置项', (tester) async {
      final repository = createRepository(initialSettings: null);

      await pumpSheet(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
      expect(find.text(SettingsStrings.themeModeTitle), findsNothing);
    });

    testWidgets('读到设置后加载提示换成设置项', (tester) async {
      final repository = createRepository(initialSettings: null);
      await pumpSheet(tester, repository);

      repository.provideSettings(defaultReaderSettings);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('读取失败时显示提示与重试按钮，不显示任何设置项', (tester) async {
      final repository = createRepository()..loadFailure = Exception('设置文件损坏');

      await pumpSheet(tester, repository);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(SettingsStrings.loadFailedMessage), findsOneWidget);
      expect(find.text(SettingsStrings.retryLoadButton), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('点重试后重新读取，成功则显示设置项', (tester) async {
      final repository = createRepository()..loadFailure = Exception('设置文件损坏');
      await pumpSheet(tester, repository);
      await tester.pumpAndSettle();

      repository.loadFailure = null;
      await tester.tap(find.text(SettingsStrings.retryLoadButton));
      await tester.pumpAndSettle();

      expect(find.text(SettingsStrings.loadFailedMessage), findsNothing);
      expect(find.byType(Slider), findsOneWidget);
    });
  });

  group('布局', () {
    testWidgets('小屏上不溢出，最后一项可以滚动到可见', (tester) async {
      const smallScreenSize = Size(320, 240);
      await tester.binding.setSurfaceSize(smallScreenSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpSheet(tester, createRepository());
      final lastOption = find.text(SettingsStrings.displayModeSourceOnly);
      await tester.scrollUntilVisible(
        lastOption,
        smallScreenSize.height / 2,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getBottomLeft(lastOption).dy,
        lessThanOrEqualTo(smallScreenSize.height),
      );
    });

    testWidgets('作为 bottom sheet 弹出时正常显示并可修改', (tester) async {
      final repository = createRepository();
      await tester.pumpWidget(
        wrapWithApp(
          repository,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => const ReaderSettingsSheet(),
                ),
                child: const Text(openSheetButtonLabel),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(openSheetButtonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(SettingsStrings.themeModeDark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repository.savedSettings.single.themeMode, ReaderThemeMode.dark);
    });
  });
}

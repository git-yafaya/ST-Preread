import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/settings_layout_constants.dart';
import '../../core/constants/settings_strings.dart';
import '../../core/providers/providers.dart';
import '../../domain/domain.dart';
import 'reader_settings_form.dart';
import 'reader_settings_status_view.dart';

/// 阅读设置面板的内容，由阅读页以 bottom sheet 形式弹出。
///
/// 显示的始终是仓库里的当前设置；每次改动立即保存，
/// 界面随仓库推送的新值刷新，所以面板自己不保留任何副本。
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      // 小屏或大字体下四项设置可能排不下，必须能滚动而不是溢出。
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: SettingsLayoutConstants.sheetHorizontalPadding,
          vertical: SettingsLayoutConstants.sheetVerticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetTitle(),
            const SizedBox(height: SettingsLayoutConstants.sectionSpacing),
            _buildBody(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(WidgetRef ref) {
    final asyncSettings = ref.watch(readerSettingsProvider);
    final settings = asyncSettings.value;
    // 只要拿到过设置就继续显示表单：之后流上偶发的错误不该把用户正在调的面板换掉。
    if (settings != null) {
      return ReaderSettingsForm(
        settings: settings,
        onSettingsChanged: (newSettings) => _saveSettings(ref, newSettings),
      );
    }
    if (asyncSettings.hasError && !asyncSettings.isLoading) {
      return ReaderSettingsLoadFailedView(
        onRetry: () => ref.invalidate(readerSettingsProvider),
      );
    }
    return const ReaderSettingsLoadingView();
  }

  void _saveSettings(WidgetRef ref, ReaderSettings newSettings) {
    ref.read(readerSettingsRepositoryProvider).saveSettings(newSettings);
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        SettingsStrings.sheetTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

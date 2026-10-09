import 'package:flutter/material.dart';

import '../../core/constants/settings_layout_constants.dart';
import '../../core/constants/settings_strings.dart';

/// 设置尚未读到时显示的加载提示。
class ReaderSettingsLoadingView extends StatelessWidget {
  const ReaderSettingsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: SettingsLayoutConstants.statusVerticalPadding,
      ),
      child: Center(
        child: CircularProgressIndicator(
          semanticsLabel: SettingsStrings.loadingSemanticsLabel,
        ),
      ),
    );
  }
}

/// 设置读取失败时显示的提示，附带重试入口。
class ReaderSettingsLoadFailedView extends StatelessWidget {
  const ReaderSettingsLoadFailedView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SettingsLayoutConstants.statusVerticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: SettingsLayoutConstants.titleToControlSpacing),
          const Text(
            SettingsStrings.loadFailedMessage,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SettingsLayoutConstants.titleToControlSpacing),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text(SettingsStrings.retryLoadButton),
          ),
        ],
      ),
    );
  }
}

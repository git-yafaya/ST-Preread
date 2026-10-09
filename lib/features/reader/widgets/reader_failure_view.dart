import 'package:flutter/material.dart';

import '../../../core/constants/reader_layout_constants.dart';
import '../../../core/constants/reader_strings.dart';
import '../logic/reader_state.dart';

/// 阅读页加载失败时的界面：说明原因，并提供重试。
class ReaderFailureView extends StatelessWidget {
  const ReaderFailureView({
    required this.reason,
    required this.onRetry,
    super.key,
  });

  final ReaderFailureReason reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          ReaderLayoutConstants.pageHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: ReaderLayoutConstants.failureIconSize,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: ReaderLayoutConstants.failureContentSpacing),
            Text(
              _messageOf(reason),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ReaderLayoutConstants.failureContentSpacing),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text(ReaderStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _messageOf(ReaderFailureReason reason) {
    return switch (reason) {
      ReaderFailureReason.bookNotFound => ReaderStrings.bookNotFound,
      ReaderFailureReason.chapterNotFound => ReaderStrings.chapterNotFound,
      ReaderFailureReason.emptyBook => ReaderStrings.emptyBook,
      ReaderFailureReason.unknown => ReaderStrings.loadFailed,
    };
  }
}

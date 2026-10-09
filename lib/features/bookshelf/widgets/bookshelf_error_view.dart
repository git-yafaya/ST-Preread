import 'package:flutter/material.dart';

import '../../../core/constants/bookshelf_strings.dart';
import 'bookshelf_status_view.dart';

/// 书架读取失败：说明出错并提供重试。
class BookshelfErrorView extends StatelessWidget {
  const BookshelfErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BookshelfStatusView(
      icon: Icons.error_outline,
      title: BookshelfStrings.loadFailedTitle,
      message: BookshelfStrings.loadFailedMessage,
      action: FilledButton.tonal(
        onPressed: onRetry,
        child: const Text(BookshelfStrings.retryAction),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/bookshelf_layout_constants.dart';

/// 书架没有书可展示时的整页说明：图标、标题、说明与一个操作。
///
/// 空书架与加载失败共用这一个版式，保证两种状态看起来一致。
class BookshelfStatusView extends StatelessWidget {
  const BookshelfStatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// 让用户走出当前状态的操作，如导入、重试。
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      // 小屏幕或放大字号时内容可能超出一屏，允许滚动而不是溢出。
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          BookshelfLayoutConstants.statusViewPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: BookshelfLayoutConstants.statusViewIconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: BookshelfLayoutConstants.statusViewSpacing),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(
              height: BookshelfLayoutConstants.statusViewMessageSpacing,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BookshelfLayoutConstants.statusViewSpacing),
            action,
          ],
        ),
      ),
    );
  }
}

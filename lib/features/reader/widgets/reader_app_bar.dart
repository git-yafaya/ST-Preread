import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/reader_strings.dart';
import '../../settings/reader_settings_sheet.dart';

/// 阅读页顶栏：返回、标题、目录入口、设置入口。
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderAppBar({
    required this.title,
    required this.isContentsAvailable,
    super.key,
  });

  final String title;

  /// 章节目录是否已经加载出来；没有时目录入口不可点。
  final bool isContentsAvailable;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // 页面带了抽屉后，顶栏默认会把返回键换成抽屉按钮；
      // 目录入口放在右侧，左侧明确留给返回。
      leading: IconButton(
        icon: const BackButtonIcon(),
        tooltip: ReaderStrings.backTooltip,
        onPressed: () => _leaveReader(context),
      ),
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.format_list_bulleted),
          tooltip: ReaderStrings.tableOfContents,
          onPressed: isContentsAvailable
              ? () => Scaffold.of(context).openDrawer()
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: ReaderStrings.settingsTooltip,
          onPressed: () => _showSettingsSheet(context),
        ),
      ],
    );
  }

  /// 阅读页若是被直接打开的（没有可以退回的上一页），返回键改为去书架，
  /// 不然用户会被困在阅读页里。
  void _leaveReader(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && !router.canPop()) {
      router.go(AppRoutes.bookshelf);
      return;
    }
    Navigator.maybePop(context);
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => const ReaderSettingsSheet(),
    );
  }
}

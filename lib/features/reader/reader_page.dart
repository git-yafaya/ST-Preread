import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/reader_strings.dart';
import '../player/player_bar.dart';
import 'logic/reader_controller.dart';
import 'logic/reader_state.dart';
import 'widgets/chapter_list_drawer.dart';
import 'widgets/reader_app_bar.dart';
import 'widgets/reader_chapter_body.dart';
import 'widgets/reader_failure_view.dart';

/// 阅读页：打开时恢复到上次读到的章节与位置，拼装正文视图、目录、设置入口与播放条。
class ReaderPage extends ConsumerWidget {
  const ReaderPage({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerControllerProvider(bookId));
    final controller = ref.read(readerControllerProvider(bookId).notifier);
    return Scaffold(
      appBar: ReaderAppBar(
        title: _titleOf(state),
        isContentsAvailable: state is ReaderReady,
      ),
      drawer: _buildContentsDrawer(state, controller),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildBody(state, controller)),
            const PlayerBar(),
          ],
        ),
      ),
    );
  }

  String _titleOf(ReaderState state) {
    return state is ReaderReady
        ? state.chapter.summary.title
        : ReaderStrings.defaultTitle;
  }

  Widget? _buildContentsDrawer(ReaderState state, ReaderController controller) {
    if (state is! ReaderReady) {
      return null;
    }
    return ChapterListDrawer(
      chapters: state.chapters,
      currentChapterIndex: state.currentChapterIndex,
      onChapterSelected: controller.openChapterFromContents,
    );
  }

  Widget _buildBody(ReaderState state, ReaderController controller) {
    return switch (state) {
      ReaderLoading() => const Center(child: CircularProgressIndicator()),
      ReaderFailure(:final reason) => ReaderFailureView(
        reason: reason,
        onRetry: controller.retry,
      ),
      ReaderReady() => ReaderChapterBody(bookId: bookId, readyState: state),
    };
  }
}

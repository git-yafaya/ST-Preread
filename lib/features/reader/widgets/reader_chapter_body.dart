import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/reader_setting_defaults.dart';
import '../../../core/constants/reader_strings.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/domain.dart';
import '../logic/reader_controller.dart';
import '../logic/reader_state.dart';
import '../paged/paged_chapter_view.dart';
import '../scroll/scroll_chapter_view.dart';

/// 阅读页的正文区：按翻阅方式选用滚动或翻页视图，并把视图的回调接到阅读页的编排上。
class ReaderChapterBody extends ConsumerWidget {
  const ReaderChapterBody({
    required this.bookId,
    required this.readyState,
    super.key,
  });

  final String bookId;
  final ReaderReady readyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 设置还没读到时先按默认值显示，读到后视图会按锚点保持位置。
    final settings =
        ref.watch(readerSettingsProvider).value ?? defaultReaderSettings;
    final activeSentence = ref.watch(
      playbackStateProvider.select((playback) => playback.value?.sentence),
    );
    final controller = ref.read(readerControllerProvider(bookId).notifier);
    final viewKey = ValueKey<int>(readyState.navigationSerial);
    final onPreviousChapterRequested = readyState.previousChapterIndex == null
        ? null
        : controller.goToPreviousChapter;
    final onNextChapterRequested = readyState.nextChapterIndex == null
        ? null
        : controller.goToNextChapter;
    void onSentenceTap(SentenceRef sentence) =>
        _toggleSentencePlayback(context, controller, sentence);

    return switch (settings.pageTurnMode) {
      PageTurnMode.scroll => ScrollChapterView(
        key: viewKey,
        chapter: readyState.chapter,
        displayMode: settings.displayMode,
        initialAnchor: readyState.initialAnchor,
        activeSentence: activeSentence,
        onAnchorChanged: controller.reportAnchor,
        onSentenceTap: onSentenceTap,
        onPreviousChapterRequested: onPreviousChapterRequested,
        onNextChapterRequested: onNextChapterRequested,
      ),
      PageTurnMode.paged => PagedChapterView(
        key: viewKey,
        chapter: readyState.chapter,
        displayMode: settings.displayMode,
        initialAnchor: readyState.initialAnchor,
        activeSentence: activeSentence,
        onAnchorChanged: controller.reportAnchor,
        onSentenceTap: onSentenceTap,
        onPreviousChapterRequested: onPreviousChapterRequested,
        onNextChapterRequested: onNextChapterRequested,
      ),
    };
  }

  Future<void> _toggleSentencePlayback(
    BuildContext context,
    ReaderController controller,
    SentenceRef sentence,
  ) async {
    // 播放是异步的，等它结束时这个 context 可能已经失效，所以先取出来。
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await controller.toggleSentencePlayback(sentence);
    if (outcome != SentenceTapOutcome.failed) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(ReaderStrings.playbackFailed)),
      );
  }
}

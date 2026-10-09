import '../../../domain/domain.dart';

/// 阅读页的状态。
sealed class ReaderState {
  const ReaderState();
}

/// 正在读取章节目录、阅读进度与章节内容。
final class ReaderLoading extends ReaderState {
  const ReaderLoading();
}

/// 打不开这本书或这一章的原因。
enum ReaderFailureReason { bookNotFound, chapterNotFound, emptyBook, unknown }

/// 加载失败，界面给出原因与重试入口。
final class ReaderFailure extends ReaderState {
  const ReaderFailure(this.reason);

  final ReaderFailureReason reason;
}

/// 一章已经加载好，可以阅读。
final class ReaderReady extends ReaderState {
  const ReaderReady({
    required this.chapters,
    required this.chapter,
    required this.initialAnchor,
    required this.navigationSerial,
  });

  /// 全书的章节目录，按阅读顺序排列。
  final List<ChapterSummary> chapters;

  /// 当前显示的章节。
  final Chapter chapter;

  /// 视图进入这一章时要定位到的锚点。只在「定位请求」发生时才变，
  /// 阅读过程中视图回报的锚点不会写回这里，否则视图会被自己回报的位置反复重新定位。
  final ReadingAnchor initialAnchor;

  /// 每发生一次定位请求（打开、目录跳转、换章、切换翻阅方式）就加一，用作视图的 key。
  /// 在章首再次从目录点当前章时，章节与锚点都没有变，只有靠它才能让视图重新定位。
  final int navigationSerial;

  int get currentChapterIndex => chapter.summary.index;

  /// 上一章的章节下标；当前是第一章时为 null。
  int? get previousChapterIndex {
    final position = _currentPosition;
    return position > 0 ? chapters[position - 1].index : null;
  }

  /// 下一章的章节下标；当前是最后一章时为 null。
  int? get nextChapterIndex {
    final position = _currentPosition;
    final hasNext = position >= 0 && position < chapters.length - 1;
    return hasNext ? chapters[position + 1].index : null;
  }

  /// 当前章在目录里的位置；目录里找不到时为 -1。
  int get _currentPosition {
    return chapters.indexWhere(
      (summary) => summary.index == currentChapterIndex,
    );
  }

  ReaderReady copyWith({ReadingAnchor? initialAnchor, int? navigationSerial}) {
    return ReaderReady(
      chapters: chapters,
      chapter: chapter,
      initialAnchor: initialAnchor ?? this.initialAnchor,
      navigationSerial: navigationSerial ?? this.navigationSerial,
    );
  }
}

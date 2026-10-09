import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/reader_layout_constants.dart';
import '../../../core/constants/reader_setting_limits.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/domain.dart';
import '../content/content.dart';
import 'chapter_boundary_entry.dart';
import 'scroll_anchor_locator.dart';

/// 决定文字怎样换行的全部输入。任何一项变了，同一个滚动距离对应的就不再是原来那一行。
typedef _LayoutInputs = ({
  BilingualDisplayMode displayMode,
  double fontScale,
  TextScaler textScaler,
  double width,
});

/// 滚动模式的章节视图：章内上下滚动，章首 / 章末有换章入口。
class ScrollChapterView extends ConsumerStatefulWidget {
  const ScrollChapterView({
    required this.chapter,
    required this.displayMode,
    required this.initialAnchor,
    required this.activeSentence,
    required this.onAnchorChanged,
    required this.onSentenceTap,
    required this.onPreviousChapterRequested,
    required this.onNextChapterRequested,
    super.key,
  });

  final Chapter chapter;
  final BilingualDisplayMode displayMode;

  /// 进入时定位到的锚点（进度恢复；目录跳转时为该章开头）。
  /// 它或 [chapter] 变化时视图会重新定位。
  final ReadingAnchor initialAnchor;

  /// 正在播放或暂停中的句子，用于高亮；没有则为 null。
  final SentenceRef? activeSentence;

  /// 当前阅读锚点变化时回调，阅读页据此保存进度。
  final ValueChanged<ReadingAnchor> onAnchorChanged;

  /// 点到一句带语音的句子时回调；点到无语音的句子或句间空隙不回调。
  final ValueChanged<SentenceRef> onSentenceTap;

  /// 用户在章首要求回上一章时回调；为 null 表示没有上一章，不显示入口。
  final VoidCallback? onPreviousChapterRequested;

  /// 用户在章末要求进下一章时回调；为 null 表示已是最后一章，改为显示提示文字。
  final VoidCallback? onNextChapterRequested;

  @override
  ConsumerState<ScrollChapterView> createState() => _ScrollChapterViewState();
}

class _ScrollChapterViewState extends ConsumerState<ScrollChapterView> {
  // 滚动距离换了字号就不再指向同一行，位置一律靠锚点恢复，不让框架按旧距离恢复。
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );

  late List<GlobalKey> _blockKeys;

  /// 视口顶部当前的锚点，也是最近一次回报给阅读页的锚点。
  late ReadingAnchor _currentAnchor;

  /// 等这一帧排版完成后要定位到的锚点；为 null 表示当前位置有效。
  ReadingAnchor? _pendingAnchor;

  _LayoutInputs? _layoutInputs;
  bool _isPositioningScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _startAt(widget.initialAnchor);
  }

  @override
  void didUpdateWidget(ScrollChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isChapterChanged =
        !identical(oldWidget.chapter, widget.chapter) &&
        oldWidget.chapter != widget.chapter;
    if (isChapterChanged || oldWidget.initialAnchor != widget.initialAnchor) {
      _startAt(widget.initialAnchor);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startAt(ReadingAnchor anchor) {
    _blockKeys = List.generate(
      widget.chapter.blocks.length,
      (_) => GlobalKey(),
    );
    _currentAnchor = anchor;
    _requestPositioning(anchor);
  }

  /// 行的位置要等排版完成才知道，所以定位放到这一帧结束之后。
  void _requestPositioning(ReadingAnchor anchor) {
    _pendingAnchor = anchor;
    if (_isPositioningScheduled) {
      return;
    }
    _isPositioningScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPositioningScheduled = false;
      if (mounted) {
        _applyPendingAnchor();
      }
    });
  }

  void _applyPendingAnchor() {
    final anchor = _pendingAnchor;
    if (anchor == null) {
      return;
    }
    final targetOffset = _createLocator()?.scrollOffsetOf(anchor);
    if (targetOffset != null && _scrollController.hasClients) {
      final position = _scrollController.position;
      // 章末锚点等情况下目标会超出可滚动范围，此时停在末尾。
      position.jumpTo(
        targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
    setState(() => _pendingAnchor = null);
    _reportVisibleAnchor();
  }

  void _handleScroll() {
    // 定位完成之前的滚动距离还是旧排版下的，不能据此回报锚点。
    if (_pendingAnchor == null) {
      _reportVisibleAnchor();
    }
  }

  /// 只在锚点真的换了一行时才回报，不随每一帧滚动重复发。
  void _reportVisibleAnchor() {
    if (!_scrollController.hasClients) {
      return;
    }
    final anchor = _createLocator()?.anchorAt(
      _scrollController.position.pixels,
    );
    if (anchor == null || anchor == _currentAnchor) {
      return;
    }
    _currentAnchor = anchor;
    widget.onAnchorChanged(anchor);
  }

  ScrollAnchorLocator? _createLocator() {
    final blockBoxes = <RenderBox>[];
    for (final blockKey in _blockKeys) {
      final renderObject = blockKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return null;
      }
      blockBoxes.add(renderObject);
    }
    return ScrollAnchorLocator(blockBoxes);
  }

  /// 换行位置变了之后，用变化前的锚点把阅读位置找回来。
  void _keepPositionAcrossRelayout(_LayoutInputs layoutInputs) {
    final previousInputs = _layoutInputs;
    _layoutInputs = layoutInputs;
    if (previousInputs == null || previousInputs == layoutInputs) {
      return;
    }
    _requestPositioning(_pendingAnchor ?? _currentAnchor);
  }

  @override
  Widget build(BuildContext context) {
    final fontScale =
        ref.watch(
          readerSettingsProvider.select(
            (settings) => settings.value?.fontScale,
          ),
        ) ??
        ReaderSettingLimits.defaultFontScale;
    final textTheme = ReaderTextTheme.fromTheme(
      Theme.of(context),
      fontScale: fontScale,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _keepPositionAcrossRelayout((
          displayMode: widget.displayMode,
          fontScale: fontScale,
          textScaler: textScaler,
          width: constraints.maxWidth,
        ));
        return _buildScrollView(textTheme);
      },
    );
  }

  Widget _buildScrollView(ReaderTextTheme textTheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: ReaderLayoutConstants.pageHorizontalPadding,
        vertical: ReaderLayoutConstants.pageVerticalPadding,
      ),
      // 定位要等排版之后，这一帧的滚动距离还不对；先不画出来，免得闪一下错误的位置。
      child: Opacity(
        opacity: _pendingAnchor == null ? 1 : 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildChapterContent(textTheme),
        ),
      ),
    );
  }

  List<Widget> _buildChapterContent(ReaderTextTheme textTheme) {
    final onPreviousChapterRequested = widget.onPreviousChapterRequested;
    return [
      if (onPreviousChapterRequested != null)
        PreviousChapterEntry(onRequested: onPreviousChapterRequested),
      for (final (blockIndex, block) in widget.chapter.blocks.indexed)
        _buildBlock(blockIndex, block, textTheme),
      NextChapterEntry(onRequested: widget.onNextChapterRequested),
    ];
  }

  /// 间距放在带 key 的子树之外：这样块的渲染范围就只是内容本身，
  /// 视口顶部落在块间距里时，不会被算成还在上一个块里。
  Widget _buildBlock(
    int blockIndex,
    ContentBlock block,
    ReaderTextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: ReaderLayoutConstants.blockSpacing,
      ),
      child: KeyedSubtree(
        key: _blockKeys[blockIndex],
        child: ContentBlockView(
          block: block,
          blockIndex: blockIndex,
          displayMode: widget.displayMode,
          textTheme: textTheme,
          activeSentence: widget.activeSentence,
          onSentenceTap: widget.onSentenceTap,
        ),
      ),
    );
  }
}

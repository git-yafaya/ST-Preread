import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../../core/constants/reader_layout_constants.dart';
import '../../../domain/domain.dart';
import '../content/content.dart';

/// getOffsetToReveal 的对齐参数：0 表示把目标的顶边对到视口的顶边。
const double _viewportTopAlignment = 0;

/// 在已排版的章节内容上，把阅读锚点与滚动距离互相换算。
///
/// 滚动距离会随字号、显示方式、屏幕宽度变化，锚点不会；
/// 所以进度只存锚点，每次排版后再用这里换算回滚动距离。
class ScrollAnchorLocator {
  /// [blockBoxes] 按块下标排列，每一项是对应块已完成排版的渲染对象，
  /// 且都在同一个滚动视口之内。
  const ScrollAnchorLocator(this.blockBoxes);

  final List<RenderBox> blockBoxes;

  /// 把 [anchor] 所在的那一行对到视口顶部所需的滚动距离（未按可滚动范围收紧）。
  ///
  /// 锚点没有指明哪一面、所指的面当前没有显示、或块下标已不在本章范围内时，
  /// 取块的开头。本章没有任何块时返回 null。
  double? scrollOffsetOf(ReadingAnchor anchor) {
    if (blockBoxes.isEmpty) {
      return null;
    }
    if (anchor.blockIndex >= blockBoxes.length) {
      return _scrollOffsetOfBlockStart(blockBoxes.last);
    }
    final blockBox = blockBoxes[anchor.blockIndex];
    final fragment = _findFragmentOfSide(blockBox, anchor.side);
    if (fragment == null) {
      return _scrollOffsetOfBlockStart(blockBox);
    }
    final lineTop =
        _scrollOffsetOfTop(fragment) + fragment.lineTopOf(anchor.textOffset);
    final isFirstLineOfBlock =
        lineTop - _scrollOffsetOfTop(blockBox) <
        ReaderLayoutConstants.anchorProbeTolerance;
    return isFirstLineOfBlock ? _scrollOffsetOfBlockStart(blockBox) : lineTop;
  }

  /// 定位到块的开头时在上方留一点空：章首不至于让第一行文字紧贴顶栏，
  /// 章首的「上一章」入口也正好收在视口之外。
  double _scrollOffsetOfBlockStart(RenderBox blockBox) {
    return _scrollOffsetOfTop(blockBox) -
        ReaderLayoutConstants.blockStartLeadingMargin;
  }

  /// 滚动距离为 [viewportTop] 时，视口顶部第一行可见内容的锚点。
  ///
  /// 滚动模式下一面文字是一整个片段，只取片段起点就退化成「段落开头」，
  /// 记不住长段落内部的位置；所以这里细到行：文字取那一行的行首偏移，
  /// 非文字块取块的开头。换章入口不是正文块，不会成为锚点。
  /// 视口顶部已经越过最后一个块时返回 null。
  ReadingAnchor? anchorAt(double viewportTop) {
    final probeOffset =
        viewportTop + ReaderLayoutConstants.anchorProbeTolerance;
    final blockIndex = _findFirstBlockEndingBelow(probeOffset);
    if (blockIndex == null) {
      return null;
    }
    final fragments = collectTextFragments(blockBoxes[blockIndex]);
    if (fragments.isEmpty) {
      return ReadingAnchor(blockIndex: blockIndex, side: null, textOffset: 0);
    }
    final fragment = _findFirstFragmentEndingBelow(fragments, probeOffset);
    final offsetInFragment = probeOffset - _scrollOffsetOfTop(fragment);
    return ReadingAnchor(
      blockIndex: blockIndex,
      side: fragment.side,
      textOffset: fragment.lineStartOffsetAt(math.max(0, offsetInFragment)),
    );
  }

  RenderTextFragment? _findFragmentOfSide(RenderBox blockBox, TextSide? side) {
    if (side == null) {
      return null;
    }
    for (final fragment in collectTextFragments(blockBox)) {
      if (fragment.side == side) {
        return fragment;
      }
    }
    return null;
  }

  /// 块自上而下排列，底边位置单调递增，可以二分。
  int? _findFirstBlockEndingBelow(double scrollOffset) {
    var low = 0;
    var high = blockBoxes.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (_scrollOffsetOfBottom(blockBoxes[middle]) > scrollOffset) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }
    return low < blockBoxes.length ? low : null;
  }

  /// 视口顶部落在主文与辅文之间的间隙里时，下一个片段就是第一个可见的片段。
  RenderTextFragment _findFirstFragmentEndingBelow(
    List<RenderTextFragment> fragments,
    double scrollOffset,
  ) {
    for (final fragment in fragments) {
      if (_scrollOffsetOfBottom(fragment) > scrollOffset) {
        return fragment;
      }
    }
    return fragments.last;
  }

  double _scrollOffsetOfBottom(RenderBox box) {
    return _scrollOffsetOfTop(box) + box.size.height;
  }

  /// [box] 顶边对到视口顶部时的滚动距离，与当前滚到哪里无关。
  double _scrollOffsetOfTop(RenderBox box) {
    return RenderAbstractViewport.of(box)
        .getOffsetToReveal(box, _viewportTopAlignment)
        .offset;
  }
}

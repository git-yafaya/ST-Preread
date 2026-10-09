import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/domain.dart';
import 'fragment_text_span.dart';
import 'reader_text_theme.dart';
import 'sentence_lookup.dart';
import 'side_highlight.dart';
import 'text_segment.dart';

/// 渲染段落某一面文字的一个字符区间 `[startOffset, endOffset)`。
///
/// 滚动模式一面文字就是一个片段；翻页模式会把一个段落拆到两页上，
/// 每页各渲染其中一个切片。偏移以 UTF-16 码元为单位，相对这一面的完整文字，
/// 切片的起止不得落在一个字素簇中间。
class TextFragmentView extends StatelessWidget {
  const TextFragmentView({
    required this.sidedText,
    required this.side,
    required this.textTheme,
    required this.paragraphStyle,
    required this.role,
    required this.highlight,
    required this.onSentenceTap,
    this.startOffset = 0,
    this.endOffset,
    super.key,
  });

  final SidedText sidedText;

  /// 这段文字属于段落的哪一面。
  final TextSide side;
  final ReaderTextTheme textTheme;
  final ParagraphStyle paragraphStyle;
  final TextRole role;
  final SideHighlight highlight;

  /// 点到一句带语音的句子时回调，参数是它在这一面句子列表里的下标
  /// （与片段从哪里切开无关）。为 null 时片段不响应点击。
  final ValueChanged<int>? onSentenceTap;

  /// 切片起点（含）。
  final int startOffset;

  /// 切片终点（不含）；null 表示到这一面文字的结尾。
  final int? endOffset;

  @override
  Widget build(BuildContext context) {
    final range = clampFragmentRange(
      textLength: sidedText.text.length,
      startOffset: startOffset,
      endOffset: endOffset,
    );
    return _TextFragmentLayout(
      side: side,
      startOffset: range.start,
      endOffset: range.end,
      sentences: sidedText.sentences,
      onSentenceTap: onSentenceTap,
      child: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: buildFragmentTextSpan(
          sidedText: sidedText,
          textTheme: textTheme,
          paragraphStyle: paragraphStyle,
          role: role,
          highlight: highlight,
          startOffset: range.start,
          endOffset: range.end,
        ),
      ),
    );
  }
}

class _TextFragmentLayout extends SingleChildRenderObjectWidget {
  const _TextFragmentLayout({
    required this.side,
    required this.startOffset,
    required this.endOffset,
    required this.sentences,
    required this.onSentenceTap,
    required super.child,
  });

  final TextSide side;
  final int startOffset;
  final int endOffset;
  final List<Sentence> sentences;
  final ValueChanged<int>? onSentenceTap;

  @override
  RenderTextFragment createRenderObject(BuildContext context) {
    return RenderTextFragment(
      side: side,
      startOffset: startOffset,
      endOffset: endOffset,
      sentences: sentences,
      onSentenceTap: onSentenceTap,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTextFragment renderObject,
  ) {
    renderObject
      ..side = side
      ..startOffset = startOffset
      ..endOffset = endOffset
      ..sentences = sentences
      ..onSentenceTap = onSentenceTap;
  }
}

/// 一个文字片段的渲染对象：在文本排版结果之上提供点句命中与行级定位。
///
/// 用文本布局来判断点到了哪一句，而不是给每个句子包一层手势 Widget——
/// 句子是行内的一段，包成独立 Widget 会破坏换行。
/// 视图通过 [collectTextFragments] 取到它，用来在片段内按偏移定位、按位置反查偏移。
class RenderTextFragment extends RenderProxyBox {
  RenderTextFragment({
    required this.side,
    required this.startOffset,
    required this.endOffset,
    required this.sentences,
    required this.onSentenceTap,
  }) {
    _tapRecognizer = TapGestureRecognizer(debugOwner: this)
      ..onTapUp = _handleTapUp;
  }

  /// 这段文字属于段落的哪一面。
  TextSide side;

  /// 切片在这一面完整文字里的起点（含）。
  int startOffset;

  /// 切片在这一面完整文字里的终点（不含）。
  int endOffset;

  /// 这一面的全部句子（不只是切片内的）。
  List<Sentence> sentences;

  ValueChanged<int>? onSentenceTap;

  late final TapGestureRecognizer _tapRecognizer;

  RenderParagraph get _paragraph => child! as RenderParagraph;

  int get _fragmentLength => endOffset - startOffset;

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }

  /// 点不到带语音的句子时让出命中，外层的手势（例如翻页模式的点击翻页）才收得到这次点击。
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (onSentenceTap == null || !size.contains(position)) {
      return false;
    }
    if (playableSentenceIndexAt(position) == null) {
      return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tapRecognizer.addPointer(event);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final sentenceIndex = playableSentenceIndexAt(details.localPosition);
    if (sentenceIndex != null) {
      onSentenceTap?.call(sentenceIndex);
    }
  }

  /// 片段内的位置 [position] 点到了哪一句带语音的句子（这一面句子列表里的下标）；
  /// 点在句间空隙、无语音的句子或文字之外的留白上返回 null。
  int? playableSentenceIndexAt(Offset position) {
    final textPosition = _paragraph.getPositionForOffset(position);
    for (final offsetInFragment in candidateCodeUnitOffsets(textPosition)) {
      final sentenceIndex = findPlayableSentenceIndexInFragment(
        sentences: sentences,
        fragmentStartOffset: startOffset,
        fragmentEndOffset: endOffset,
        offsetInFragment: offsetInFragment,
      );
      if (sentenceIndex != null && _isOnSentence(sentenceIndex, position)) {
        return sentenceIndex;
      }
    }
    return null;
  }

  /// 文本布局对任何位置都会给出「最近的字符」，点在行尾右侧的留白也不例外；
  /// 所以还要确认这个位置确实落在这一句占据的行内区域里。
  bool _isOnSentence(int sentenceIndex, Offset position) {
    final sentence = sentences[sentenceIndex];
    final boxes = _paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: math.max(sentence.startOffset, startOffset) - startOffset,
        extentOffset: math.min(sentence.endOffset, endOffset) - startOffset,
      ),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    return boxes.any((box) => box.toRect().contains(position));
  }

  /// 偏移 [textOffset]（相对这一面的完整文字）所在那一行的行顶，相对本片段顶部。
  ///
  /// 偏移不在本片段内时取最近的一端。
  double lineTopOf(int textOffset) {
    if (_fragmentLength == 0) {
      return 0;
    }
    final offsetInFragment = (textOffset - startOffset).clamp(
      0,
      _fragmentLength - 1,
    );
    final characterRange = _characterRangeAt(offsetInFragment);
    final boxes = _paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: characterRange.start,
        extentOffset: characterRange.end,
      ),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    if (boxes.isNotEmpty) {
      return boxes.first.top;
    }
    // 换行符等不占位的字符没有包围盒，退而取光标位置。
    return _paragraph
        .getOffsetForCaret(TextPosition(offset: offsetInFragment), Rect.zero)
        .dy;
  }

  /// 片段内偏移 [offsetInFragment] 所在的那个完整字符占据的码元区间。
  ///
  /// 偏移可能落在代理对（如 emoji）的任意一半上，而半个代理对量不出包围盒。
  TextRange _characterRangeAt(int offsetInFragment) {
    final isLowSurrogate = _hasSurrogateTag(offsetInFragment, _lowSurrogateTag);
    final start = isLowSurrogate && offsetInFragment > 0
        ? offsetInFragment - 1
        : offsetInFragment;
    final isPair = _hasSurrogateTag(start, _highSurrogateTag);
    return TextRange(start: start, end: start + (isPair ? 2 : 1));
  }

  bool _hasSurrogateTag(int offsetInFragment, int surrogateTag) {
    final codeUnit = _paragraph.text.codeUnitAt(offsetInFragment);
    return codeUnit != null && codeUnit & _surrogateTagMask == surrogateTag;
  }

  /// 纵坐标 [localY]（相对本片段顶部）所在那一行的行首偏移，相对这一面的完整文字。
  ///
  /// 纵坐标超出片段时取最近的一行。
  int lineStartOffsetAt(double localY) {
    if (_fragmentLength == 0) {
      return startOffset;
    }
    final lineStart = _paragraph.getPositionForOffset(Offset(0, localY));
    return startOffset + lineStart.offset.clamp(0, _fragmentLength - 1);
  }
}

/// UTF-16 代理对的前后两半分别以这两种高位开头，用掩码取出高位即可分辨。
const int _surrogateTagMask = 0xFC00;
const int _highSurrogateTag = 0xD800;
const int _lowSurrogateTag = 0xDC00;

/// 文本布局给出的光标位置对应的码元下标，按可能性从高到低排列。
///
/// 点在字形左半边时光标落在字形之前（下游亲和），点在右半边时落在字形之后（上游亲和）；
/// 所以被点的字符可能是光标之后的那个，也可能是之前的那个。
List<int> candidateCodeUnitOffsets(TextPosition position) {
  final following = position.offset;
  final preceding = position.offset - 1;
  return position.affinity == TextAffinity.upstream
      ? [preceding, following]
      : [following, preceding];
}

/// 按从上到下的显示顺序收集 [root] 之下的全部文字片段。
List<RenderTextFragment> collectTextFragments(RenderObject root) {
  final fragments = <RenderTextFragment>[];
  void visit(RenderObject renderObject) {
    if (renderObject is RenderTextFragment) {
      fragments.add(renderObject);
      return;
    }
    renderObject.visitChildren(visit);
  }

  visit(root);
  return fragments;
}

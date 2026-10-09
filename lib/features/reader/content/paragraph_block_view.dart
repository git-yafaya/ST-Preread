import 'package:flutter/widgets.dart';

import '../../../core/constants/reader_layout_constants.dart';
import '../../../domain/domain.dart';
import 'paragraph_frame.dart';
import 'reader_text_theme.dart';
import 'side_highlight.dart';
import 'text_fragment_view.dart';

/// 完整渲染一个段落：按显示方式排出主文与辅文，主文在上、辅文跟在下方。
class ParagraphBlockView extends StatelessWidget {
  const ParagraphBlockView({
    required this.paragraph,
    required this.blockIndex,
    required this.displayMode,
    required this.textTheme,
    required this.activeSentence,
    required this.onSentenceTap,
    super.key,
  });

  final ParagraphBlock paragraph;

  /// 这个段落在章内的块下标，用来拼出被点句子的定位、判断高亮是否落在本段。
  final int blockIndex;
  final BilingualDisplayMode displayMode;
  final ReaderTextTheme textTheme;

  /// 正在播放或暂停中的句子；没有则为 null。
  final SentenceRef? activeSentence;

  /// 点到一句带语音的句子时回调；为 null 时段落不响应点击。
  final ValueChanged<SentenceRef>? onSentenceTap;

  @override
  Widget build(BuildContext context) {
    final displayedSides = resolveDisplayedSides(paragraph, displayMode);
    return ParagraphFrame(
      paragraphStyle: paragraph.style,
      textTheme: textTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (position, side) in displayedSides.indexed)
            _buildSide(side, isPrimary: position == 0),
        ],
      ),
    );
  }

  Widget _buildSide(TextSide side, {required bool isPrimary}) {
    final fragment = TextFragmentView(
      // resolveDisplayedSides 只返回段落实际拥有的面。
      sidedText: paragraph.textOf(side)!,
      side: side,
      textTheme: textTheme,
      paragraphStyle: paragraph.style,
      role: isPrimary ? TextRole.primary : TextRole.secondary,
      highlight: resolveSideHighlight(
        activeSentence: activeSentence,
        blockIndex: blockIndex,
        side: side,
      ),
      onSentenceTap: _sentenceTapHandlerFor(side),
    );
    if (isPrimary) {
      return fragment;
    }
    return Padding(
      padding: const EdgeInsets.only(
        top: ReaderLayoutConstants.secondaryTextSpacing,
      ),
      child: fragment,
    );
  }

  ValueChanged<int>? _sentenceTapHandlerFor(TextSide side) {
    final onSentenceTap = this.onSentenceTap;
    if (onSentenceTap == null) {
      return null;
    }
    return (sentenceIndex) => onSentenceTap(
      SentenceRef(
        blockIndex: blockIndex,
        side: side,
        sentenceIndex: sentenceIndex,
      ),
    );
  }
}

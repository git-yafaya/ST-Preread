import 'package:flutter/widgets.dart';

import '../../../domain/domain.dart';
import '../../illustration/illustration_block_view.dart';
import 'divider_block_view.dart';
import 'paragraph_block_view.dart';
import 'reader_text_theme.dart';

/// 完整渲染章内的一个块：段落、分隔线或插图。不含块与块之间的间距。
class ContentBlockView extends StatelessWidget {
  const ContentBlockView({
    required this.block,
    required this.blockIndex,
    required this.displayMode,
    required this.textTheme,
    required this.activeSentence,
    required this.onSentenceTap,
    super.key,
  });

  final ContentBlock block;

  /// 这个块在章内的下标。
  final int blockIndex;
  final BilingualDisplayMode displayMode;
  final ReaderTextTheme textTheme;

  /// 正在播放或暂停中的句子；没有则为 null。
  final SentenceRef? activeSentence;

  /// 点到一句带语音的句子时回调；为 null 时不响应点击。
  final ValueChanged<SentenceRef>? onSentenceTap;

  @override
  Widget build(BuildContext context) {
    final block = this.block;
    return switch (block) {
      ParagraphBlock() => ParagraphBlockView(
        paragraph: block,
        blockIndex: blockIndex,
        displayMode: displayMode,
        textTheme: textTheme,
        activeSentence: activeSentence,
        onSentenceTap: onSentenceTap,
      ),
      DividerBlock() => const DividerBlockView(),
      IllustrationBlock() => IllustrationBlockView(block: block),
    };
  }
}

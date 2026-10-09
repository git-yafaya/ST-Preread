import '../../../domain/domain.dart';

/// 章首锚点：目录跳转、进下一章、新书首次打开都落在这里。
const ReadingAnchor chapterStartAnchor = ReadingAnchor(
  blockIndex: 0,
  side: null,
  textOffset: 0,
);

/// 章末锚点：回上一章时接着往回读，要落在那一章的末尾。
///
/// 取最后一个块；段落取屏幕上排在最后的那一面的最后一个字符，
/// 这样翻页模式落在最后一页，滚动模式停在章末。非文字块只能取块的开头。
/// 没有任何块的章节退回章首。
ReadingAnchor resolveChapterEndAnchor(
  Chapter chapter,
  BilingualDisplayMode displayMode,
) {
  if (chapter.blocks.isEmpty) {
    return chapterStartAnchor;
  }
  final lastBlockIndex = chapter.blocks.length - 1;
  final lastBlock = chapter.blocks[lastBlockIndex];
  if (lastBlock is! ParagraphBlock) {
    return ReadingAnchor(blockIndex: lastBlockIndex, side: null, textOffset: 0);
  }
  final lastDisplayedSide = resolveDisplayedSides(lastBlock, displayMode).last;
  // resolveDisplayedSides 只返回段落实际拥有的面。
  final textLength = lastBlock.textOf(lastDisplayedSide)!.text.length;
  return ReadingAnchor(
    blockIndex: lastBlockIndex,
    side: lastDisplayedSide,
    textOffset: textLength == 0 ? 0 : textLength - 1,
  );
}

/// 打开一本书时从哪里开始读：有进度就接着读，否则从第一章开头。
///
/// 进度里记的章节如果已经不在目录里（书被重新导入后章节变少），
/// 也从第一章开头读起，而不是停在一个打不开的章节上。
/// [chapters] 不能为空。
ReadingPosition resolveStartingPosition({
  required String bookId,
  required List<ChapterSummary> chapters,
  required ReadingPosition? savedPosition,
}) {
  final isSavedChapterAvailable =
      savedPosition != null &&
      chapters.any((summary) => summary.index == savedPosition.chapterIndex);
  if (isSavedChapterAvailable) {
    return savedPosition;
  }
  return ReadingPosition(
    bookId: bookId,
    chapterIndex: chapters.first.index,
    anchor: chapterStartAnchor,
  );
}

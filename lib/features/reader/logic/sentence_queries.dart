import '../../../domain/domain.dart';

/// 取 [sentence] 这一句的语音。
///
/// 句子定位由视图回传，正常情况下一定对得上；但定位只是几个下标，
/// 换章的瞬间可能还指向旧章，所以对不上时返回 null 而不是越界抛错。
AudioClip? findAudioClip(Chapter chapter, SentenceRef sentence) {
  final sidedText = _findSidedText(chapter, sentence);
  if (sidedText == null ||
      sentence.sentenceIndex < 0 ||
      sentence.sentenceIndex >= sidedText.sentences.length) {
    return null;
  }
  return sidedText.sentences[sentence.sentenceIndex].audio;
}

/// [sentence] 所在的那一面在 [displayMode] 下是否还显示在屏幕上。
///
/// 正在播放的句子所在的面被切掉后，高亮无处可画，播放也应随之停止。
bool isSentenceDisplayed({
  required Chapter chapter,
  required SentenceRef sentence,
  required BilingualDisplayMode displayMode,
}) {
  final paragraph = _findParagraph(chapter, sentence.blockIndex);
  if (paragraph == null) {
    return false;
  }
  return resolveDisplayedSides(paragraph, displayMode).contains(sentence.side);
}

SidedText? _findSidedText(Chapter chapter, SentenceRef sentence) {
  return _findParagraph(chapter, sentence.blockIndex)?.textOf(sentence.side);
}

ParagraphBlock? _findParagraph(Chapter chapter, int blockIndex) {
  if (blockIndex < 0 || blockIndex >= chapter.blocks.length) {
    return null;
  }
  final block = chapter.blocks[blockIndex];
  return block is ParagraphBlock ? block : null;
}

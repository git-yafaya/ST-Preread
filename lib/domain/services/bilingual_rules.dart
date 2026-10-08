import '../entities/chapter.dart';
import '../entities/content_block.dart';
import '../entities/reader_settings.dart';
import '../entities/sentence_ref.dart';
import '../entities/text_side.dart';

/// 显示回退规则：某个段落按 [displayMode] 应当显示哪几面，按显示顺序排列。
///
/// 所选的那一面在该段落里不存在时，改为显示它实际拥有的那一面，
/// 这样未翻译或只有译文的段落不会在正文里留下空白。
List<TextSide> resolveDisplayedSides(
  ParagraphBlock paragraph,
  BilingualDisplayMode displayMode,
) {
  final existingSides = TextSide.values
      .where((side) => paragraph.textOf(side) != null)
      .toList();
  final preferredSide = _singleDisplayedSide(displayMode);
  if (preferredSide == null || !existingSides.contains(preferredSide)) {
    return existingSides;
  }
  return [preferredSide];
}

/// 朗读面规则：本章按 [displayMode] 应当朗读哪一面；两面都没有语音时返回 null。
///
/// 按章而不是按段判断，是为了一章之内朗读的语言保持一致。
TextSide? selectNarrationSide(
  Chapter chapter,
  BilingualDisplayMode displayMode,
) {
  final preferredSide = _preferredNarrationSide(displayMode);
  final candidateSides = [preferredSide, _oppositeSide(preferredSide)];
  for (final side in candidateSides) {
    if (listPlayableSentences(chapter, side).isNotEmpty) {
      return side;
    }
  }
  return null;
}

/// 播放队列：本章 [side] 这一面所有带语音的句子，按阅读顺序排列。
List<SentenceRef> listPlayableSentences(Chapter chapter, TextSide side) {
  final playableSentences = <SentenceRef>[];
  for (var blockIndex = 0; blockIndex < chapter.blocks.length; blockIndex++) {
    playableSentences.addAll(
      _playableSentencesInBlock(chapter.blocks[blockIndex], blockIndex, side),
    );
  }
  return playableSentences;
}

/// 单面显示时返回要显示的那一面；对照显示时返回 null。
TextSide? _singleDisplayedSide(BilingualDisplayMode displayMode) {
  return switch (displayMode) {
    BilingualDisplayMode.sourceOnly => TextSide.source,
    BilingualDisplayMode.translationOnly => TextSide.translation,
    BilingualDisplayMode.both => null,
  };
}

/// 对照显示时优先译文，与镜译默认朗读译文的行为保持一致。
TextSide _preferredNarrationSide(BilingualDisplayMode displayMode) {
  return _singleDisplayedSide(displayMode) ?? TextSide.translation;
}

TextSide _oppositeSide(TextSide side) {
  return switch (side) {
    TextSide.source => TextSide.translation,
    TextSide.translation => TextSide.source,
  };
}

Iterable<SentenceRef> _playableSentencesInBlock(
  ContentBlock block,
  int blockIndex,
  TextSide side,
) sync* {
  if (block is! ParagraphBlock) {
    return;
  }
  final sentences = block.textOf(side)?.sentences ?? const [];
  for (var index = 0; index < sentences.length; index++) {
    if (sentences[index].hasAudio) {
      yield SentenceRef(
        blockIndex: blockIndex,
        side: side,
        sentenceIndex: index,
      );
    }
  }
}

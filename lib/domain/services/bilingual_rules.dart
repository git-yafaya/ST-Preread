import '../entities/content_block.dart';
import '../entities/reader_settings.dart';
import '../entities/text_side.dart';

/// 双语显示规则：某个段落按 [displayMode] 应当显示哪几面。
///
/// 返回值的第一项为主文，其后为辅文；只显示一面时它就是主文。
/// 所选的那一面在该段落里不存在时，改为显示它实际拥有的那一面，
/// 这样未翻译或只有译文的段落不会在正文里留下空白。
List<TextSide> resolveDisplayedSides(
  ParagraphBlock paragraph,
  BilingualDisplayMode displayMode,
) {
  final existingSides = _sidesByPriority(displayMode)
      .where((side) => paragraph.textOf(side) != null);
  return existingSides.take(_maxDisplayedSideCount(displayMode)).toList();
}

/// 各显示方式下两面的优先顺序：排在前面的优先成为主文，
/// 单面显示时排在后面的那一面只在首选面缺失时作为回退。
List<TextSide> _sidesByPriority(BilingualDisplayMode displayMode) {
  return switch (displayMode) {
    BilingualDisplayMode.both || BilingualDisplayMode.translationOnly => const [
      TextSide.translation,
      TextSide.source,
    ],
    BilingualDisplayMode.sourceOnly => const [
      TextSide.source,
      TextSide.translation,
    ],
  };
}

int _maxDisplayedSideCount(BilingualDisplayMode displayMode) {
  return switch (displayMode) {
    BilingualDisplayMode.both => TextSide.values.length,
    BilingualDisplayMode.translationOnly ||
    BilingualDisplayMode.sourceOnly => 1,
  };
}

import '../../../domain/domain.dart';

/// 段落某一面受到的播放高亮。
sealed class SideHighlight {
  const SideHighlight();
}

/// 这一面不受播放影响。
final class NoSideHighlight extends SideHighlight {
  const NoSideHighlight();

  @override
  bool operator ==(Object other) => other is NoSideHighlight;

  @override
  int get hashCode => (NoSideHighlight).hashCode;

  @override
  String toString() => 'NoSideHighlight()';
}

/// 被播的句子就在这一面：只高亮这一句。
final class ActiveSentenceHighlight extends SideHighlight {
  const ActiveSentenceHighlight(this.sentenceIndex);

  /// 被播句子在这一面句子列表里的下标。
  final int sentenceIndex;

  @override
  bool operator ==(Object other) {
    return other is ActiveSentenceHighlight &&
        other.sentenceIndex == sentenceIndex;
  }

  @override
  int get hashCode => Object.hash(ActiveSentenceHighlight, sentenceIndex);

  @override
  String toString() => 'ActiveSentenceHighlight(sentenceIndex: $sentenceIndex)';
}

/// 被播的句子在同一段的另一面：两面的句子没有一一对应关系，
/// 所以这一面只能整段以较淡的颜色高亮。
final class CompanionSideHighlight extends SideHighlight {
  const CompanionSideHighlight();

  @override
  bool operator ==(Object other) => other is CompanionSideHighlight;

  @override
  int get hashCode => (CompanionSideHighlight).hashCode;

  @override
  String toString() => 'CompanionSideHighlight()';
}

/// 第 [blockIndex] 个块的 [side] 这一面，在 [activeSentence] 正被播放（或暂停）时
/// 应当怎样高亮。
///
/// 只有对照显示时一个段落才会同时显示两面，
/// 所以「另一面」只要被渲染出来，就是需要整段淡色高亮的那一面。
SideHighlight resolveSideHighlight({
  required SentenceRef? activeSentence,
  required int blockIndex,
  required TextSide side,
}) {
  if (activeSentence == null || activeSentence.blockIndex != blockIndex) {
    return const NoSideHighlight();
  }
  if (activeSentence.side == side) {
    return ActiveSentenceHighlight(activeSentence.sentenceIndex);
  }
  return const CompanionSideHighlight();
}

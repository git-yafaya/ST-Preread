import 'chapter_summary.dart';
import 'content_block.dart';
import 'collection_equality.dart';

/// 一章的完整内容。
class Chapter {
  const Chapter({required this.summary, required this.blocks});

  final ChapterSummary summary;

  /// 按阅读顺序排列；块在此列表中的下标即阅读定位用的 blockIndex。
  final List<ContentBlock> blocks;

  Chapter copyWith({ChapterSummary? summary, List<ContentBlock>? blocks}) {
    return Chapter(
      summary: summary ?? this.summary,
      blocks: blocks ?? this.blocks,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Chapter &&
        other.summary == summary &&
        areListsEqual(other.blocks, blocks);
  }

  @override
  int get hashCode => Object.hash(summary, Object.hashAll(blocks));

  @override
  String toString() =>
      'Chapter(summary: $summary, blockCount: ${blocks.length})';
}

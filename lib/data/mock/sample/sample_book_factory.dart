import '../../../domain/domain.dart';
import 'sample_book_content.dart';
import 'sample_content_spec.dart';
import 'sample_text_builder.dart';

/// 示例资源的虚拟根目录。阶段 1 不涉及真实文件，这些路径下没有任何东西；
/// 插图会走「加载失败显示占位」的分支，语音由假播放器按句长模拟。
const String _sampleAssetRoot = 'sample';

/// 一本示例书：书架条目加上全部章节内容。
class SampleBook {
  const SampleBook({required this.book, required this.chapters});

  final Book book;
  final List<Chapter> chapters;
}

/// 构建第 [sequenceNumber] 本示例书（从 1 开始）。
///
/// 每本的 id 与标题都带上序号，这样多次导入后书架上的条目可以互相区分。
SampleBook buildSampleBook({
  required int sequenceNumber,
  required DateTime importedAt,
}) {
  final bookId = 'sample-book-$sequenceNumber';
  final chapters = [
    for (final (chapterIndex, chapterSpec) in sampleChapterSpecs.indexed)
      _buildChapter(bookId, chapterIndex, chapterSpec),
  ];
  final book = Book(
    id: bookId,
    title: _titleOf(sequenceNumber),
    author: sampleBookAuthor,
    coverImagePath: null,
    chapterCount: chapters.length,
    importedAt: importedAt,
  );
  return SampleBook(book: book, chapters: List<Chapter>.unmodifiable(chapters));
}

String _titleOf(int sequenceNumber) {
  const firstSequenceNumber = 1;
  if (sequenceNumber == firstSequenceNumber) {
    return sampleBookTitle;
  }
  return '$sampleBookTitle（$sequenceNumber）';
}

Chapter _buildChapter(
  String bookId,
  int chapterIndex,
  SampleChapterSpec chapterSpec,
) {
  final chapterKey = '$bookId/chapter-$chapterIndex';
  return Chapter(
    summary: ChapterSummary(
      bookId: bookId,
      index: chapterIndex,
      title: chapterSpec.title,
    ),
    blocks: List<ContentBlock>.unmodifiable([
      for (final (blockIndex, blockSpec) in chapterSpec.blocks.indexed)
        _buildBlock('$chapterKey/block-$blockIndex', blockSpec),
    ]),
  );
}

ContentBlock _buildBlock(String blockKey, SampleBlockSpec blockSpec) {
  return switch (blockSpec) {
    SampleParagraphSpec() => ParagraphBlock(
      id: blockKey,
      source: _buildSide(blockKey, TextSide.source, blockSpec.source),
      translation: _buildSide(
        blockKey,
        TextSide.translation,
        blockSpec.translation,
      ),
    ),
    SampleIllustrationSpec() => IllustrationBlock(
      id: blockKey,
      imagePath: '$_sampleAssetRoot/illustrations/${blockSpec.imageFileName}',
      caption: blockSpec.caption,
    ),
  };
}

SidedText? _buildSide(String blockKey, TextSide side, SampleSideSpec? spec) {
  if (spec == null) {
    return null;
  }
  return buildSidedText(
    spec: spec,
    side: side,
    audioFileStem: '$_sampleAssetRoot/audio/$blockKey-${side.name}',
  );
}

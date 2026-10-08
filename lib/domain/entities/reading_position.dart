/// 一本书读到的位置。
class ReadingPosition {
  const ReadingPosition({
    required this.bookId,
    required this.chapterIndex,
    required this.blockIndex,
  });

  final String bookId;
  final int chapterIndex;

  /// 章内块下标。
  final int blockIndex;

  ReadingPosition copyWith({
    String? bookId,
    int? chapterIndex,
    int? blockIndex,
  }) {
    return ReadingPosition(
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      blockIndex: blockIndex ?? this.blockIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingPosition &&
        other.bookId == bookId &&
        other.chapterIndex == chapterIndex &&
        other.blockIndex == blockIndex;
  }

  @override
  int get hashCode => Object.hash(bookId, chapterIndex, blockIndex);

  @override
  String toString() =>
      'ReadingPosition(bookId: $bookId, chapterIndex: $chapterIndex, '
      'blockIndex: $blockIndex)';
}

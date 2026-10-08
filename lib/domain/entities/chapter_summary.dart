/// 章节的目录信息，不含正文，供目录列表使用。
class ChapterSummary {
  const ChapterSummary({
    required this.bookId,
    required this.index,
    required this.title,
  });

  final String bookId;

  /// 从 0 开始。
  final int index;
  final String title;

  ChapterSummary copyWith({String? bookId, int? index, String? title}) {
    return ChapterSummary(
      bookId: bookId ?? this.bookId,
      index: index ?? this.index,
      title: title ?? this.title,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChapterSummary &&
        other.bookId == bookId &&
        other.index == index &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(bookId, index, title);

  @override
  String toString() =>
      'ChapterSummary(bookId: $bookId, index: $index, title: $title)';
}

import 'reading_anchor.dart';

/// 一本书读到的位置。
class ReadingPosition {
  const ReadingPosition({
    required this.bookId,
    required this.chapterIndex,
    required this.anchor,
  });

  final String bookId;
  final int chapterIndex;

  /// 章内的阅读锚点。
  final ReadingAnchor anchor;

  ReadingPosition copyWith({
    String? bookId,
    int? chapterIndex,
    ReadingAnchor? anchor,
  }) {
    return ReadingPosition(
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      anchor: anchor ?? this.anchor,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingPosition &&
        other.bookId == bookId &&
        other.chapterIndex == chapterIndex &&
        other.anchor == anchor;
  }

  @override
  int get hashCode => Object.hash(bookId, chapterIndex, anchor);

  @override
  String toString() =>
      'ReadingPosition(bookId: $bookId, chapterIndex: $chapterIndex, '
      'anchor: $anchor)';
}

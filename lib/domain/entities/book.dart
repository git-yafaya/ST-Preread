import 'nullable_value_getter.dart';

/// 书架上的一本书。
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImagePath,
    required this.chapterCount,
    required this.importedAt,
  });

  final String id;
  final String title;
  final String? author;

  /// 本地路径；为 null 时由 UI 显示占位封面。
  final String? coverImagePath;
  final int chapterCount;
  final DateTime importedAt;

  Book copyWith({
    String? id,
    String? title,
    NullableValueGetter<String>? author,
    NullableValueGetter<String>? coverImagePath,
    int? chapterCount,
    DateTime? importedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author == null ? this.author : author(),
      coverImagePath: coverImagePath == null
          ? this.coverImagePath
          : coverImagePath(),
      chapterCount: chapterCount ?? this.chapterCount,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Book &&
        other.id == id &&
        other.title == title &&
        other.author == author &&
        other.coverImagePath == coverImagePath &&
        other.chapterCount == chapterCount &&
        other.importedAt == importedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, author, coverImagePath, chapterCount, importedAt);

  @override
  String toString() => 'Book(id: $id, title: $title)';
}

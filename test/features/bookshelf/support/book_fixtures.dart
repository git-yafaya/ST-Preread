import 'package:st_preread/domain/domain.dart';

/// 构造一本测试用的书；只需写出用例关心的字段。
Book buildBook({
  String id = 'book-1',
  String title = '测试之书',
  String? author = '某作者',
  String? coverImagePath,
  int chapterCount = 3,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    coverImagePath: coverImagePath,
    chapterCount: chapterCount,
    importedAt: DateTime.utc(2026, 10, 8),
  );
}

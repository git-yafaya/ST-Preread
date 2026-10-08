import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const summary = ChapterSummary(bookId: 'book-1', index: 0, title: '第一章');
  const illustration = IllustrationBlock(
    id: 'block-1',
    imagePath: 'images/a.png',
    caption: null,
  );

  Chapter buildChapter() {
    return const Chapter(summary: summary, blocks: [illustration]);
  }

  group('Chapter', () {
    test('目录信息与块列表逐项相同时相等且哈希一致', () {
      final first = buildChapter();
      final second = Chapter(summary: summary, blocks: List.of(first.blocks));
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('目录信息或块不同则不相等', () {
      final chapter = buildChapter();
      expect(
        chapter.copyWith(summary: summary.copyWith(title: '别的章')),
        isNot(chapter),
      );
      expect(chapter.copyWith(blocks: const []), isNot(chapter));
    });

    test('copyWith 只替换传入的字段', () {
      final emptied = buildChapter().copyWith(blocks: const []);
      expect(emptied.summary, summary);
      expect(emptied.blocks, isEmpty);
      expect(buildChapter().copyWith(), buildChapter());
    });
  });
}

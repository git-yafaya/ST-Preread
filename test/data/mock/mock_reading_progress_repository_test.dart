import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/mock_reading_progress_repository.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  late MockReadingProgressRepository repository;

  setUp(() {
    repository = MockReadingProgressRepository();
  });

  group('MockReadingProgressRepository', () {
    test('没有保存过进度的书返回 null', () async {
      expect(await repository.loadPosition('book-1'), isNull);
    });

    test('保存后可以读回', () async {
      const position = ReadingPosition(
        bookId: 'book-1',
        chapterIndex: 1,
        blockIndex: 4,
      );

      await repository.savePosition(position);

      expect(await repository.loadPosition('book-1'), position);
    });

    test('同一本书再次保存会覆盖旧进度', () async {
      const earlier = ReadingPosition(
        bookId: 'book-1',
        chapterIndex: 0,
        blockIndex: 2,
      );
      final later = earlier.copyWith(chapterIndex: 2, blockIndex: 0);

      await repository.savePosition(earlier);
      await repository.savePosition(later);

      expect(await repository.loadPosition('book-1'), later);
    });

    test('不同书的进度互不影响', () async {
      const firstBookPosition = ReadingPosition(
        bookId: 'book-1',
        chapterIndex: 1,
        blockIndex: 1,
      );
      const secondBookPosition = ReadingPosition(
        bookId: 'book-2',
        chapterIndex: 2,
        blockIndex: 2,
      );

      await repository.savePosition(firstBookPosition);
      await repository.savePosition(secondBookPosition);

      expect(await repository.loadPosition('book-1'), firstBookPosition);
      expect(await repository.loadPosition('book-2'), secondBookPosition);
    });
  });
}

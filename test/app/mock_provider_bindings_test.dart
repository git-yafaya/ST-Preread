import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/app/mock_provider_bindings.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: buildMockProviderBindings());
    addTearDown(container.dispose);
  });

  group('buildMockProviderBindings', () {
    test('四个接口都绑定到了可用的实现', () {
      expect(container.read(bookRepositoryProvider), isA<BookRepository>());
      expect(
        container.read(readingProgressRepositoryProvider),
        isA<ReadingProgressRepository>(),
      );
      expect(
        container.read(readerSettingsRepositoryProvider),
        isA<ReaderSettingsRepository>(),
      );
      expect(
        container.read(audioPlaybackServiceProvider),
        isA<AudioPlaybackService>(),
      );
    });

    test('同一个容器内反复读取得到同一个实例，状态才能在页面之间共享', () {
      expect(
        container.read(bookRepositoryProvider),
        same(container.read(bookRepositoryProvider)),
      );
      expect(
        container.read(readingProgressRepositoryProvider),
        same(container.read(readingProgressRepositoryProvider)),
      );
    });

    test('绑定后的书库自带示例书，可以一路读到章节正文', () async {
      final repository = container.read(bookRepositoryProvider);

      final books = await repository.watchBooks().first;
      final chapter = await repository.loadChapter(books.first.id, 0);

      expect(books, isNotEmpty);
      expect(chapter.blocks, isNotEmpty);
    });
  });
}

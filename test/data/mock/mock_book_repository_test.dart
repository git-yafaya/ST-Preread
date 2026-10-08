import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/mock_book_repository.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 10, 8, 12);

  MockBookRepository buildRepository({int? initialBookCount}) {
    final repository = MockBookRepository(
      readCurrentTime: () => fixedTime,
      initialBookCount:
          initialBookCount ?? MockBookRepository.defaultInitialBookCount,
    );
    addTearDown(repository.dispose);
    return repository;
  }

  Future<List<Book>> currentBooks(MockBookRepository repository) {
    return repository.watchBooks().first;
  }

  group('MockBookRepository 书架', () {
    test('默认预置示例书，导入时间来自注入的时间源', () async {
      final books = await currentBooks(buildRepository());

      expect(books, hasLength(MockBookRepository.defaultInitialBookCount));
      expect(books.first.importedAt, fixedTime);
    });

    test('初始数量为 0 时书架为空', () async {
      expect(await currentBooks(buildRepository(initialBookCount: 0)), isEmpty);
    });

    test('导入忽略路径并追加一本可区分的示例书', () async {
      final repository = buildRepository();
      final existingBook = (await currentBooks(repository)).single;

      final importedBook = await repository.importBook('/any/ignored/path');

      expect(importedBook.id, isNot(existingBook.id));
      expect(importedBook.title, isNot(existingBook.title));
      expect(await currentBooks(repository), [existingBook, importedBook]);
    });

    test('订阅者依次收到导入与删除后的书架', () async {
      final repository = buildRepository(initialBookCount: 0);
      final bookCounts = <int>[];
      final subscription = repository.watchBooks().listen(
        (books) => bookCounts.add(books.length),
      );
      addTearDown(subscription.cancel);

      final firstBook = await repository.importBook('first');
      await repository.importBook('second');
      await repository.deleteBook(firstBook.id);
      await pumpEventQueue();

      expect(bookCounts, [0, 1, 2, 1]);
    });

    test('删除后书从书架消失，其内容也不再可读', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;

      await repository.deleteBook(book.id);

      expect(await currentBooks(repository), isEmpty);
      expect(
        repository.listChapters(book.id),
        throwsA(isA<BookNotFoundException>()),
      );
    });

    test('删除后再导入不会复用旧 id', () async {
      final repository = buildRepository();
      final deletedBook = (await currentBooks(repository)).single;
      await repository.deleteBook(deletedBook.id);

      final importedBook = await repository.importBook('again');

      expect(importedBook.id, isNot(deletedBook.id));
    });

    test('删除不存在的书抛 BookNotFoundException', () {
      expect(
        buildRepository().deleteBook('missing'),
        throwsA(
          isA<BookNotFoundException>().having(
            (exception) => exception.bookId,
            'bookId',
            'missing',
          ),
        ),
      );
    });
  });

  group('MockBookRepository 交出的章节不可被改动', () {
    /// 取第一章里一个两面都有样式、译文有句级数据的段落。
    Future<ParagraphBlock> loadStyledParagraph(
      MockBookRepository repository,
      String bookId,
    ) async {
      final chapter = await repository.loadChapter(bookId, 0);
      return chapter.blocks.whereType<ParagraphBlock>().firstWhere(
        (paragraph) =>
            (paragraph.translation?.styleSpans.isNotEmpty ?? false) &&
            (paragraph.translation?.sentences.isNotEmpty ?? false),
      );
    }

    test('块、句子、样式区间与样式集合都拒绝修改', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;
      final chapter = await repository.loadChapter(book.id, 0);
      final translation = (await loadStyledParagraph(
        repository,
        book.id,
      )).translation!;

      expect(chapter.blocks.clear, throwsUnsupportedError);
      expect(translation.sentences.clear, throwsUnsupportedError);
      expect(translation.styleSpans.clear, throwsUnsupportedError);
      expect(translation.styleSpans.first.styles.clear, throwsUnsupportedError);
      expect(
        () => translation.styleSpans.first.styles.add(InlineStyle.code),
        throwsUnsupportedError,
      );
    });

    test('整本书所有段落的集合都不可修改', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;

      for (final summary in await repository.listChapters(book.id)) {
        final chapter = await repository.loadChapter(book.id, summary.index);
        final sidedTexts = [
          for (final paragraph in chapter.blocks.whereType<ParagraphBlock>())
            for (final side in TextSide.values) ?paragraph.textOf(side),
        ];

        expect(chapter.blocks.clear, throwsUnsupportedError);
        for (final sidedText in sidedTexts) {
          expect(sidedText.sentences.clear, throwsUnsupportedError);
          expect(sidedText.styleSpans.clear, throwsUnsupportedError);
        }
      }
    });

    test('尝试修改之后重新加载，内容与之前完全一致', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;
      final translationBefore = (await loadStyledParagraph(
        repository,
        book.id,
      )).translation!;
      final sentencesBefore = List.of(translationBefore.sentences);
      final styleSpansBefore = List.of(translationBefore.styleSpans);

      expect(translationBefore.sentences.clear, throwsUnsupportedError);
      expect(translationBefore.styleSpans.clear, throwsUnsupportedError);
      final translationAfter = (await loadStyledParagraph(
        repository,
        book.id,
      )).translation!;

      expect(translationAfter.sentences, sentencesBefore);
      expect(translationAfter.styleSpans, styleSpansBefore);
      expect(sentencesBefore, isNotEmpty);
      expect(styleSpansBefore, isNotEmpty);
    });

    test('目录列表拒绝修改', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;
      final summaries = await repository.listChapters(book.id);

      expect(summaries.clear, throwsUnsupportedError);
      expect(
        await repository.listChapters(book.id),
        hasLength(book.chapterCount),
      );
    });

    test('书架列表拒绝修改', () async {
      final books = await currentBooks(buildRepository());

      expect(books.clear, throwsUnsupportedError);
    });
  });

  group('MockBookRepository 章节', () {
    test('目录与书的章节数一致，下标从 0 连续递增', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;

      final summaries = await repository.listChapters(book.id);

      expect(summaries, hasLength(book.chapterCount));
      expect(
        summaries.map((summary) => summary.index),
        List.generate(book.chapterCount, (index) => index),
      );
      expect(summaries.map((summary) => summary.bookId).toSet(), {book.id});
    });

    test('加载到的章节与目录项对应且有正文', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;
      final summaries = await repository.listChapters(book.id);

      for (final summary in summaries) {
        final chapter = await repository.loadChapter(book.id, summary.index);
        expect(chapter.summary, summary);
        expect(chapter.blocks, isNotEmpty);
      }
    });

    test('找不到书时抛 BookNotFoundException', () {
      final repository = buildRepository();

      expect(
        repository.listChapters('missing'),
        throwsA(isA<BookNotFoundException>()),
      );
      expect(
        repository.loadChapter('missing', 0),
        throwsA(isA<BookNotFoundException>()),
      );
    });

    test('章节下标越界时抛 ChapterNotFoundException', () async {
      final repository = buildRepository();
      final book = (await currentBooks(repository)).single;

      for (final invalidIndex in [-1, book.chapterCount]) {
        expect(
          repository.loadChapter(book.id, invalidIndex),
          throwsA(
            isA<ChapterNotFoundException>()
                .having((exception) => exception.bookId, 'bookId', book.id)
                .having(
                  (exception) => exception.chapterIndex,
                  'chapterIndex',
                  invalidIndex,
                ),
          ),
        );
      }
    });
  });
}

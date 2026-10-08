import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/errors/domain_exceptions.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const sentence = SentenceRef(
    blockIndex: 2,
    side: TextSide.source,
    sentenceIndex: 5,
  );

  test('领域异常携带定位问题所需的信息', () {
    const bookNotFound = BookNotFoundException('book-1');
    const chapterNotFound = ChapterNotFoundException(
      bookId: 'book-1',
      chapterIndex: 9,
    );
    const sentenceNotPlayable = SentenceNotPlayableException(sentence);

    expect(bookNotFound.bookId, 'book-1');
    expect(bookNotFound.toString(), contains('book-1'));
    expect(chapterNotFound.bookId, 'book-1');
    expect(chapterNotFound.chapterIndex, 9);
    expect(chapterNotFound.toString(), contains('9'));
    expect(sentenceNotPlayable.sentence, sentence);
    expect(sentenceNotPlayable.toString(), contains('sentenceIndex: 5'));
  });

  test('领域异常都属于 DomainException，可被 UI 层统一捕获', () {
    const List<Object> exceptions = [
      BookNotFoundException('book-1'),
      ChapterNotFoundException(bookId: 'book-1', chapterIndex: 0),
      SentenceNotPlayableException(sentence),
    ];

    expect(exceptions, everyElement(isA<DomainException>()));
    expect(exceptions, everyElement(isA<Exception>()));
  });
}

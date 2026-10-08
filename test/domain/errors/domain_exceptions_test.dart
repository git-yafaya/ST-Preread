import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const clip = AudioClip(filePath: 'audio/a.mp3', start: null, end: null);

  test('领域异常携带定位问题所需的信息', () {
    const bookNotFound = BookNotFoundException('book-1');
    const chapterNotFound = ChapterNotFoundException(
      bookId: 'book-1',
      chapterIndex: 9,
    );
    final playbackFailed = AudioPlaybackFailedException(
      clip: clip,
      cause: StateError('解码失败'),
    );

    expect(bookNotFound.bookId, 'book-1');
    expect(bookNotFound.toString(), contains('book-1'));
    expect(chapterNotFound.bookId, 'book-1');
    expect(chapterNotFound.chapterIndex, 9);
    expect(chapterNotFound.toString(), contains('9'));
    expect(playbackFailed.clip, clip);
    expect(playbackFailed.cause, isA<StateError>());
    expect(playbackFailed.toString(), contains('audio/a.mp3'));
  });

  test('播放失败的原因可以不提供', () {
    const playbackFailed = AudioPlaybackFailedException(clip: clip);

    expect(playbackFailed.cause, isNull);
  });

  test('领域异常都属于 DomainException，可被 UI 层统一捕获', () {
    const List<Object> exceptions = [
      BookNotFoundException('book-1'),
      ChapterNotFoundException(bookId: 'book-1', chapterIndex: 0),
      AudioPlaybackFailedException(clip: clip),
    ];

    expect(exceptions, everyElement(isA<DomainException>()));
    expect(exceptions, everyElement(isA<Exception>()));
  });
}

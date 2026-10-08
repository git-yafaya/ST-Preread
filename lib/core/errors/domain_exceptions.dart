import '../../domain/entities/sentence_ref.dart';

/// 领域异常的共同父类型。
///
/// UI 层据此区分「可以转成用户提示的业务错误」与程序缺陷。
sealed class DomainException implements Exception {
  const DomainException();
}

/// 按 id 找不到书。
final class BookNotFoundException extends DomainException {
  const BookNotFoundException(this.bookId);

  final String bookId;

  @override
  String toString() => 'BookNotFoundException(bookId: $bookId)';
}

/// 书存在，但没有这个下标的章节。
final class ChapterNotFoundException extends DomainException {
  const ChapterNotFoundException({
    required this.bookId,
    required this.chapterIndex,
  });

  final String bookId;
  final int chapterIndex;

  @override
  String toString() =>
      'ChapterNotFoundException(bookId: $bookId, chapterIndex: $chapterIndex)';
}

/// 要求播放的句子不在当前播放队列里（不属于已加载的那一面，或没有语音）。
final class SentenceNotPlayableException extends DomainException {
  const SentenceNotPlayableException(this.sentence);

  final SentenceRef sentence;

  @override
  String toString() => 'SentenceNotPlayableException(sentence: $sentence)';
}

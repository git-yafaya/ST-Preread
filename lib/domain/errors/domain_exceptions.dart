import '../entities/audio_clip.dart';

/// 领域异常的共同父类型。
///
/// UI 层据此区分「可以转成用户提示的业务错误」与程序缺陷。
/// 定义在领域层，这样数据层抛出、界面层捕获都只需依赖领域层。
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

/// 语音无法读取或解码，播放没有开始。
final class AudioPlaybackFailedException extends DomainException {
  const AudioPlaybackFailedException({required this.clip, this.cause});

  final AudioClip clip;

  /// 底层播放器报告的原始错误，仅用于排查，不直接展示给用户。
  final Object? cause;

  @override
  String toString() =>
      'AudioPlaybackFailedException(clip: $clip, cause: $cause)';
}

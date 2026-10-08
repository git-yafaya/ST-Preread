import '../entities/chapter.dart';
import '../entities/nullable_value_getter.dart';
import '../entities/sentence_ref.dart';
import '../entities/text_side.dart';

enum PlaybackStatus { idle, playing, paused }

/// 播放器对外可见的状态。
class PlaybackState {
  const PlaybackState({
    required this.status,
    required this.sentence,
    required this.position,
    required this.duration,
  });

  const PlaybackState.idle()
    : status = PlaybackStatus.idle,
      sentence = null,
      position = Duration.zero,
      duration = null;

  final PlaybackStatus status;

  /// 正在播放的句子；idle 时为 null。
  final SentenceRef? sentence;

  /// 当前句内的播放位置。
  final Duration position;

  /// 当前句的时长，未知时为 null。
  final Duration? duration;

  PlaybackState copyWith({
    PlaybackStatus? status,
    NullableValueGetter<SentenceRef>? sentence,
    Duration? position,
    NullableValueGetter<Duration>? duration,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      sentence: sentence == null ? this.sentence : sentence(),
      position: position ?? this.position,
      duration: duration == null ? this.duration : duration(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaybackState &&
        other.status == status &&
        other.sentence == sentence &&
        other.position == position &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(status, sentence, position, duration);

  @override
  String toString() =>
      'PlaybackState(status: ${status.name}, sentence: $sentence, '
      'position: $position, duration: $duration)';
}

/// 以「章的某一面」为播放队列，按顺序逐句播放其中带语音的句子。
abstract interface class AudioPlaybackService {
  /// 订阅后立即收到当前状态，之后每次变化再推送。
  Stream<PlaybackState> watchState();

  /// 换用新的播放队列；正在进行的播放会被停止。
  Future<void> loadChapter(Chapter chapter, TextSide side);

  /// [sentence] 必须在当前队列里（属于已加载的那一面且带语音），
  /// 否则抛出 core 中定义的 SentenceNotPlayableException。
  Future<void> playFrom(SentenceRef sentence);

  Future<void> pause();

  /// 仅在 paused 时生效。idle 时不做任何事：
  /// 「从哪一句开始」由阅读页决定，播放服务不猜。
  Future<void> resume();

  /// 已是队列最后一句时停止并回到 idle。
  Future<void> skipToNextSentence();

  /// 已是队列第一句时从该句开头重播。
  Future<void> skipToPreviousSentence();

  Future<void> stop();
}

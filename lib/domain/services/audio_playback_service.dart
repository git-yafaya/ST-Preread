import '../entities/audio_clip.dart';
import '../entities/nullable_value_getter.dart';
import '../entities/sentence_ref.dart';

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

  /// 正在播放或暂停中的句子；idle 时为 null。
  final SentenceRef? sentence;

  /// 相对这一句的语音片段的播放位置（不是相对整个文件）。
  final Duration position;

  /// 这一句语音片段的时长，未知时为 null。
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

/// 一次只播一句：点哪句播哪句，播完即结束。没有队列，没有连续朗读。
///
/// 服务不知道章节与页面，[SentenceRef] 只是原样带回给界面用于高亮；
/// 所以切换章节、离开阅读页前，调用方必须先 [stop]，
/// 否则旧章的句子定位会被新章误用。
abstract interface class AudioPlaybackService {
  /// 订阅后立即收到当前状态，之后每次变化再推送。
  Stream<PlaybackState> watchState();

  /// 播放 [sentence] 的语音 [clip]；正在播放或暂停中的句子会被立即丢弃。
  ///
  /// Future 在开始播放后完成。语音无法读取或解码时抛出
  /// AudioPlaybackFailedException，状态回到 idle。
  /// 被打断的旧句子不会再发出任何状态。
  Future<void> play({required SentenceRef sentence, required AudioClip clip});

  /// 仅在 playing 时生效：保留句子与位置，进入 paused。
  Future<void> pause();

  /// 仅在 paused 时生效：从暂停位置继续播放。
  Future<void> resume();

  /// playing 或 paused 时回到 idle；idle 时不做任何事。
  Future<void> stop();
}

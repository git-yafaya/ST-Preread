import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import 'unbound_provider_error.dart';

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>(
  (ref) => throw UnboundProviderError('audioPlaybackServiceProvider'),
);

/// 当前播放状态。播放条与阅读页（句高亮）共用这一份订阅。
final playbackStateProvider = StreamProvider<PlaybackState>(
  (ref) => ref.watch(audioPlaybackServiceProvider).watchState(),
);

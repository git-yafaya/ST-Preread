import 'package:flutter/material.dart';

import '../../core/constants/player_layout_constants.dart';
import '../../core/constants/player_strings.dart';
import '../../domain/domain.dart';
import 'playback_progress.dart';

/// 播放条的可见部分：这一句语音的进度，以及「暂停或继续」「停止」两个按钮。
///
/// 只负责显示与转发点击，不接触播放服务。
class PlayerBarContent extends StatelessWidget {
  const PlayerBarContent({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    super.key,
  });

  final PlaybackState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: PlayerLayoutConstants.elevation,
      color: Theme.of(context).colorScheme.surfaceContainer,
      // 播放条贴着屏幕底部时要让开系统手势区；放在可见部分内部，
      // 这样 idle 时不会留下一条空白。
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PlaybackProgressTrack(state: state),
            _PlayerControlRow(
              state: state,
              onPause: onPause,
              onResume: onResume,
              onStop: onStop,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackProgressTrack extends StatelessWidget {
  const _PlaybackProgressTrack({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context) {
    final fraction = playbackProgressFraction(
      position: state.position,
      duration: state.duration,
    );
    // 时长未知时算不出比例：留出同样的高度但不画进度条，
    // 既不误导成「0%」，播放条的高度也不会跳动。
    if (fraction == null) {
      return const SizedBox(height: PlayerLayoutConstants.progressTrackHeight);
    }
    return LinearProgressIndicator(
      value: fraction,
      minHeight: PlayerLayoutConstants.progressTrackHeight,
      semanticsLabel: PlayerStrings.progressSemanticsLabel,
      semanticsValue: formatProgressPercent(fraction),
    );
  }
}

class _PlayerControlRow extends StatelessWidget {
  const _PlayerControlRow({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final PlaybackState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PlayerLayoutConstants.horizontalPadding,
        vertical: PlayerLayoutConstants.verticalPadding,
      ),
      child: Row(
        children: [
          Expanded(child: _PlaybackTimeLabel(state: state)),
          _PauseOrResumeButton(
            isPlaying: state.status == PlaybackStatus.playing,
            onPause: onPause,
            onResume: onResume,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: PlayerStrings.stopTooltip,
            onPressed: onStop,
          ),
        ],
      ),
    );
  }
}

class _PlaybackTimeLabel extends StatelessWidget {
  const _PlaybackTimeLabel({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context) {
    final label = formatPlaybackTimeLabel(
      position: state.position,
      duration: state.duration,
      separator: PlayerStrings.timeSeparator,
    );
    return Text(
      label,
      // 等宽数字：秒数跳动时文字宽度不变，不会左右抖动。
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}

class _PauseOrResumeButton extends StatelessWidget {
  const _PauseOrResumeButton({
    required this.isPlaying,
    required this.onPause,
    required this.onResume,
  });

  final bool isPlaying;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    if (isPlaying) {
      return IconButton(
        icon: const Icon(Icons.pause),
        tooltip: PlayerStrings.pauseTooltip,
        onPressed: onPause,
      );
    }
    return IconButton(
      icon: const Icon(Icons.play_arrow),
      tooltip: PlayerStrings.resumeTooltip,
      onPressed: onResume,
    );
  }
}

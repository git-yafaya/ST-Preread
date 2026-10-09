import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/player_layout_constants.dart';
import '../../core/providers/providers.dart';
import '../../domain/domain.dart';
import 'player_bar_content.dart';

/// 精简播放条：只在播放或暂停时出现，idle 时不显示也不占位。
///
/// 自己监听播放状态并直接调用播放服务，阅读页只需把它放进布局。
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  /// 播放中与暂停时共用同一个 key：进度刷新、暂停与继续之间互相切换时
  /// 都是原地更新，只有出现与消失才触发过渡。
  static const ValueKey<String> _visibleContentKey = ValueKey<String>(
    'player-bar-visible-content',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 状态尚未读到或读取出错时都按 idle 处理：没有可控制的句子就不该出现播放条。
    final state = ref.watch(playbackStateProvider).value;
    final isVisible = state != null && state.status != PlaybackStatus.idle;
    return AnimatedSwitcher(
      duration: PlayerLayoutConstants.visibilityTransitionDuration,
      transitionBuilder: _buildVisibilityTransition,
      child: isVisible
          ? _buildVisibleContent(ref, state)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildVisibleContent(WidgetRef ref, PlaybackState state) {
    final service = ref.read(audioPlaybackServiceProvider);
    return PlayerBarContent(
      key: _visibleContentKey,
      state: state,
      onPause: service.pause,
      onResume: service.resume,
      onStop: service.stop,
    );
  }

  /// 从上边缘向下展开并淡入；高度随动画变化，消失后不再占位。
  static Widget _buildVisibilityTransition(
    Widget child,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

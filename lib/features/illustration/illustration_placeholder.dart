import 'package:flutter/material.dart';

import '../../core/constants/illustration_layout_constants.dart';
import '../../core/constants/illustration_strings.dart';

/// 图片读不出来时代替它显示的占位。
class IllustrationPlaceholder extends StatelessWidget {
  const IllustrationPlaceholder({required this.semanticLabel, super.key});

  /// 与本应显示的图片相同的语义标签，读屏用户仍然知道这里是哪张图。
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: semanticLabel,
      value: IllustrationStrings.imageUnavailable,
      // 占位里的文字已经作为语义值给出，不必再读一遍。
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: IllustrationLayoutConstants.placeholderAspectRatio,
          child: ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: _PlaceholderHint(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderHint extends StatelessWidget {
  const _PlaceholderHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      // 翻页模式可能只给很小的高度；图标与文字整体缩小，而不是溢出。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(
            IllustrationLayoutConstants.placeholderPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: IllustrationLayoutConstants.placeholderIconSize,
                color: color,
              ),
              const SizedBox(
                height:
                    IllustrationLayoutConstants.placeholderIconToTextSpacing,
              ),
              Text(
                IllustrationStrings.imageUnavailable,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

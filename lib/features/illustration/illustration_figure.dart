import 'package:flutter/material.dart';

import '../../core/constants/illustration_layout_constants.dart';
import '../../core/constants/illustration_strings.dart';
import 'illustration_placeholder.dart';

/// 一张图加可选的说明文字，整体不超出父级给的宽高。
///
/// 图片来源以 [ImageProvider] 传入而不是文件路径，
/// 这样排版规则可以脱离文件系统单独验证。
class IllustrationFigure extends StatelessWidget {
  const IllustrationFigure({
    required this.image,
    required this.caption,
    super.key,
  });

  final ImageProvider image;
  final String? caption;

  /// 只有空白的说明等同于没有说明。
  String? get _visibleCaption {
    final trimmedCaption = caption?.trim();
    if (trimmedCaption == null || trimmedCaption.isEmpty) {
      return null;
    }
    return trimmedCaption;
  }

  @override
  Widget build(BuildContext context) {
    final visibleCaption = _visibleCaption;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = _resolveMaxHeight(constraints);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: _buildImage(visibleCaption)),
              if (visibleCaption != null)
                _IllustrationCaption(
                  caption: visibleCaption,
                  maxHeight:
                      maxHeight *
                      IllustrationLayoutConstants.captionMaxHeightFraction,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 父级限制了高度（翻页模式的一页）就用它；没有限制（滚动模式）时用常量兜底。
  double _resolveMaxHeight(BoxConstraints constraints) {
    if (constraints.hasBoundedHeight) {
      return constraints.maxHeight;
    }
    return IllustrationLayoutConstants.maxHeightWhenUnbounded;
  }

  Widget _buildImage(String? visibleCaption) {
    final semanticLabel =
        visibleCaption ?? IllustrationStrings.genericSemanticsLabel;
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        IllustrationLayoutConstants.imageCornerRadius,
      ),
      child: Image(
        image: image,
        // 只缩小、不裁切：图片内容必须完整可见。
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
        errorBuilder: (context, error, stackTrace) =>
            IllustrationPlaceholder(semanticLabel: semanticLabel),
      ),
    );
  }
}

class _IllustrationCaption extends StatelessWidget {
  const _IllustrationCaption({required this.caption, required this.maxHeight});

  final String caption;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.only(
          top: IllustrationLayoutConstants.captionTopSpacing,
        ),
        // 说明已经用作图片的语义标签，这里再读一遍就重复了。
        child: ExcludeSemantics(
          child: Text(
            caption,
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

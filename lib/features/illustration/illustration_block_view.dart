import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'illustration_figure.dart';

/// 正文中的插图块：显示本地图片与可选的说明文字。
///
/// 图片读不出来（文件不存在、损坏）时显示占位，不抛异常；
/// 尺寸服从父级约束，滚动与翻页两种视图都可以直接放。
class IllustrationBlockView extends StatelessWidget {
  const IllustrationBlockView({required this.block, super.key});

  final IllustrationBlock block;

  @override
  Widget build(BuildContext context) {
    return IllustrationFigure(
      image: FileImage(File(block.imagePath)),
      caption: block.caption,
    );
  }
}

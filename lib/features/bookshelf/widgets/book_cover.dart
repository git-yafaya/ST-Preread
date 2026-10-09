import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/bookshelf_layout_constants.dart';

/// 书的封面：没有封面或封面读不出来时显示占位封面。
class BookCover extends StatelessWidget {
  const BookCover({required this.coverImagePath, super.key});

  /// 封面图片的本地路径；为 null 表示这本书没有封面。
  final String? coverImagePath;

  @override
  Widget build(BuildContext context) {
    final imagePath = coverImagePath;
    if (imagePath == null) {
      return const BookCoverPlaceholder();
    }
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      // 封面只是装饰，书名已在卡片上以文字给出，不必让读屏再念一遍。
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          const BookCoverPlaceholder(),
    );
  }
}

/// 占位封面。
class BookCoverPlaceholder extends StatelessWidget {
  const BookCoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: BookshelfLayoutConstants.placeholderCoverIconSize,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/placeholder_strings.dart';

/// 阅读页。占位实现，待阅读功能替换。
class ReaderPage extends StatelessWidget {
  const ReaderPage({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(bookId)),
      body: const Center(child: Text(PlaceholderStrings.readerPage)),
    );
  }
}

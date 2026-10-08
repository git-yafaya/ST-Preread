import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/placeholder_strings.dart';

/// 书架页。占位实现，待书架功能替换。
class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: const Center(child: Text(PlaceholderStrings.bookshelfPage)),
    );
  }
}

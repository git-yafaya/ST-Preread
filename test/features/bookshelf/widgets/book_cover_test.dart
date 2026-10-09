import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/features/bookshelf/widgets/book_cover.dart';

void main() {
  Future<void> pumpCover(WidgetTester tester, String? coverImagePath) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BookCover(coverImagePath: coverImagePath)),
      ),
    );
  }

  group('BookCover', () {
    testWidgets('没有封面路径时显示占位封面', (tester) async {
      await pumpCover(tester, null);

      expect(find.byType(BookCoverPlaceholder), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('有封面路径时按该路径读取图片', (tester) async {
      const coverImagePath = '/covers/some-book.png';
      await pumpCover(tester, coverImagePath);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, FileImage(File(coverImagePath)));
      expect(find.byType(BookCoverPlaceholder), findsNothing);
    });

    testWidgets('封面读不出来时改为显示占位封面', (tester) async {
      await pumpCover(tester, '/covers/unreadable-cover.png');
      final imageFinder = find.byType(Image);

      // 读文件是真实的 IO，在测试的假时钟里不会有结果，等不到真正的读取失败；
      // 所以直接问这张图片「读取失败时显示什么」。
      final shownOnFailure = tester.widget<Image>(imageFinder).errorBuilder!(
        tester.element(imageFinder),
        const FileSystemException('读不出来'),
        null,
      );

      expect(shownOnFailure, isA<BookCoverPlaceholder>());
    });
  });
}

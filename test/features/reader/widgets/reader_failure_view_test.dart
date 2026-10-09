import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_strings.dart';
import 'package:st_preread/features/reader/logic/reader_state.dart';
import 'package:st_preread/features/reader/widgets/reader_failure_view.dart';

void main() {
  late int retryCount;

  setUp(() {
    retryCount = 0;
  });

  Future<void> pumpFailure(
    WidgetTester tester,
    ReaderFailureReason reason,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderFailureView(reason: reason, onRetry: () => retryCount++),
        ),
      ),
    );
  }

  const expectedMessages = {
    ReaderFailureReason.bookNotFound: ReaderStrings.bookNotFound,
    ReaderFailureReason.chapterNotFound: ReaderStrings.chapterNotFound,
    ReaderFailureReason.emptyBook: ReaderStrings.emptyBook,
    ReaderFailureReason.unknown: ReaderStrings.loadFailed,
  };

  for (final MapEntry(key: reason, value: message)
      in expectedMessages.entries) {
    testWidgets('失败原因为 ${reason.name} 时显示「$message」', (tester) async {
      await pumpFailure(tester, reason);

      expect(find.text(message), findsOneWidget);
    });
  }

  test('每一种失败原因的提示文案都不相同', () {
    expect(expectedMessages.keys, ReaderFailureReason.values);
    expect(expectedMessages.values.toSet(), hasLength(expectedMessages.length));
  });

  testWidgets('点「重试」触发回调', (tester) async {
    await pumpFailure(tester, ReaderFailureReason.unknown);

    await tester.tap(find.text(ReaderStrings.retry));

    expect(retryCount, 1);
  });
}

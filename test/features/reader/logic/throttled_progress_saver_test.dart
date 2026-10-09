import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/logic/throttled_progress_saver.dart';

import '../support/reader_fakes.dart';
import '../support/reader_fixtures.dart';

void main() {
  const interval = Duration(seconds: 3);

  late ManualDelayedCallScheduler scheduler;
  late RecordingProgressRepository repository;
  late ThrottledProgressSaver saver;

  ReadingPosition positionAt(int textOffset) {
    return ReadingPosition(
      bookId: fixtureBookId,
      chapterIndex: 0,
      anchor: ReadingAnchor(
        blockIndex: 0,
        side: TextSide.translation,
        textOffset: textOffset,
      ),
    );
  }

  setUp(() {
    scheduler = ManualDelayedCallScheduler();
    repository = RecordingProgressRepository();
    saver = ThrottledProgressSaver(
      interval: interval,
      savePosition: repository.savePosition,
      scheduleDelayedCall: scheduler.schedule,
    );
  });

  test('收到位置后不立即保存，间隔到了才保存', () {
    saver.schedule(positionAt(1));

    expect(repository.savedPositions, isEmpty);
    expect(scheduler.requestedDelays, [interval]);

    scheduler.elapse();

    expect(repository.savedPositions, [positionAt(1)]);
  });

  test('一个间隔内收到多次位置，只保存最后一次', () {
    saver.schedule(positionAt(1));
    saver.schedule(positionAt(2));
    saver.schedule(positionAt(3));

    scheduler.elapse();

    expect(scheduler.requestedDelays, hasLength(1));
    expect(repository.savedPositions, [positionAt(3)]);
  });

  test('一个间隔结束后，下一次位置重新开始计时', () {
    saver.schedule(positionAt(1));
    scheduler.elapse();
    saver.schedule(positionAt(2));

    expect(repository.savedPositions, [positionAt(1)]);
    expect(scheduler.requestedDelays, hasLength(2));

    scheduler.elapse();

    expect(repository.savedPositions, [positionAt(1), positionAt(2)]);
  });

  test('flush 立即保存尚未保存的位置，并取消计时', () {
    saver.schedule(positionAt(1));

    saver.flush();

    expect(repository.savedPositions, [positionAt(1)]);
    expect(scheduler.activeTimerCount, 0);

    scheduler.elapse();

    expect(repository.savedPositions, hasLength(1));
  });

  test('没有待保存的位置时 flush 什么也不做', () {
    saver.flush();

    expect(repository.savedPositions, isEmpty);
  });

  test('saveNow 绕过限速立即保存，并丢弃还没保存的旧位置', () {
    saver.schedule(positionAt(1));

    saver.saveNow(positionAt(9));

    expect(repository.savedPositions, [positionAt(9)]);
    expect(scheduler.activeTimerCount, 0);
  });
}

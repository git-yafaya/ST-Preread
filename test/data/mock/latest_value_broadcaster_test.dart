import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/latest_value_broadcaster.dart';

void main() {
  group('LatestValueBroadcaster', () {
    test('新订阅者先收到当前值', () async {
      final broadcaster = LatestValueBroadcaster<int>(1);
      addTearDown(broadcaster.close);

      expect(await broadcaster.watch().first, 1);

      broadcaster.emit(2);
      expect(broadcaster.value, 2);
      expect(await broadcaster.watch().first, 2);
    });

    test('订阅后依次收到后续变化', () async {
      final broadcaster = LatestValueBroadcaster<int>(1);
      final received = <int>[];
      final subscription = broadcaster.watch().listen(received.add);
      addTearDown(subscription.cancel);
      addTearDown(broadcaster.close);

      broadcaster.emit(2);
      broadcaster.emit(3);
      await pumpEventQueue();

      expect(received, [1, 2, 3]);
    });

    test('多个订阅者互不影响', () async {
      final broadcaster = LatestValueBroadcaster<int>(1);
      final firstReceived = <int>[];
      final secondReceived = <int>[];
      final firstSubscription = broadcaster.watch().listen(firstReceived.add);
      addTearDown(broadcaster.close);

      broadcaster.emit(2);
      await pumpEventQueue();
      final secondSubscription = broadcaster.watch().listen(secondReceived.add);
      addTearDown(secondSubscription.cancel);
      await firstSubscription.cancel();
      broadcaster.emit(3);
      await pumpEventQueue();

      expect(firstReceived, [1, 2]);
      expect(secondReceived, [2, 3]);
    });

    test('关闭后订阅者的流随之结束', () async {
      final broadcaster = LatestValueBroadcaster<int>(1);
      final received = broadcaster.watch().toList();

      broadcaster.emit(2);
      await broadcaster.close();

      expect(await received, [1, 2]);
    });
  });
}

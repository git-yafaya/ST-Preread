import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const sentence = SentenceRef(
    blockIndex: 1,
    side: TextSide.source,
    sentenceIndex: 0,
  );
  const state = PlaybackState(
    status: PlaybackStatus.playing,
    sentence: sentence,
    position: Duration(milliseconds: 300),
    duration: Duration(seconds: 2),
  );

  group('PlaybackState', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameState = PlaybackState(
        status: PlaybackStatus.playing,
        sentence: sentence,
        position: Duration(milliseconds: 300),
        duration: Duration(seconds: 2),
      );
      expect(state, sameState);
      expect(state.hashCode, sameState.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(state.copyWith(status: PlaybackStatus.paused), isNot(state));
      expect(state.copyWith(sentence: () => null), isNot(state));
      expect(state.copyWith(position: Duration.zero), isNot(state));
      expect(state.copyWith(duration: () => null), isNot(state));
    });

    test('copyWith 只替换传入的字段', () {
      final paused = state.copyWith(status: PlaybackStatus.paused);
      expect(paused.status, PlaybackStatus.paused);
      expect(paused.sentence, sentence);
      expect(paused.position, const Duration(milliseconds: 300));
      expect(paused.duration, const Duration(seconds: 2));
      expect(state.copyWith(), state);
    });

    test('idle 命名构造表示没有句子、位置为零、时长未知', () {
      const idleState = PlaybackState.idle();
      expect(idleState.status, PlaybackStatus.idle);
      expect(idleState.sentence, isNull);
      expect(idleState.position, Duration.zero);
      expect(idleState.duration, isNull);
      expect(idleState, const PlaybackState.idle());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/data/mock/mock_audio_playback_service.dart';
import 'package:st_preread/data/mock/mock_playback_timing.dart';
import 'package:st_preread/domain/domain.dart';

import '../../support/manual_playback_ticker.dart';

void main() {
  const tickInterval = MockPlaybackTiming.tickInterval;
  const firstSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.translation,
    sentenceIndex: 1,
  );
  const secondSentence = SentenceRef(
    blockIndex: 4,
    side: TextSide.source,
    sentenceIndex: 0,
  );
  final firstDuration = tickInterval * 5;
  final secondDuration = tickInterval * 8;
  // 两种片段形态：一句一个文件（从文件开头播起），以及共用文件里的一段区间。
  final firstClip = AudioClip(
    filePath: 'first.mp3',
    start: null,
    end: firstDuration,
  );
  final secondClip = AudioClip(
    filePath: 'shared.mp3',
    start: const Duration(seconds: 2),
    end: const Duration(seconds: 2) + secondDuration,
  );

  late ManualPlaybackTicker ticker;
  late MockAudioPlaybackService service;
  late List<PlaybackState> emittedStates;

  /// 等状态流把已发出的事件送达后，返回最新状态。
  Future<PlaybackState> currentState() async {
    await pumpEventQueue();
    return emittedStates.last;
  }

  Future<int> emittedStateCount() async {
    await pumpEventQueue();
    return emittedStates.length;
  }

  PlaybackState stateOfFirst({
    PlaybackStatus status = PlaybackStatus.playing,
    Duration position = Duration.zero,
  }) {
    return PlaybackState(
      status: status,
      sentence: firstSentence,
      position: position,
      duration: firstDuration,
    );
  }

  PlaybackState playingSecondFromStart() {
    return PlaybackState(
      status: PlaybackStatus.playing,
      sentence: secondSentence,
      position: Duration.zero,
      duration: secondDuration,
    );
  }

  Future<void> playFirst() {
    return service.play(sentence: firstSentence, clip: firstClip);
  }

  Future<void> playSecond() {
    return service.play(sentence: secondSentence, clip: secondClip);
  }

  /// 进入「第一句已暂停在两个间隔处」的状态。
  Future<void> pauseFirstAfterTwoTicks() async {
    await playFirst();
    ticker.tick(times: 2);
    await service.pause();
  }

  setUp(() {
    ticker = ManualPlaybackTicker();
    service = MockAudioPlaybackService(ticker: ticker);
    emittedStates = [];
    final subscription = service.watchState().listen(emittedStates.add);
    addTearDown(subscription.cancel);
    addTearDown(service.dispose);
  });

  test('初始为 idle，时间源未启动', () async {
    expect(await currentState(), const PlaybackState.idle());
    expect(ticker.isRunning, isFalse);
  });

  group('play', () {
    test('idle 时：从这一句的开头开始播放', () async {
      await playFirst();

      expect(await currentState(), stateOfFirst());
      expect(ticker.isRunning, isTrue);
      expect(ticker.lastInterval, tickInterval);
    });

    test('playing 时：立即停掉当前句，从头改播新的一句', () async {
      await playFirst();
      ticker.tick(times: 2);

      await playSecond();

      expect(await currentState(), playingSecondFromStart());
      expect(ticker.isRunning, isTrue);
    });

    test('playing 时再播同一句：从这一句的开头重新播放', () async {
      await playFirst();
      ticker.tick(times: 2);

      await playFirst();

      expect(await currentState(), stateOfFirst());
    });

    test('paused 时：丢弃暂停的句子，播放新的一句', () async {
      await pauseFirstAfterTwoTicks();

      await playSecond();

      expect(await currentState(), playingSecondFromStart());
      expect(ticker.isRunning, isTrue);
    });

    test('时长取自片段区间；没有结束位置时用兜底时长', () async {
      const wholeFileClip = AudioClip(
        filePath: 'whole.mp3',
        start: null,
        end: null,
      );

      await playFirst();
      expect((await currentState()).duration, firstDuration);

      await playSecond();
      expect((await currentState()).duration, secondDuration);

      await service.play(sentence: firstSentence, clip: wholeFileClip);
      expect(
        (await currentState()).duration,
        MockPlaybackTiming.fallbackClipDuration,
      );
    });
  });

  group('pause', () {
    test('idle 时：不做任何事', () async {
      final countBefore = await emittedStateCount();

      await service.pause();

      expect(await currentState(), const PlaybackState.idle());
      expect(await emittedStateCount(), countBefore);
      expect(ticker.isRunning, isFalse);
    });

    test('playing 时：进入 paused，保留句子与位置，时间不再推进', () async {
      await playFirst();
      ticker.tick(times: 2);

      await service.pause();
      ticker.tick(times: 10);

      expect(
        await currentState(),
        stateOfFirst(status: PlaybackStatus.paused, position: tickInterval * 2),
      );
      expect(ticker.isRunning, isFalse);
    });

    test('paused 时：不做任何事', () async {
      await pauseFirstAfterTwoTicks();
      final stateBefore = await currentState();
      final countBefore = await emittedStateCount();

      await service.pause();

      expect(await currentState(), stateBefore);
      expect(await emittedStateCount(), countBefore);
      expect(ticker.isRunning, isFalse);
    });
  });

  group('resume', () {
    test('idle 时：不做任何事', () async {
      final countBefore = await emittedStateCount();

      await service.resume();

      expect(await currentState(), const PlaybackState.idle());
      expect(await emittedStateCount(), countBefore);
      expect(ticker.isRunning, isFalse);
    });

    test('playing 时：不做任何事，播放照常推进', () async {
      await playFirst();
      ticker.tick();
      final countBefore = await emittedStateCount();

      await service.resume();

      expect(await currentState(), stateOfFirst(position: tickInterval));
      expect(await emittedStateCount(), countBefore);

      ticker.tick();
      expect(await currentState(), stateOfFirst(position: tickInterval * 2));
    });

    test('paused 时：从暂停位置继续播放', () async {
      await pauseFirstAfterTwoTicks();

      await service.resume();
      expect(await currentState(), stateOfFirst(position: tickInterval * 2));
      expect(ticker.isRunning, isTrue);

      ticker.tick();
      expect(await currentState(), stateOfFirst(position: tickInterval * 3));
    });
  });

  group('stop', () {
    test('idle 时：不做任何事', () async {
      final countBefore = await emittedStateCount();

      await service.stop();

      expect(await currentState(), const PlaybackState.idle());
      expect(await emittedStateCount(), countBefore);
    });

    test('playing 时：回到 idle 并停掉时间源', () async {
      await playFirst();
      ticker.tick();

      await service.stop();

      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('paused 时：回到 idle，之后 resume 不再生效', () async {
      await pauseFirstAfterTwoTicks();

      await service.stop();
      expect(await currentState(), const PlaybackState.idle());

      await service.resume();
      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });
  });

  group('这一句自然播完', () {
    test('每过一个间隔，句内位置向前推进一格', () async {
      await playFirst();

      ticker.tick(times: 3);

      expect(await currentState(), stateOfFirst(position: tickInterval * 3));
    });

    test('playing 时：到时长即回到 idle 并停掉时间源', () async {
      await playFirst();

      ticker.tick(times: 4);
      expect((await currentState()).status, PlaybackStatus.playing);

      ticker.tick();
      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('播完后不会接着播别的句子，再过多久都保持 idle', () async {
      await playFirst();
      ticker.tick(times: 5);
      final countAfterFinish = await emittedStateCount();

      ticker.tick(times: 20);

      expect(await currentState(), const PlaybackState.idle());
      expect(await emittedStateCount(), countAfterFinish);
    });

    test('暂停后恢复，播满剩余时长才结束', () async {
      await pauseFirstAfterTwoTicks();
      await service.resume();

      ticker.tick(times: 2);
      expect((await currentState()).status, PlaybackStatus.playing);

      ticker.tick();
      expect(await currentState(), const PlaybackState.idle());
    });
  });

  group('被打断的旧句子不再发出任何状态', () {
    test('被新的 play 打断后，旧句子迟到的进度不影响新句子', () async {
      await playFirst();
      ticker.tick(times: 2);
      await playSecond();
      final countBefore = await emittedStateCount();

      ticker.fireStaleCallbacks();

      expect(await currentState(), playingSecondFromStart());
      expect(await emittedStateCount(), countBefore);
    });

    test('被新的 play 打断后，旧句子迟到的「播完」不会让新句子停止', () async {
      await playFirst();
      ticker.tick(times: 4);
      await playSecond();

      ticker.fireStaleCallbacks();
      ticker.fireStaleCallbacks();

      expect(await currentState(), playingSecondFromStart());
      expect(ticker.isRunning, isTrue);
    });

    test('被 stop 打断后，迟到的计时不会让状态离开 idle', () async {
      await playFirst();
      ticker.tick();
      await service.stop();
      final countBefore = await emittedStateCount();

      ticker.fireStaleCallbacks();

      expect(await currentState(), const PlaybackState.idle());
      expect(await emittedStateCount(), countBefore);
    });

    test('暂停期间迟到的计时不会推进位置', () async {
      await pauseFirstAfterTwoTicks();
      final stateBefore = await currentState();

      ticker.fireStaleCallbacks();

      expect(await currentState(), stateBefore);
    });

    test('恢复播放后，暂停前那一轮迟到的计时不会让位置多走一格', () async {
      await pauseFirstAfterTwoTicks();
      await service.resume();

      ticker.fireStaleCallbacks();

      expect(await currentState(), stateOfFirst(position: tickInterval * 2));
    });
  });

  group('状态流', () {
    test('后来的订阅者一订阅就收到当前状态', () async {
      await playFirst();
      ticker.tick();

      expect(
        await service.watchState().first,
        stateOfFirst(position: tickInterval),
      );
    });

    test('订阅者依次收到每一次状态变化', () async {
      await playFirst();
      ticker.tick();
      await service.pause();
      await service.resume();
      await service.stop();
      await pumpEventQueue();

      expect(emittedStates, [
        const PlaybackState.idle(),
        stateOfFirst(),
        stateOfFirst(position: tickInterval),
        stateOfFirst(status: PlaybackStatus.paused, position: tickInterval),
        stateOfFirst(position: tickInterval),
        const PlaybackState.idle(),
      ]);
    });
  });
}

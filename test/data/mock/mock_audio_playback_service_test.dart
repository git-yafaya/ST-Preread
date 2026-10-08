import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/mock_playback_timing.dart';
import 'package:st_preread/core/errors/domain_exceptions.dart';
import 'package:st_preread/data/mock/mock_audio_playback_service.dart';
import 'package:st_preread/domain/domain.dart';

import '../../support/chapter_fixtures.dart';
import '../../support/manual_playback_ticker.dart';

void main() {
  const tickInterval = MockPlaybackTiming.tickInterval;
  final sentenceDuration =
      MockPlaybackTiming.durationPerCharacter * fixtureSentenceLength;
  final ticksPerSentence =
      (sentenceDuration.inMicroseconds / tickInterval.inMicroseconds).ceil();

  // 译文一面的播放队列依次是下面三句；中间隔着一句无语音的句子和一个插图块。
  final chapter = buildChapterFixture([
    buildParagraphFixture(
      id: 'first',
      sourceAudio: [true],
      translationAudio: [true, false, true],
    ),
    const IllustrationBlock(id: 'image', imagePath: 'a.png', caption: null),
    buildParagraphFixture(id: 'last', translationAudio: [true]),
  ]);
  const firstSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.translation,
    sentenceIndex: 0,
  );
  const secondSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.translation,
    sentenceIndex: 2,
  );
  const lastSentence = SentenceRef(
    blockIndex: 2,
    side: TextSide.translation,
    sentenceIndex: 0,
  );
  const silentSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.translation,
    sentenceIndex: 1,
  );
  const otherSideSentence = SentenceRef(
    blockIndex: 0,
    side: TextSide.source,
    sentenceIndex: 0,
  );

  late ManualPlaybackTicker ticker;
  late MockAudioPlaybackService service;

  Future<PlaybackState> currentState() => service.watchState().first;

  PlaybackState stateAt(
    SentenceRef sentence, {
    PlaybackStatus status = PlaybackStatus.playing,
    Duration position = Duration.zero,
  }) {
    return PlaybackState(
      status: status,
      sentence: sentence,
      position: position,
      duration: sentenceDuration,
    );
  }

  setUp(() async {
    ticker = ManualPlaybackTicker();
    service = MockAudioPlaybackService(ticker: ticker);
    addTearDown(service.dispose);
    await service.loadChapter(chapter, TextSide.translation);
  });

  group('初始与起播', () {
    test('加载章节后处于 idle，时间源未启动', () async {
      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('playFrom 从指定句的开头开始播放，时长按句长推算', () async {
      await service.playFrom(secondSentence);

      expect(await currentState(), stateAt(secondSentence));
      expect(ticker.isRunning, isTrue);
      expect(ticker.lastInterval, tickInterval);
    });

    test('playFrom 传入无语音的句子时抛 SentenceNotPlayableException', () async {
      await expectLater(
        service.playFrom(silentSentence),
        throwsA(
          isA<SentenceNotPlayableException>().having(
            (exception) => exception.sentence,
            'sentence',
            silentSentence,
          ),
        ),
      );
      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('playFrom 传入另一面的句子时抛 SentenceNotPlayableException', () async {
      await expectLater(
        service.playFrom(otherSideSentence),
        throwsA(isA<SentenceNotPlayableException>()),
      );
      expect(await currentState(), const PlaybackState.idle());
    });

    test('尚未加载章节时 playFrom 抛 SentenceNotPlayableException', () async {
      final emptyService = MockAudioPlaybackService(
        ticker: ManualPlaybackTicker(),
      );
      addTearDown(emptyService.dispose);

      await expectLater(
        emptyService.playFrom(firstSentence),
        throwsA(isA<SentenceNotPlayableException>()),
      );
    });

    test('playFrom 失败不打断正在进行的播放', () async {
      await service.playFrom(firstSentence);
      ticker.tick();

      await expectLater(
        service.playFrom(silentSentence),
        throwsA(isA<SentenceNotPlayableException>()),
      );

      expect(
        await currentState(),
        stateAt(firstSentence, position: tickInterval),
      );
      expect(ticker.isRunning, isTrue);
    });
  });

  group('逐句推进', () {
    test('每个间隔把句内位置向前推进一格', () async {
      await service.playFrom(firstSentence);

      ticker.tick(times: 2);

      expect(
        await currentState(),
        stateAt(firstSentence, position: tickInterval * 2),
      );
    });

    test('一句播完后自动进入队列中的下一句，跳过无语音的句子', () async {
      await service.playFrom(firstSentence);

      ticker.tick(times: ticksPerSentence - 1);
      expect((await currentState()).sentence, firstSentence);

      ticker.tick();
      expect(await currentState(), stateAt(secondSentence));
    });

    test('推进时跨过插图块进入后面的段落', () async {
      await service.playFrom(secondSentence);

      ticker.tick(times: ticksPerSentence);

      expect(await currentState(), stateAt(lastSentence));
    });

    test('播完队列最后一句后回到 idle 并停掉时间源', () async {
      await service.playFrom(lastSentence);

      ticker.tick(times: ticksPerSentence);

      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('从头播到章末，依次经过队列中的每一句后停止', () async {
      final playedSentences = <SentenceRef?>[];
      final subscription = service.watchState().listen((state) {
        if (playedSentences.isEmpty || playedSentences.last != state.sentence) {
          playedSentences.add(state.sentence);
        }
      });
      addTearDown(subscription.cancel);

      await service.playFrom(firstSentence);
      ticker.tick(times: ticksPerSentence * 3);
      await pumpEventQueue();

      expect(playedSentences, [
        null,
        firstSentence,
        secondSentence,
        lastSentence,
        null,
      ]);
    });
  });

  group('暂停与恢复', () {
    test('暂停后保留句子与位置，时间流逝不再推进', () async {
      await service.playFrom(firstSentence);
      ticker.tick(times: 2);

      await service.pause();
      ticker.tick(times: ticksPerSentence);

      expect(
        await currentState(),
        stateAt(
          firstSentence,
          status: PlaybackStatus.paused,
          position: tickInterval * 2,
        ),
      );
      expect(ticker.isRunning, isFalse);
    });

    test('恢复后从暂停的位置继续推进', () async {
      await service.playFrom(firstSentence);
      ticker.tick(times: 2);
      await service.pause();

      await service.resume();
      expect(
        await currentState(),
        stateAt(firstSentence, position: tickInterval * 2),
      );

      ticker.tick();
      expect(
        await currentState(),
        stateAt(firstSentence, position: tickInterval * 3),
      );
    });

    test('idle 时 resume 不做任何事', () async {
      await service.resume();

      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('正在播放时 resume 不改变状态', () async {
      await service.playFrom(firstSentence);
      ticker.tick();

      await service.resume();

      expect(
        await currentState(),
        stateAt(firstSentence, position: tickInterval),
      );
    });

    test('idle 或已暂停时 pause 不改变状态', () async {
      await service.pause();
      expect(await currentState(), const PlaybackState.idle());

      await service.playFrom(firstSentence);
      await service.pause();
      await service.pause();
      expect(
        await currentState(),
        stateAt(firstSentence, status: PlaybackStatus.paused),
      );
    });
  });

  group('上一句与下一句', () {
    test('播放中跳到下一句：从该句开头继续播放', () async {
      await service.playFrom(firstSentence);
      ticker.tick(times: 2);

      await service.skipToNextSentence();

      expect(await currentState(), stateAt(secondSentence));
      expect(ticker.isRunning, isTrue);
    });

    test('暂停中跳到下一句：停在该句开头并保持暂停', () async {
      await service.playFrom(firstSentence);
      await service.pause();

      await service.skipToNextSentence();

      expect(
        await currentState(),
        stateAt(secondSentence, status: PlaybackStatus.paused),
      );
      expect(ticker.isRunning, isFalse);
    });

    test('已是最后一句时跳到下一句：停止并回到 idle', () async {
      await service.playFrom(lastSentence);

      await service.skipToNextSentence();

      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('跳到上一句：从上一句的开头播放', () async {
      await service.playFrom(lastSentence);
      ticker.tick(times: 2);

      await service.skipToPreviousSentence();

      expect(await currentState(), stateAt(secondSentence));
    });

    test('已是第一句时跳到上一句：从该句开头重播', () async {
      await service.playFrom(firstSentence);
      ticker.tick(times: 2);

      await service.skipToPreviousSentence();

      expect(await currentState(), stateAt(firstSentence));
      expect(ticker.isRunning, isTrue);
    });

    test('暂停中跳到上一句：保持暂停', () async {
      await service.playFrom(secondSentence);
      await service.pause();

      await service.skipToPreviousSentence();

      expect(
        await currentState(),
        stateAt(firstSentence, status: PlaybackStatus.paused),
      );
    });

    test('idle 时上一句、下一句都不做任何事', () async {
      await service.skipToNextSentence();
      await service.skipToPreviousSentence();

      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });
  });

  group('停止与换章', () {
    test('stop 回到 idle 并停掉时间源', () async {
      await service.playFrom(firstSentence);
      ticker.tick();

      await service.stop();

      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
    });

    test('暂停中 stop 之后不能再 resume', () async {
      await service.playFrom(firstSentence);
      await service.pause();
      await service.stop();

      await service.resume();

      expect(await currentState(), const PlaybackState.idle());
    });

    test('播放中加载新章节会停止播放并换用新的队列', () async {
      await service.playFrom(firstSentence);

      await service.loadChapter(chapter, TextSide.source);

      expect(await currentState(), const PlaybackState.idle());
      expect(ticker.isRunning, isFalse);
      await expectLater(
        service.playFrom(firstSentence),
        throwsA(isA<SentenceNotPlayableException>()),
      );
      await service.playFrom(otherSideSentence);
      expect(await currentState(), stateAt(otherSideSentence));
    });

    test('加载没有任何语音的一面后任何句子都不可播', () async {
      final unvoicedChapter = buildChapterFixture([
        buildParagraphFixture(translationAudio: [false, false]),
      ]);

      await service.loadChapter(unvoicedChapter, TextSide.translation);

      await expectLater(
        service.playFrom(firstSentence),
        throwsA(isA<SentenceNotPlayableException>()),
      );
    });
  });

  group('状态流', () {
    test('订阅者先收到当前状态，再依次收到每次变化', () async {
      await service.playFrom(firstSentence);
      final received = <PlaybackState>[];
      final subscription = service.watchState().listen(received.add);
      addTearDown(subscription.cancel);

      ticker.tick();
      await service.pause();
      await pumpEventQueue();

      expect(received, [
        stateAt(firstSentence),
        stateAt(firstSentence, position: tickInterval),
        stateAt(
          firstSentence,
          status: PlaybackStatus.paused,
          position: tickInterval,
        ),
      ]);
    });

    test('时长随句子长度变化', () async {
      const longSentenceLength = fixtureSentenceLength * 3;
      final longChapter = buildChapterFixture([
        buildParagraphFixture(
          translationAudio: [true],
          sentenceLength: longSentenceLength,
        ),
      ]);
      await service.loadChapter(longChapter, TextSide.translation);

      await service.playFrom(firstSentence);

      expect(
        (await currentState()).duration,
        MockPlaybackTiming.durationPerCharacter * longSentenceLength,
      );
    });
  });
}

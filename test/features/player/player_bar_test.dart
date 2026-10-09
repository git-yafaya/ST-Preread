import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/player_layout_constants.dart';
import 'package:st_preread/core/constants/player_strings.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/data/mock/mock_audio_playback_service.dart';
import 'package:st_preread/data/mock/mock_playback_timing.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/player/player_bar.dart';

import '../../support/manual_playback_ticker.dart';
import 'recording_playback_service.dart';

void main() {
  const sentence = SentenceRef(
    blockIndex: 2,
    side: TextSide.translation,
    sentenceIndex: 0,
  );
  const tickInterval = MockPlaybackTiming.tickInterval;
  const clipTickCount = 8;
  final clip = AudioClip(
    filePath: 'voice.mp3',
    start: null,
    end: tickInterval * clipTickCount,
  );

  final pauseButton = find.byTooltip(PlayerStrings.pauseTooltip);
  final resumeButton = find.byTooltip(PlayerStrings.resumeTooltip);
  final stopButton = find.byTooltip(PlayerStrings.stopTooltip);
  final progressIndicator = find.byType(LinearProgressIndicator);

  /// 把播放条放在一列的底部，模拟阅读页里「正文在上、播放条在下」的摆法。
  Future<void> pumpPlayerBar(
    WidgetTester tester,
    AudioPlaybackService service,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioPlaybackServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: SizedBox.expand()),
                PlayerBar(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 播放条在纵向上占掉的高度；为 0 即不占位。
  double barHeight(WidgetTester tester) {
    return tester.getSize(find.byType(PlayerBar)).height;
  }

  /// 播放服务最新发出的状态，取自播放条自己订阅的那一份。
  PlaybackStatus? serviceStatus(WidgetTester tester) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerBar)),
    );
    return container.read(playbackStateProvider).value?.status;
  }

  double? shownProgress(WidgetTester tester) {
    return tester.widget<LinearProgressIndicator>(progressIndicator).value;
  }

  PlaybackState stateWith({
    required PlaybackStatus status,
    Duration position = Duration.zero,
    Duration? duration,
  }) {
    return PlaybackState(
      status: status,
      sentence: sentence,
      position: position,
      duration: duration,
    );
  }

  group('配合假播放器', () {
    late ManualPlaybackTicker ticker;
    late MockAudioPlaybackService service;

    setUp(() {
      ticker = ManualPlaybackTicker();
      service = MockAudioPlaybackService(ticker: ticker);
      addTearDown(service.dispose);
    });

    testWidgets('idle 时不显示任何内容，也不占位', (tester) async {
      await pumpPlayerBar(tester, service);

      expect(pauseButton, findsNothing);
      expect(resumeButton, findsNothing);
      expect(stopButton, findsNothing);
      expect(progressIndicator, findsNothing);
      expect(barHeight(tester), 0);
    });

    testWidgets('开始播放后出现，带暂停与停止按钮和从零开始的进度', (tester) async {
      await pumpPlayerBar(tester, service);

      await service.play(sentence: sentence, clip: clip);
      await tester.pumpAndSettle();

      expect(pauseButton, findsOneWidget);
      expect(stopButton, findsOneWidget);
      expect(resumeButton, findsNothing);
      expect(shownProgress(tester), 0.0);
      expect(barHeight(tester), greaterThan(0));
    });

    testWidgets('出现时有过渡：高度逐渐展开而不是一步到位', (tester) async {
      const framesPerTransition = 10;
      final frameInterval =
          PlayerLayoutConstants.visibilityTransitionDuration ~/
          framesPerTransition;
      await pumpPlayerBar(tester, service);
      await service.play(sentence: sentence, clip: clip);

      final heightsDuringTransition = <double>[];
      for (var frame = 0; frame < framesPerTransition * 2; frame++) {
        await tester.pump(frameInterval);
        heightsDuringTransition.add(barHeight(tester));
      }
      final settledHeight = barHeight(tester);

      expect(settledHeight, greaterThan(0));
      expect(
        heightsDuringTransition.where(
          (height) => height > 0 && height < settledHeight,
        ),
        isNotEmpty,
      );
    });

    testWidgets('播放推进时进度随之更新', (tester) async {
      await pumpPlayerBar(tester, service);
      await service.play(sentence: sentence, clip: clip);

      ticker.tick(times: 2);
      await tester.pumpAndSettle();

      expect(shownProgress(tester), closeTo(2 / clipTickCount, 1e-9));
    });

    testWidgets('点暂停后服务进入暂停，按钮换成继续，进度保留', (tester) async {
      await pumpPlayerBar(tester, service);
      await service.play(sentence: sentence, clip: clip);
      ticker.tick(times: 2);
      await tester.pumpAndSettle();

      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      expect(serviceStatus(tester), PlaybackStatus.paused);
      expect(resumeButton, findsOneWidget);
      expect(pauseButton, findsNothing);
      expect(stopButton, findsOneWidget);
      expect(shownProgress(tester), closeTo(2 / clipTickCount, 1e-9));
    });

    testWidgets('暂停时点继续，服务恢复播放，按钮换回暂停', (tester) async {
      await pumpPlayerBar(tester, service);
      await service.play(sentence: sentence, clip: clip);
      await service.pause();
      await tester.pumpAndSettle();

      await tester.tap(resumeButton);
      await tester.pumpAndSettle();

      expect(serviceStatus(tester), PlaybackStatus.playing);
      expect(pauseButton, findsOneWidget);
      expect(resumeButton, findsNothing);
    });

    testWidgets('点停止后服务回到 idle，播放条消失且不再占位', (tester) async {
      await pumpPlayerBar(tester, service);
      await service.play(sentence: sentence, clip: clip);
      await tester.pumpAndSettle();

      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      expect(serviceStatus(tester), PlaybackStatus.idle);
      expect(stopButton, findsNothing);
      expect(barHeight(tester), 0);
    });

    testWidgets('暂停时也能停止', (tester) async {
      await pumpPlayerBar(tester, service);
      await service.play(sentence: sentence, clip: clip);
      await service.pause();
      await tester.pumpAndSettle();

      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      expect(serviceStatus(tester), PlaybackStatus.idle);
      expect(barHeight(tester), 0);
    });

    testWidgets('这一句自然播完后播放条消失', (tester) async {
      await pumpPlayerBar(tester, service);
      await service.play(sentence: sentence, clip: clip);
      await tester.pumpAndSettle();

      ticker.tick(times: clipTickCount);
      await tester.pumpAndSettle();

      expect(pauseButton, findsNothing);
      expect(barHeight(tester), 0);
    });
  });

  group('配合可指定状态的播放服务', () {
    late RecordingPlaybackService service;

    RecordingPlaybackService createService({PlaybackState? initialState}) {
      final createdService = RecordingPlaybackService(
        initialState: initialState,
      );
      addTearDown(createdService.dispose);
      return createdService;
    }

    testWidgets('还没收到任何播放状态时不显示', (tester) async {
      service = createService();

      await pumpPlayerBar(tester, service);

      expect(stopButton, findsNothing);
      expect(barHeight(tester), 0);
    });

    testWidgets('显示已播时间与总时长', (tester) async {
      service = createService(
        initialState: stateWith(
          status: PlaybackStatus.playing,
          position: const Duration(seconds: 3),
          duration: const Duration(seconds: 12),
        ),
      );

      await pumpPlayerBar(tester, service);

      expect(find.text('0:03 / 0:12'), findsOneWidget);
      expect(shownProgress(tester), 0.25);
    });

    testWidgets('时长未知时不显示进度条，只显示已播时间', (tester) async {
      service = createService(
        initialState: stateWith(
          status: PlaybackStatus.playing,
          position: const Duration(seconds: 3),
          duration: null,
        ),
      );

      await pumpPlayerBar(tester, service);

      expect(progressIndicator, findsNothing);
      expect(find.text('0:03'), findsOneWidget);
      expect(pauseButton, findsOneWidget);
      expect(stopButton, findsOneWidget);
    });

    testWidgets('时长未知时暂停，同样只显示已播时间与继续、停止按钮', (tester) async {
      service = createService(
        initialState: stateWith(
          status: PlaybackStatus.paused,
          position: const Duration(seconds: 3),
          duration: null,
        ),
      );

      await pumpPlayerBar(tester, service);

      expect(progressIndicator, findsNothing);
      expect(find.text('0:03'), findsOneWidget);
      expect(resumeButton, findsOneWidget);
      expect(stopButton, findsOneWidget);
    });

    testWidgets('播放中的两个按钮分别只调用 pause 与 stop', (tester) async {
      service = createService(
        initialState: stateWith(
          status: PlaybackStatus.playing,
          duration: const Duration(seconds: 12),
        ),
      );
      await pumpPlayerBar(tester, service);

      await tester.tap(pauseButton);
      await tester.tap(stopButton);

      expect(service.controlCalls, ['pause', 'stop']);
    });

    testWidgets('暂停时的两个按钮分别只调用 resume 与 stop', (tester) async {
      service = createService(
        initialState: stateWith(
          status: PlaybackStatus.paused,
          duration: const Duration(seconds: 12),
        ),
      );
      await pumpPlayerBar(tester, service);

      await tester.tap(resumeButton);
      await tester.tap(stopButton);

      expect(service.controlCalls, ['resume', 'stop']);
    });

    testWidgets('进度条带有语义标签与百分比', (tester) async {
      service = createService(
        initialState: stateWith(
          status: PlaybackStatus.playing,
          position: const Duration(seconds: 3),
          duration: const Duration(seconds: 12),
        ),
      );

      await pumpPlayerBar(tester, service);

      final indicator = tester.widget<LinearProgressIndicator>(
        progressIndicator,
      );
      expect(indicator.semanticsLabel, PlayerStrings.progressSemanticsLabel);
      expect(indicator.semanticsValue, '25%');
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/data/mock/mock_audio_playback_service.dart';
import 'package:st_preread/data/mock/mock_reader_settings_repository.dart';
import 'package:st_preread/domain/domain.dart';

import '../../support/manual_playback_ticker.dart';

void main() {
  /// Riverpod 会把 provider 构建时抛出的错误包一层再抛出，这里取出原始错误。
  Object? readFailureOf(
    ProviderContainer container,
    Provider<Object> provider,
  ) {
    try {
      container.read(provider);
    } on ProviderException catch (wrapped) {
      return wrapped.exception;
    } on Object catch (error) {
      return error;
    }
    return null;
  }

  group('未绑定的 provider', () {
    final unboundProviders = <String, Provider<Object>>{
      'bookRepositoryProvider': bookRepositoryProvider,
      'readingProgressRepositoryProvider': readingProgressRepositoryProvider,
      'readerSettingsRepositoryProvider': readerSettingsRepositoryProvider,
      'audioPlaybackServiceProvider': audioPlaybackServiceProvider,
    };

    for (final MapEntry(key: providerName, value: provider)
        in unboundProviders.entries) {
      test('$providerName 被读取时抛出带名字的 UnboundProviderError', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final failure = readFailureOf(container, provider);

        expect(failure, isA<UnboundProviderError>());
        expect(failure.toString(), contains(providerName));
      });
    }
  });

  group('共享的派生流', () {
    test('readerSettingsProvider 跟随设置仓库', () async {
      final repository = MockReaderSettingsRepository(
        initialSettings: defaultReaderSettings,
      );
      final container = ProviderContainer(
        overrides: [
          readerSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(readerSettingsProvider, (_, _) {});
      addTearDown(subscription.close);

      expect(
        await container.read(readerSettingsProvider.future),
        defaultReaderSettings,
      );

      final darkSettings = defaultReaderSettings.copyWith(
        themeMode: ReaderThemeMode.dark,
      );
      await repository.saveSettings(darkSettings);
      await pumpEventQueue();

      expect(container.read(readerSettingsProvider).value, darkSettings);
    });

    test('playbackStateProvider 跟随播放服务的每一次状态变化', () async {
      const sentence = SentenceRef(
        blockIndex: 1,
        side: TextSide.translation,
        sentenceIndex: 0,
      );
      const clipDuration = Duration(seconds: 1);
      const clip = AudioClip(filePath: 'a.mp3', start: null, end: clipDuration);
      final service = MockAudioPlaybackService(ticker: ManualPlaybackTicker());
      addTearDown(service.dispose);
      final container = ProviderContainer(
        overrides: [audioPlaybackServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(playbackStateProvider, (_, _) {});
      addTearDown(subscription.close);

      PlaybackState? providedState() {
        return container.read(playbackStateProvider).value;
      }

      expect(
        await container.read(playbackStateProvider.future),
        const PlaybackState.idle(),
      );

      await service.play(sentence: sentence, clip: clip);
      await pumpEventQueue();
      expect(providedState()?.status, PlaybackStatus.playing);
      expect(providedState()?.sentence, sentence);
      expect(providedState()?.duration, clipDuration);

      await service.pause();
      await pumpEventQueue();
      expect(providedState()?.status, PlaybackStatus.paused);
      expect(providedState()?.sentence, sentence);

      await service.stop();
      await pumpEventQueue();
      expect(providedState(), const PlaybackState.idle());
    });
  });
}

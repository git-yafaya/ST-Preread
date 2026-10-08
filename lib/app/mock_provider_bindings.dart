import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/constants/reader_setting_defaults.dart';
import '../core/providers/providers.dart';
import '../data/mock/mock_audio_playback_service.dart';
import '../data/mock/mock_book_repository.dart';
import '../data/mock/mock_reader_settings_repository.dart';
import '../data/mock/mock_reading_progress_repository.dart';

/// 把 core 中声明的 provider 绑定到内存假实现。
///
/// 这是全应用唯一 import data/ 的地方：接入真实实现时只需替换这份绑定。
List<Override> buildMockProviderBindings() {
  return [
    bookRepositoryProvider.overrideWith((ref) {
      final repository = MockBookRepository();
      ref.onDispose(repository.dispose);
      return repository;
    }),
    readingProgressRepositoryProvider.overrideWith(
      (ref) => MockReadingProgressRepository(),
    ),
    readerSettingsRepositoryProvider.overrideWith((ref) {
      final repository = MockReaderSettingsRepository(
        initialSettings: defaultReaderSettings,
      );
      ref.onDispose(repository.dispose);
      return repository;
    }),
    audioPlaybackServiceProvider.overrideWith((ref) {
      final service = MockAudioPlaybackService();
      ref.onDispose(service.dispose);
      return service;
    }),
  ];
}

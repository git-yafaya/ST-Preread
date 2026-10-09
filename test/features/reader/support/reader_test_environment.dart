import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:st_preread/core/constants/reader_setting_defaults.dart';
import 'package:st_preread/core/providers/providers.dart';
import 'package:st_preread/data/mock/mock_reader_settings_repository.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/logic/reader_controller.dart';

import 'reader_fakes.dart';
import 'reader_fixtures.dart';

/// 阅读页测试用的一整套依赖：仓库、播放服务、延时调度都是可观察、可操控的假实现。
class ReaderTestEnvironment {
  ReaderTestEnvironment({
    required List<Chapter> chapters,
    ReaderSettings settings = defaultReaderSettings,
    ReadingPosition? savedPosition,
  }) : _settings = settings,
       progressRepository = RecordingProgressRepository(
         savedPosition: savedPosition,
       ),
       settingsRepository = MockReaderSettingsRepository(
         initialSettings: settings,
       ) {
    bookRepository = FakeBookRepository(
      bookId: fixtureBookId,
      chapters: chapters,
      log: log,
    );
    playbackService = RecordingPlaybackService(log: log);
  }

  /// 书籍仓库与播放服务共用的调用记录，用来断言先后顺序。
  final List<String> log = [];

  late final FakeBookRepository bookRepository;
  late final RecordingPlaybackService playbackService;
  final RecordingProgressRepository progressRepository;
  final MockReaderSettingsRepository settingsRepository;
  final ManualDelayedCallScheduler scheduler = ManualDelayedCallScheduler();

  ReaderSettings _settings;

  List<Override> get overrides => [
    bookRepositoryProvider.overrideWithValue(bookRepository),
    readingProgressRepositoryProvider.overrideWithValue(progressRepository),
    readerSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    audioPlaybackServiceProvider.overrideWithValue(playbackService),
    progressSaveSchedulerProvider.overrideWithValue(scheduler.schedule),
  ];

  /// 在当前设置的基础上修改并保存，返回新设置。
  Future<ReaderSettings> updateSettings(
    ReaderSettings Function(ReaderSettings current) update,
  ) async {
    _settings = update(_settings);
    await settingsRepository.saveSettings(_settings);
    return _settings;
  }

  Future<void> dispose() async {
    await settingsRepository.dispose();
    await playbackService.dispose();
  }
}

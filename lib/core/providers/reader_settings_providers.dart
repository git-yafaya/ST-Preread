import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import 'unbound_provider_error.dart';

final readerSettingsRepositoryProvider = Provider<ReaderSettingsRepository>(
  (ref) => throw UnboundProviderError('readerSettingsRepositoryProvider'),
);

/// 当前阅读设置。应用主题、阅读页、设置面板共用这一份订阅，
/// 避免各自监听仓库而出现短暂不一致。
final readerSettingsProvider = StreamProvider<ReaderSettings>(
  (ref) => ref.watch(readerSettingsRepositoryProvider).watchSettings(),
);

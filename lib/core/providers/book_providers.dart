import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import 'unbound_provider_error.dart';

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => throw UnboundProviderError('bookRepositoryProvider'),
);

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>(
  (ref) => throw UnboundProviderError('readingProgressRepositoryProvider'),
);

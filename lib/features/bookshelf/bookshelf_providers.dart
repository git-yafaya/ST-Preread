import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../domain/domain.dart';

/// 书架上的全部书籍，顺序由书库决定。
///
/// 关闭自动重试：读取失败后由用户在出错界面上决定何时再试。
/// 自动重试会让界面在「出错」与「加载中」之间自行跳动，用户无从判断当前状态。
final bookshelfBooksProvider = StreamProvider<List<Book>>(
  (ref) => ref.watch(bookRepositoryProvider).watchBooks(),
  retry: _neverRetry,
);

Duration? _neverRetry(int retryCount, Object error) => null;

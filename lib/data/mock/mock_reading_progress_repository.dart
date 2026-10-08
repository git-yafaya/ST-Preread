import '../../domain/domain.dart';

/// 只在内存里记住进度的假实现：本次运行内有效，重启后清空。
class MockReadingProgressRepository implements ReadingProgressRepository {
  final Map<String, ReadingPosition> _positionsByBookId = {};

  @override
  Future<ReadingPosition?> loadPosition(String bookId) async {
    return _positionsByBookId[bookId];
  }

  @override
  Future<void> savePosition(ReadingPosition position) async {
    _positionsByBookId[position.bookId] = position;
  }
}

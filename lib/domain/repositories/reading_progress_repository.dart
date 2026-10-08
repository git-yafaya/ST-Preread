import '../entities/reading_position.dart';

/// 每本书的阅读进度。
abstract interface class ReadingProgressRepository {
  /// 这本书还没有保存过进度时返回 null。
  Future<ReadingPosition?> loadPosition(String bookId);

  Future<void> savePosition(ReadingPosition position);
}

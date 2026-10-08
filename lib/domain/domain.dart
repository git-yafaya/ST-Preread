/// 领域层的统一出口，其他层只需 import 这一个文件。
library;

export 'entities/audio_clip.dart';
export 'entities/book.dart';
export 'entities/chapter.dart';
export 'entities/chapter_summary.dart';
export 'entities/content_block.dart';
export 'entities/inline_style_span.dart';
export 'entities/nullable_value_getter.dart';
export 'entities/reader_settings.dart';
export 'entities/reading_position.dart';
export 'entities/sentence.dart';
export 'entities/sentence_ref.dart';
export 'entities/sided_text.dart';
export 'entities/text_side.dart';
export 'repositories/book_repository.dart';
export 'repositories/reader_settings_repository.dart';
export 'repositories/reading_progress_repository.dart';
export 'services/audio_playback_service.dart';
export 'services/bilingual_rules.dart';

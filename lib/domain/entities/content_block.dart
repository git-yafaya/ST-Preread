import 'nullable_value_getter.dart';
import 'sided_text.dart';
import 'text_side.dart';

/// 正文由「块」顺序组成，块是阅读定位与插图锚定的最小单位。
sealed class ContentBlock {
  const ContentBlock({required this.id});

  final String id;
}

/// 一个段落。[source] 与 [translation] 至少有一面非空。
final class ParagraphBlock extends ContentBlock {
  const ParagraphBlock({
    required super.id,
    required this.source,
    required this.translation,
  }) : assert(source != null || translation != null, '段落至少要有一面文字');

  final SidedText? source;
  final SidedText? translation;

  /// 取某一面的文字；这一面不存在时返回 null。
  SidedText? textOf(TextSide side) {
    return switch (side) {
      TextSide.source => source,
      TextSide.translation => translation,
    };
  }

  ParagraphBlock copyWith({
    String? id,
    NullableValueGetter<SidedText>? source,
    NullableValueGetter<SidedText>? translation,
  }) {
    return ParagraphBlock(
      id: id ?? this.id,
      source: source == null ? this.source : source(),
      translation: translation == null ? this.translation : translation(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ParagraphBlock &&
        other.id == id &&
        other.source == source &&
        other.translation == translation;
  }

  @override
  int get hashCode => Object.hash(id, source, translation);

  @override
  String toString() =>
      'ParagraphBlock(id: $id, hasSource: ${source != null}, '
      'hasTranslation: ${translation != null})';
}

/// 内嵌在正文中的一张插图。
final class IllustrationBlock extends ContentBlock {
  const IllustrationBlock({
    required super.id,
    required this.imagePath,
    required this.caption,
  });

  /// 本地路径。
  final String imagePath;
  final String? caption;

  IllustrationBlock copyWith({
    String? id,
    String? imagePath,
    NullableValueGetter<String>? caption,
  }) {
    return IllustrationBlock(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      caption: caption == null ? this.caption : caption(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IllustrationBlock &&
        other.id == id &&
        other.imagePath == imagePath &&
        other.caption == caption;
  }

  @override
  int get hashCode => Object.hash(id, imagePath, caption);

  @override
  String toString() => 'IllustrationBlock(id: $id, imagePath: $imagePath)';
}

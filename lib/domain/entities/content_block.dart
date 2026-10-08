import 'nullable_value_getter.dart';
import 'sided_text.dart';
import 'text_side.dart';

/// 正文由「块」顺序组成，块是阅读定位与插图锚定的最小单位。
sealed class ContentBlock {
  const ContentBlock({required this.id});

  final String id;
}

/// 段落的块级样式。Markdown 四级及更深的标题归入 [heading3]。
enum ParagraphStyle { body, heading1, heading2, heading3, quote }

/// 一个段落。[source] 与 [translation] 至少有一面非空。
final class ParagraphBlock extends ContentBlock {
  const ParagraphBlock({
    required super.id,
    required this.style,
    required this.source,
    required this.translation,
  }) : assert(source != null || translation != null, '段落至少要有一面文字');

  final ParagraphStyle style;
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
    ParagraphStyle? style,
    NullableValueGetter<SidedText>? source,
    NullableValueGetter<SidedText>? translation,
  }) {
    return ParagraphBlock(
      id: id ?? this.id,
      style: style ?? this.style,
      source: source == null ? this.source : source(),
      translation: translation == null ? this.translation : translation(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ParagraphBlock &&
        other.id == id &&
        other.style == style &&
        other.source == source &&
        other.translation == translation;
  }

  @override
  int get hashCode => Object.hash(id, style, source, translation);

  @override
  String toString() =>
      'ParagraphBlock(id: $id, style: ${style.name}, '
      'hasSource: ${source != null}, '
      'hasTranslation: ${translation != null})';
}

/// 分隔线（Markdown 的 `---`）。
final class DividerBlock extends ContentBlock {
  const DividerBlock({required super.id});

  DividerBlock copyWith({String? id}) => DividerBlock(id: id ?? this.id);

  @override
  bool operator ==(Object other) => other is DividerBlock && other.id == id;

  // 混入类型，避免与只有 id 相同的其他对象撞哈希。
  @override
  int get hashCode => Object.hash(DividerBlock, id);

  @override
  String toString() => 'DividerBlock(id: $id)';
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

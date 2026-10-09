import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/core/constants/bilingual_text_constants.dart';
import 'package:st_preread/core/constants/reader_text_style_constants.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';

void main() {
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
  );
  final textTheme = ReaderTextTheme.fromTheme(theme, fontScale: 1);

  TextSegment segment({
    Set<InlineStyle> styles = const {},
    bool isPlayable = false,
    SegmentHighlight highlight = SegmentHighlight.none,
  }) {
    return TextSegment(
      startOffset: 0,
      endOffset: 1,
      inlineStyles: styles,
      isPlayable: isPlayable,
      highlight: highlight,
    );
  }

  group('字号', () {
    test('正文字号跟随字号倍数', () {
      final enlarged = ReaderTextTheme.fromTheme(theme, fontScale: 1.5);

      expect(textTheme.bodyFontSize, ReaderTextStyleConstants.bodyFontSize);
      expect(
        enlarged.bodyFontSize,
        ReaderTextStyleConstants.bodyFontSize * 1.5,
      );
    });
  });

  group('blockStyleOf', () {
    test('主文正文使用正文字号与主题文字颜色', () {
      final style = textTheme.blockStyleOf(
        paragraphStyle: ParagraphStyle.body,
        role: TextRole.primary,
      );

      expect(style.fontSize, ReaderTextStyleConstants.bodyFontSize);
      expect(style.color, theme.colorScheme.onSurface);
      expect(style.height, ReaderTextStyleConstants.bodyLineHeight);
    });

    test('辅文按常量缩小字号并减淡颜色', () {
      final style = textTheme.blockStyleOf(
        paragraphStyle: ParagraphStyle.body,
        role: TextRole.secondary,
      );

      expect(
        style.fontSize,
        ReaderTextStyleConstants.bodyFontSize *
            BilingualTextConstants.secondaryTextFontScale,
      );
      expect(style.color, textTheme.secondaryTextColor);
      expect(style.color!.a, lessThan(theme.colorScheme.onSurface.a));
    });

    test('三级标题字号依次递减且都比正文大，并加粗', () {
      double fontSizeOf(ParagraphStyle paragraphStyle) {
        return textTheme
            .blockStyleOf(
              paragraphStyle: paragraphStyle,
              role: TextRole.primary,
            )
            .fontSize!;
      }

      expect(
        fontSizeOf(ParagraphStyle.heading1),
        greaterThan(fontSizeOf(ParagraphStyle.heading2)),
      );
      expect(
        fontSizeOf(ParagraphStyle.heading2),
        greaterThan(fontSizeOf(ParagraphStyle.heading3)),
      );
      expect(
        fontSizeOf(ParagraphStyle.heading3),
        greaterThan(fontSizeOf(ParagraphStyle.body)),
      );
      expect(
        textTheme
            .blockStyleOf(
              paragraphStyle: ParagraphStyle.heading2,
              role: TextRole.primary,
            )
            .fontWeight,
        FontWeight.bold,
      );
    });

    test('标题的辅文在标题字号的基础上缩小', () {
      final primary = textTheme.blockStyleOf(
        paragraphStyle: ParagraphStyle.heading1,
        role: TextRole.primary,
      );
      final secondary = textTheme.blockStyleOf(
        paragraphStyle: ParagraphStyle.heading1,
        role: TextRole.secondary,
      );

      expect(
        secondary.fontSize,
        closeTo(
          primary.fontSize! * BilingualTextConstants.secondaryTextFontScale,
          0.001,
        ),
      );
    });
  });

  group('segmentStyleOf', () {
    test('没有任何特殊样式的分段不需要额外样式', () {
      expect(textTheme.segmentStyleOf(segment()), isNull);
    });

    test('四种行内样式各有对应的呈现', () {
      final bold = textTheme.segmentStyleOf(
        segment(styles: {InlineStyle.bold}),
      )!;
      final italic = textTheme.segmentStyleOf(
        segment(styles: {InlineStyle.italic}),
      )!;
      final strikethrough = textTheme.segmentStyleOf(
        segment(styles: {InlineStyle.strikethrough}),
      )!;
      final code = textTheme.segmentStyleOf(
        segment(styles: {InlineStyle.code}),
      )!;

      expect(bold.fontWeight, FontWeight.bold);
      expect(italic.fontStyle, FontStyle.italic);
      expect(strikethrough.decoration, TextDecoration.lineThrough);
      expect(code.fontFamily, ReaderTextStyleConstants.inlineCodeFontFamily);
      expect(code.backgroundColor, textTheme.inlineCodeBackgroundColor);
    });

    test('粗斜体叠加时两种样式同时生效', () {
      final style = textTheme.segmentStyleOf(
        segment(styles: {InlineStyle.bold, InlineStyle.italic}),
      )!;

      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontStyle, FontStyle.italic);
    });

    test('带语音的句子加淡色下划线，颜色不同于文字本身', () {
      final style = textTheme.segmentStyleOf(segment(isPlayable: true))!;

      expect(style.decoration, TextDecoration.underline);
      expect(style.decorationColor, textTheme.playableUnderlineColor);
      expect(style.decorationColor, isNot(theme.colorScheme.onSurface));
      expect(style.decorationColor!.a, lessThan(1));
    });

    test('只有删除线时不带下划线，装饰线沿用文字颜色', () {
      final style = textTheme.segmentStyleOf(
        segment(styles: {InlineStyle.strikethrough}),
      )!;

      expect(style.decoration!.contains(TextDecoration.underline), isFalse);
      expect(style.decorationColor, isNull);
    });

    test('带语音的句子里有删除线时两条线都在，删除线保持文字颜色', () {
      final style = textTheme.segmentStyleOf(
        segment(styles: {InlineStyle.strikethrough}, isPlayable: true),
      )!;

      expect(style.decoration!.contains(TextDecoration.underline), isTrue);
      expect(style.decoration!.contains(TextDecoration.lineThrough), isTrue);
      expect(style.decorationColor, isNull);
    });

    test('被播的句子与另一面的整段高亮用不同深浅的底色', () {
      final active = textTheme.segmentStyleOf(
        segment(highlight: SegmentHighlight.activeSentence),
      )!;
      final companion = textTheme.segmentStyleOf(
        segment(highlight: SegmentHighlight.companion),
      )!;

      expect(active.backgroundColor, textTheme.activeSentenceHighlightColor);
      expect(companion.backgroundColor, textTheme.companionHighlightColor);
      expect(companion.backgroundColor!.a, lessThan(active.backgroundColor!.a));
    });

    test('播放高亮盖过行内代码的底色', () {
      final style = textTheme.segmentStyleOf(
        segment(
          styles: {InlineStyle.code},
          highlight: SegmentHighlight.activeSentence,
        ),
      )!;

      expect(style.backgroundColor, textTheme.activeSentenceHighlightColor);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';
import 'package:st_preread/features/reader/content/content.dart';

import '../support/reader_fixtures.dart';

void main() {
  TextSegment segment(
    int startOffset,
    int endOffset, {
    Set<InlineStyle> styles = const {},
    bool isPlayable = false,
    SegmentHighlight highlight = SegmentHighlight.none,
  }) {
    return TextSegment(
      startOffset: startOffset,
      endOffset: endOffset,
      inlineStyles: styles,
      isPlayable: isPlayable,
      highlight: highlight,
    );
  }

  List<TextSegment> segmentsOf(
    SidedText sidedText, {
    SideHighlight highlight = const NoSideHighlight(),
    int startOffset = 0,
    int? endOffset,
  }) {
    return buildTextSegments(
      sidedText: sidedText,
      highlight: highlight,
      startOffset: startOffset,
      endOffset: endOffset,
    );
  }

  group('buildTextSegments', () {
    test('空文字没有任何分段', () {
      expect(segmentsOf(buildPlainSidedText('')), isEmpty);
    });

    test('没有样式也没有句子时整面是一个分段', () {
      expect(segmentsOf(buildPlainSidedText('只有文字')), [segment(0, 4)]);
    });

    test('相邻的句子：带语音与不带语音在句界处分开，样式相同的相邻句子合并', () {
      final sidedText = buildSidedText(const [
        FixtureSentence.voiced('甲甲'),
        FixtureSentence.voiced('乙乙'),
        FixtureSentence('丙丙'),
        FixtureSentence('丁丁'),
      ]);

      expect(segmentsOf(sidedText), [
        segment(0, 4, isPlayable: true),
        segment(4, 8),
      ]);
    });

    test('嵌套样式合并在同一段里，样式集合不同的相邻区间各自成段', () {
      final sidedText = SidedText(
        text: '普通粗体粗斜普通',
        styleSpans: const [
          InlineStyleSpan(
            startOffset: 2,
            endOffset: 4,
            styles: {InlineStyle.bold},
          ),
          InlineStyleSpan(
            startOffset: 4,
            endOffset: 6,
            styles: {InlineStyle.bold, InlineStyle.italic},
          ),
        ],
        sentences: const [],
      );

      expect(segmentsOf(sidedText), [
        segment(0, 2),
        segment(2, 4, styles: {InlineStyle.bold}),
        segment(4, 6, styles: {InlineStyle.bold, InlineStyle.italic}),
        segment(6, 8),
      ]);
    });

    test('样式区间跨越句子边界时，在样式边界与句子边界处都切开', () {
      final sidedText = buildSidedText(
        const [FixtureSentence.voiced('甲甲甲甲甲甲'), FixtureSentence('乙乙乙乙乙乙')],
        styleSpans: const [
          InlineStyleSpan(
            startOffset: 3,
            endOffset: 9,
            styles: {InlineStyle.bold},
          ),
        ],
      );

      expect(segmentsOf(sidedText), [
        segment(0, 3, isPlayable: true),
        segment(3, 6, styles: {InlineStyle.bold}, isPlayable: true),
        segment(6, 9, styles: {InlineStyle.bold}),
        segment(9, 12),
      ]);
    });

    test('句间空隙不属于任何句子，不算可播', () {
      final sidedText = buildSidedText(const [
        FixtureSentence.voiced('甲甲甲？', gapAfter: '　'),
        FixtureSentence.voiced('乙乙乙。'),
      ]);

      expect(segmentsOf(sidedText), [
        segment(0, 4, isPlayable: true),
        segment(4, 5),
        segment(5, 9, isPlayable: true),
      ]);
    });

    test('切片落在区间中间时只输出切片内的部分，偏移仍相对完整文字', () {
      final sidedText = buildSidedText(
        const [FixtureSentence.voiced('甲甲甲甲'), FixtureSentence('乙乙乙乙')],
        styleSpans: const [
          InlineStyleSpan(
            startOffset: 1,
            endOffset: 7,
            styles: {InlineStyle.italic},
          ),
        ],
      );

      expect(segmentsOf(sidedText, startOffset: 2, endOffset: 6), [
        segment(2, 4, styles: {InlineStyle.italic}, isPlayable: true),
        segment(4, 6, styles: {InlineStyle.italic}),
      ]);
    });

    test('切片不给终点时一直到文字结尾', () {
      final sidedText = buildSidedText(const [
        FixtureSentence('甲甲甲甲'),
        FixtureSentence.voiced('乙乙乙乙'),
      ]);

      expect(segmentsOf(sidedText, startOffset: 6), [
        segment(6, 8, isPlayable: true),
      ]);
    });

    test('切片越界时收回到文字范围内，起点在结尾之后则没有分段', () {
      final sidedText = buildPlainSidedText('四个字符');

      expect(segmentsOf(sidedText, startOffset: 2, endOffset: 99), [
        segment(2, 4),
      ]);
      expect(segmentsOf(sidedText, startOffset: 9), isEmpty);
      expect(segmentsOf(sidedText, startOffset: 3, endOffset: 1), isEmpty);
    });

    test('被播的句子单独成段并高亮，相邻的可播句子不受影响', () {
      final sidedText = buildSidedText(const [
        FixtureSentence.voiced('甲甲'),
        FixtureSentence.voiced('乙乙'),
        FixtureSentence('丙丙'),
      ]);

      expect(
        segmentsOf(sidedText, highlight: const ActiveSentenceHighlight(1)),
        [
          segment(0, 2, isPlayable: true),
          segment(
            2,
            4,
            isPlayable: true,
            highlight: SegmentHighlight.activeSentence,
          ),
          segment(4, 6),
        ],
      );
    });

    test('被播句子的下标对不上任何句子时不高亮', () {
      final sidedText = buildSidedText(const [FixtureSentence.voiced('甲甲')]);

      expect(
        segmentsOf(sidedText, highlight: const ActiveSentenceHighlight(5)),
        [segment(0, 2, isPlayable: true)],
      );
    });

    test('另一面整段淡色高亮，句间空隙也在内', () {
      final sidedText = buildSidedText(const [
        FixtureSentence.voiced('甲甲', gapAfter: ' '),
        FixtureSentence('乙乙'),
      ]);

      expect(segmentsOf(sidedText, highlight: const CompanionSideHighlight()), [
        segment(0, 2, isPlayable: true, highlight: SegmentHighlight.companion),
        segment(2, 5, highlight: SegmentHighlight.companion),
      ]);
    });

    test('含 emoji 时偏移按 UTF-16 码元计，不会把代理对拆开', () {
      const emoji = '😀';
      final sidedText = buildSidedText(const [
        FixtureSentence('前'),
        FixtureSentence.voiced('$emoji好'),
        FixtureSentence('后'),
      ]);

      final segments = segmentsOf(sidedText);

      expect(emoji.length, 2);
      expect(segments, [
        segment(0, 1),
        segment(1, 4, isPlayable: true),
        segment(4, 5),
      ]);
      expect(
        sidedText.text.substring(
          segments[1].startOffset,
          segments[1].endOffset,
        ),
        '$emoji好',
      );
    });
  });

  group('clampFragmentRange', () {
    test('终点为 null 表示到文字结尾', () {
      expect(
        clampFragmentRange(textLength: 10, startOffset: 3, endOffset: null),
        (start: 3, end: 10),
      );
    });

    test('越界的起止收回到文字范围内，且终点不早于起点', () {
      expect(
        clampFragmentRange(textLength: 10, startOffset: -2, endOffset: 50),
        (start: 0, end: 10),
      );
      expect(clampFragmentRange(textLength: 10, startOffset: 8, endOffset: 4), (
        start: 8,
        end: 8,
      ));
    });
  });
}

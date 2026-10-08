import 'package:st_preread/domain/domain.dart';

/// 测试夹具里每句话的默认字符数。
const int fixtureSentenceLength = 4;

/// 构建一面文字：[sentenceHasAudio] 的每一项对应一句，值表示这一句是否带语音。
SidedText buildSidedTextFixture(
  List<bool> sentenceHasAudio, {
  int sentenceLength = fixtureSentenceLength,
}) {
  return SidedText(
    text: '字' * (sentenceLength * sentenceHasAudio.length),
    styleSpans: const [],
    sentences: [
      for (final (index, hasAudio) in sentenceHasAudio.indexed)
        Sentence(
          startOffset: index * sentenceLength,
          endOffset: (index + 1) * sentenceLength,
          audio: hasAudio
              ? AudioClip(
                  filePath: 'fixture-$index.mp3',
                  start: null,
                  end: null,
                )
              : null,
        ),
    ],
  );
}

/// 构建一个段落：某一面传 null 表示该段落没有这一面。
ParagraphBlock buildParagraphFixture({
  String id = 'paragraph',
  ParagraphStyle style = ParagraphStyle.body,
  List<bool>? sourceAudio,
  List<bool>? translationAudio,
  int sentenceLength = fixtureSentenceLength,
}) {
  return ParagraphBlock(
    id: id,
    style: style,
    source: sourceAudio == null
        ? null
        : buildSidedTextFixture(sourceAudio, sentenceLength: sentenceLength),
    translation: translationAudio == null
        ? null
        : buildSidedTextFixture(
            translationAudio,
            sentenceLength: sentenceLength,
          ),
  );
}

Chapter buildChapterFixture(List<ContentBlock> blocks) {
  return Chapter(
    summary: const ChapterSummary(bookId: 'book', index: 0, title: '测试章'),
    blocks: blocks,
  );
}

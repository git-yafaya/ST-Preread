import 'package:st_preread/domain/domain.dart';

/// 测试里统一使用的书 id。
const String fixtureBookId = 'fixture-book';

/// 一句测试文字：[hasAudio] 决定它是否带语音，[gapAfter] 是它后面不属于任何句子的间隙。
class FixtureSentence {
  const FixtureSentence(this.text, {this.hasAudio = false, this.gapAfter = ''});

  const FixtureSentence.voiced(this.text, {this.gapAfter = ''})
    : hasAudio = true;

  final String text;
  final bool hasAudio;
  final String gapAfter;
}

/// 由若干句子拼出一面文字，句子区间按 UTF-16 码元推算。
///
/// [audioFileStem] 用来给每句语音起不同的文件名，便于断言播放的是哪一句。
SidedText buildSidedText(
  List<FixtureSentence> sentences, {
  List<InlineStyleSpan> styleSpans = const [],
  String audioFileStem = 'audio',
}) {
  final text = StringBuffer();
  final builtSentences = <Sentence>[];
  for (final (index, sentence) in sentences.indexed) {
    final startOffset = text.length;
    text.write(sentence.text);
    builtSentences.add(
      Sentence(
        startOffset: startOffset,
        endOffset: text.length,
        audio: sentence.hasAudio
            ? AudioClip(
                filePath: '$audioFileStem-$index.mp3',
                start: null,
                end: null,
              )
            : null,
      ),
    );
    text.write(sentence.gapAfter);
  }
  return SidedText(
    text: text.toString(),
    styleSpans: List.unmodifiable(styleSpans),
    sentences: List.unmodifiable(builtSentences),
  );
}

/// 没有句级数据、没有样式的一面文字。
SidedText buildPlainSidedText(String text) {
  return SidedText(text: text, styleSpans: const [], sentences: const []);
}

/// 两面文字各不相同的段落，便于在界面上分辨主文与辅文。
ParagraphBlock buildParagraph({
  String id = 'paragraph',
  ParagraphStyle style = ParagraphStyle.body,
  SidedText? source,
  SidedText? translation,
}) {
  return ParagraphBlock(
    id: id,
    style: style,
    source: source,
    translation: translation,
  );
}

/// 由同一个字符重复 [length] 次构成的一面文字，用来造出超过一屏的长段落；
/// 行的位置由测试按偏移去量，所以内容本身不需要有区别。
SidedText buildLongSidedText({required String character, required int length}) {
  return buildPlainSidedText(character * length);
}

Chapter buildChapter({
  required int index,
  required List<ContentBlock> blocks,
  String? title,
  String bookId = fixtureBookId,
}) {
  return Chapter(
    summary: ChapterSummary(
      bookId: bookId,
      index: index,
      title: title ?? '测试第 ${index + 1} 章',
    ),
    blocks: List.unmodifiable(blocks),
  );
}

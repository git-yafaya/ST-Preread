import '../../../domain/domain.dart';

/// [textOffset] 落在哪一句里；落在句间空隙或文字之外时返回 null。
///
/// [sentences] 按出现顺序排列且互不重叠，[textOffset] 相对所属那一面的文字，
/// 以 UTF-16 码元为单位。
int? findSentenceIndexAt(List<Sentence> sentences, int textOffset) {
  var low = 0;
  var high = sentences.length - 1;
  while (low <= high) {
    final middle = (low + high) ~/ 2;
    final sentence = sentences[middle];
    if (textOffset < sentence.startOffset) {
      high = middle - 1;
    } else if (textOffset >= sentence.endOffset) {
      low = middle + 1;
    } else {
      return middle;
    }
  }
  return null;
}

/// 点句命中：片段内的偏移 [offsetInFragment] 点到了哪一句**带语音**的句子。
///
/// 片段是某一面文字的切片 `[fragmentStartOffset, fragmentEndOffset)`，
/// 文本布局给出的偏移相对片段开头，这里先加回片段起点再找句子，
/// 返回的是句子在那一面句子列表里的下标。
/// 点在片段之外、句间空隙、无语音的句子上都返回 null。
int? findPlayableSentenceIndexInFragment({
  required List<Sentence> sentences,
  required int fragmentStartOffset,
  required int fragmentEndOffset,
  required int offsetInFragment,
}) {
  final textOffset = fragmentStartOffset + offsetInFragment;
  if (offsetInFragment < 0 || textOffset >= fragmentEndOffset) {
    return null;
  }
  final sentenceIndex = findSentenceIndexAt(sentences, textOffset);
  if (sentenceIndex == null || !sentences[sentenceIndex].hasAudio) {
    return null;
  }
  return sentenceIndex;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/domain.dart';

void main() {
  const clip = AudioClip(
    filePath: 'audio/a.mp3',
    start: Duration(seconds: 1),
    end: Duration(seconds: 3),
  );

  group('AudioClip', () {
    test('字段全部相同时相等且哈希一致', () {
      const sameClip = AudioClip(
        filePath: 'audio/a.mp3',
        start: Duration(seconds: 1),
        end: Duration(seconds: 3),
      );
      expect(clip, sameClip);
      expect(clip.hashCode, sameClip.hashCode);
    });

    test('任一字段不同则不相等', () {
      expect(clip.copyWith(filePath: 'audio/b.mp3'), isNot(clip));
      expect(clip.copyWith(start: () => Duration.zero), isNot(clip));
      expect(clip.copyWith(end: () => null), isNot(clip));
    });

    test('copyWith 可以把区间清空表示整个文件', () {
      final wholeFile = clip.copyWith(start: () => null, end: () => null);
      expect(wholeFile.filePath, 'audio/a.mp3');
      expect(wholeFile.start, isNull);
      expect(wholeFile.end, isNull);
      expect(clip.copyWith(), clip);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:st_preread/domain/entities/collection_equality.dart';

void main() {
  group('areListsEqual', () {
    test('同一个实例相等', () {
      final numbers = [1, 2, 3];
      expect(areListsEqual(numbers, numbers), isTrue);
    });

    test('元素逐个相等的不同实例相等', () {
      expect(areListsEqual([1, 2, 3], [1, 2, 3]), isTrue);
      expect(areListsEqual(<int>[], <int>[]), isTrue);
    });

    test('长度不同不相等', () {
      expect(areListsEqual([1, 2], [1, 2, 3]), isFalse);
    });

    test('元素不同或顺序不同不相等', () {
      expect(areListsEqual([1, 2, 3], [1, 2, 4]), isFalse);
      expect(areListsEqual([1, 2, 3], [3, 2, 1]), isFalse);
    });
  });

  group('areSetsEqual', () {
    test('元素相同即相等，与插入顺序无关', () {
      final numbers = {1, 2, 3};
      expect(areSetsEqual(numbers, numbers), isTrue);
      expect(areSetsEqual({1, 2, 3}, {3, 2, 1}), isTrue);
      expect(areSetsEqual(<int>{}, <int>{}), isTrue);
    });

    test('元素个数或内容不同不相等', () {
      expect(areSetsEqual({1, 2}, {1, 2, 3}), isFalse);
      expect(areSetsEqual({1, 2, 3}, {1, 2, 4}), isFalse);
    });
  });
}

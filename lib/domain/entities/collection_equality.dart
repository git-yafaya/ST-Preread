/// 逐元素比较两个列表。
///
/// 领域层是纯 Dart 且不引入第三方依赖，所以自带这一小段，
/// 而不是使用 collection 包或 Flutter 的 listEquals / setEquals。
bool areListsEqual<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

/// 比较两个集合是否包含相同的元素，与元素的插入顺序无关。
bool areSetsEqual<T>(Set<T> first, Set<T> second) {
  if (identical(first, second)) {
    return true;
  }
  return first.length == second.length && first.containsAll(second);
}

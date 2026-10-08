/// `copyWith` 中可空字段的取值函数。
///
/// 可空字段若直接用 `T?` 作参数，无法区分「不修改」与「改为 null」；
/// 包一层函数后，不传表示不修改，传 `() => null` 表示清空。
typedef NullableValueGetter<T> = T? Function();

/// A generic Tuple class with two typed elements, [T] and [R].
/// Tuples are immutable, and this class provides a simple way to store pairs of values.
class Tuple<T, R> {
  /// Field to store the first element of the tuple.
  final T item1;

  /// Field to store the second element of the tuple.
  final R item2;

  /// Constructor to initialize the tuple with the provided values.
  const Tuple(this.item1, this.item2);
}

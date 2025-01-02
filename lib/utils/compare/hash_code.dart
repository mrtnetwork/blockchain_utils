import '../binary/binary_operation.dart';

/// A utility class for generating consistent and efficient hash codes
/// for collections and objects.
class HashCodeGenerator {
  /// Generates a hash code for a list of bytes, optionally including
  /// additional objects in the calculation.
  ///
  /// Returns: A 32-bit integer hash code.
  static int generateBytesHashCode(List<int> bytes,
      [List<Object> optional = const []]) {
    int hash = 12;
    for (final element in bytes) {
      hash ^= element;
      hash = (hash * 31) & mask32;
    }
    if (optional.isNotEmpty) {
      hash = (hash ^ generateHashCode(optional)) & mask32;
    }
    return hash;
  }

  /// Generates a hash code for a collection of objects, recursively handling
  /// nested iterables.
  ///
  /// Returns: A 32-bit integer hash code.
  static int generateHashCode(Iterable<Object?> objects) {
    int hash = 12;
    for (final element in objects) {
      if (element is Iterable) {
        hash = (hash ^ generateHashCode(element)) & mask32;
      } else {
        hash = (hash ^ element.hashCode) & mask32;
      }
    }
    return hash;
  }
}

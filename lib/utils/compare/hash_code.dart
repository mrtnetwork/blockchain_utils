import 'package:blockchain_utils/utils/binary/binary_operation.dart';

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

  static int generateHashCodeNew(Object? object, {bool sorting = false}) {
    int hash = 12;

    if (object == null) {
      return hash ^ 0;
    } else if (object is Map) {
      var entries = object.entries;
      if (sorting) {
        // Sort by key hash to ensure consistent order
        entries = entries.toList()
          ..sort((a, b) => a.key.hashCode.compareTo(b.key.hashCode));
      }
      for (final entry in entries) {
        hash =
            (hash ^ generateHashCodeNew(entry.key, sorting: sorting)) & mask32;
        hash = (hash ^ generateHashCodeNew(entry.value, sorting: sorting)) &
            mask32;
      }
    } else if (object is Iterable) {
      var elements = object;
      if (sorting) {
        // Sort elements by hash to ensure consistent order
        elements = elements.toList()
          ..sort((a, b) => a.hashCode.compareTo(b.hashCode));
      }
      for (final element in elements) {
        hash = (hash ^ generateHashCodeNew(element, sorting: sorting)) & mask32;
      }
    } else {
      hash = (hash ^ object.hashCode) & mask32;
    }

    // Final mix step to reduce collisions
    hash = ((hash << 3) | (hash >> 29)) & mask32;
    return hash;
  }
}

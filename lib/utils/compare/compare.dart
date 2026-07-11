import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

class CompareUtils {
  static List<List<T>> chunk<T>(List<T> items, int chunk) {
    if (chunk < 0) {
      throw ArgumentException.invalidOperationArguments(
        "chunk",
        reason: 'chunk size must be greater than 0',
      );
    }

    final result = <List<T>>[];

    for (var i = 0; i < items.length; i += chunk) {
      final end = (i + chunk < items.length) ? i + chunk : items.length;
      result.add(items.sublist(i, end));
    }

    return result;
  }

  static List<List<T>> groupConsecutive<T>(List<T> items) {
    if (items.isEmpty) return [];

    final List<List<T>> result = [];
    List<T> currentGroup = [items.first];
    for (int i = 1; i < items.length; i++) {
      if (items[i] == items[i - 1]) {
        currentGroup.add(items[i]);
      } else {
        result.add(currentGroup);
        currentGroup = [items[i]];
      }
    }

    // add the last group
    result.add(currentGroup);

    return result;
  }

  static bool constantTimeBigIntEquals(List<BigInt> a, List<BigInt> b) {
    if (a.length != b.length) return false;

    BigInt diff = BigInt.zero;
    for (int i = 0; i < a.length; i++) {
      diff |= (a[i] ^ b[i]);
    }
    return diff == BigInt.zero;
  }

  static bool iterableConstantTime(
    Iterable<List<int>> a,
    Iterable<List<int>> b,
  ) {
    if (a.isEmpty && b.isEmpty) return true;
    if (a.length != b.length) {
      return false;
    }
    if (identical(a, b)) {
      return true;
    }
    for (int index = 0; index < a.length; index += 1) {
      final valueA = a.elementAt(index);
      final valueB = b.elementAt(index);
      if (!BytesUtils.bytesEqualConst(valueA, valueB)) return false;
    }
    return true;
  }

  /// Compare two lists of bytes for equality.
  /// This function compares two lists of bytes 'a' and 'b' for equality. It returns true
  /// if the lists are equal (including null check), false if they have different lengths
  /// or contain different byte values, and true if the lists reference the same object.
  static bool iterableIsEqual<T>(Iterable<T>? a, Iterable<T>? b) {
    /// Check if 'a' is null and handle null comparison.
    if (a == null) {
      return b == null;
    }

    /// Check if 'b' is null or if the lengths of 'a' and 'b' are different.
    if (b == null || a.length != b.length) {
      return false;
    }

    /// Check if 'a' and 'b' reference the same object (identity comparison).
    if (identical(a, b)) {
      return true;
    }

    /// Compare the individual byte values in 'a' and 'b'.
    for (int index = 0; index < a.length; index += 1) {
      final valueA = a.elementAt(index);
      final valueB = b.elementAt(index);
      if (valueA is Map && valueB is Map) {
        // Recursively compare maps
        if (!mapIsEqual(valueA, valueB)) return false;
      } else if (valueA is Iterable && valueB is Iterable) {
        // Recursively compare iterables
        if (!iterableIsEqual(valueA, valueB)) return false;
      } else if (valueA != valueB) {
        return false;
      }
    }

    /// If no differences were found, the lists are equal.
    return true;
  }

  static bool mapIsEqual<K, V>(Map<K, V>? a, Map<K, V>? b) {
    // Handle null comparison
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;

    // Check if 'a' and 'b' are identical objects
    if (identical(a, b)) return true;

    // Compare the entries in 'a' and 'b'
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;

      final valueA = a[key];
      final valueB = b[key];
      if (valueA == null && valueB == null) continue;

      if (valueA is Map && valueB is Map) {
        // Recursively compare maps
        if (!mapIsEqual(valueA, valueB)) return false;
      } else if (valueA is Iterable && valueB is Iterable) {
        // Recursively compare iterables
        if (!iterableIsEqual(valueA, valueB)) return false;
      } else if (valueA != valueB) {
        return false;
      }
    }

    return true;
  }
}

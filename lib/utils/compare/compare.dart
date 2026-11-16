import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

/// Comparison and equality helpers for lists, maps, and grouping.
class CompareUtils {
  /// Splits [items] into consecutive sublists of at most [chunk] elements.
  static List<List<T>> chunk<T>(List<T> items, int chunk) {
    if (chunk <= 0) {
      throw CoreErrors.invalidOperationArguments(
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

  /// Groups adjacent equal elements of [items] together.
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
    result.add(currentGroup);

    return result;
  }

  /// Constant-time equality check for two same-length lists of [BigInt].
  static bool constantTimeBigIntEquals(List<BigInt> a, List<BigInt> b) {
    if (a.length != b.length) return false;

    BigInt diff = BigInt.zero;
    for (int i = 0; i < a.length; i++) {
      diff |= (a[i] ^ b[i]);
    }
    return diff == BigInt.zero;
  }

  /// Constant-time equality check for two sequences of byte lists.
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

  /// Deep, order-sensitive equality for two iterables (null-safe, recurses
  /// into nested [Map]s and [Iterable]s).
  static bool iterableIsEqual<T>(Iterable<T>? a, Iterable<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    if (identical(a, b)) {
      return true;
    }

    for (int index = 0; index < a.length; index += 1) {
      final valueA = a.elementAt(index);
      final valueB = b.elementAt(index);
      if (valueA is Map && valueB is Map) {
        if (!mapIsEqual(valueA, valueB)) return false;
      } else if (valueA is Iterable && valueB is Iterable) {
        if (!iterableIsEqual(valueA, valueB)) return false;
      } else if (valueA != valueB) {
        return false;
      }
    }

    return true;
  }

  /// Deep equality for two maps (null-safe, recurses into nested [Map]s and
  /// [Iterable]s).
  static bool mapIsEqual<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;

      final valueA = a[key];
      final valueB = b[key];
      if (valueA == null && valueB == null) continue;

      if (valueA is Map && valueB is Map) {
        if (!mapIsEqual(valueA, valueB)) return false;
      } else if (valueA is Iterable && valueB is Iterable) {
        if (!iterableIsEqual(valueA, valueB)) return false;
      } else if (valueA != valueB) {
        return false;
      }
    }

    return true;
  }
}

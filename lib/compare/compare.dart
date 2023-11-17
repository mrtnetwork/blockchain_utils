import 'dart:core';

/// Compare two lists of bytes for equality.
/// This function compares two lists of bytes 'a' and 'b' for equality. It returns true
/// if the lists are equal (including null check), false if they have different lengths
/// or contain different byte values, and true if the lists reference the same object.
bool bytesEqual(List<int>? a, List<int>? b) {
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
    if (a[index] != b[index]) {
      return false;
    }
  }

  /// If no differences were found, the lists are equal.
  return true;
}

/// Compare two lists of bytes for equality.
/// This function compares two lists of bytes 'a' and 'b' for equality. It returns true
/// if the lists are equal (including null check), false if they have different lengths
/// or contain different byte values, and true if the lists reference the same object.
bool iterableIsEqual<T>(Iterable<T>? a, Iterable<T>? b) {
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
    if (a.elementAt(index) != b.elementAt(index)) {
      return false;
    }
  }

  /// If no differences were found, the lists are equal.
  return true;
}

bool isLessThanBytes(List<int> thashedA, List<int> thashedB) {
  for (int i = 0; i < thashedA.length && i < thashedB.length; i++) {
    if (thashedA[i] < thashedB[i]) {
      return true;
    } else if (thashedA[i] > thashedB[i]) {
      return false;
    }
  }
  return thashedA.length < thashedB.length;
}

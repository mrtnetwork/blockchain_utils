import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/hex/hex.dart' as hex;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

/// A utility class for working with binary data represented as lists of integers (bytes).
class BytesUtils {
  /// Bitwise XOR of two equal-length byte lists.
  static BuBytes xor(List<int> dataBytes1, List<int> dataBytes2) {
    return BuBytes(
      List<int>.generate(
        dataBytes1.length,
        (index) => dataBytes1[index] ^ dataBytes2[index],
      ),
    );
  }

  /// Converts [dataBytes] to a binary string, zero-padded to [zeroPadBitLen] bits.
  static String toBinary(List<int> dataBytes, {int zeroPadBitLen = 0}) {
    return BigintUtils.toBinary(
      BigintUtils.fromBytes(dataBytes),
      zeroPadBitLen: zeroPadBitLen,
    );
  }

  /// Parses a binary string back into bytes, zero-padded to [zeroPadByteLen] bytes.
  static BuBytes fromBinary(String data, {int zeroPadByteLen = 0}) {
    final BigInt intValue = BigInt.parse(data, radix: 2);
    final String hexValue = intValue
        .toRadixString(16)
        .padLeft(zeroPadByteLen, '0');
    return fromHexString(hexValue);
  }

  /// Encodes [dataBytes] as a hex string, optionally with [prefix].
  static String toHexString(
    List<int> dataBytes, {
    bool lowerCase = true,
    String? prefix,
  }) {
    final String toHex = hex.hex.encode(dataBytes, lowerCase: lowerCase);
    return "${prefix ?? ''}$toHex";
  }

  /// Like [toHexString], but returns null instead of throwing on failure
  /// (or if [dataBytes] is null).
  static String? tryToHexString(
    List<int>? dataBytes, {
    bool lowerCase = true,
    String? prefix,
  }) {
    if (dataBytes == null) return null;
    try {
      return toHexString(dataBytes, lowerCase: lowerCase, prefix: prefix);
    } catch (e) {
      return null;
    }
  }

  /// Decodes a hex string (with an optional `0x` prefix) into bytes.
  ///
  /// [paddingZero] left-pads a zero when the string has odd length.
  /// Throws [BuError] on an invalid hex string.
  static BuBytes fromHexString(String hexStr, {bool paddingZero = false}) {
    try {
      String hexString = StringUtils.strip0x(hexStr);
      if (hexString.isEmpty) return BuBytes.empty();
      if (paddingZero && hexString.length.isOdd) {
        hexString = "0$hexString";
      }
      return hex.hex.decode(hexString);
    } catch (e) {
      throw CoreErrors.invalidOperationArguments(
        "fromHexString",
        name: "hexStr",
        reason: "invalid hex string.",
      );
    }
  }

  /// Like [fromHexString], but returns null instead of throwing on failure
  /// (or if [data] is null).
  static BuBytes? tryFromHexString(String? data, {bool paddingZero = false}) {
    if (data == null) return null;
    try {
      return fromHexString(data, paddingZero: paddingZero);
    } catch (e) {
      return null;
    }
  }

  /// Masks every element of [bytes] to a single byte (0-255).
  static BuBytes toBytes(Iterable<int> bytes, {bool unmodifiable = false}) {
    final masked = bytes.map((e) => e & BinaryOps.mask8).toList();
    if (unmodifiable) {
      return BuBytes.immutable(masked);
    }
    return BuBytes(masked);
  }

  /// Like [toBytes], but returns null if [bytes] is null.
  static BuBytes? tryToBytes(List<int>? bytes, {bool unmodifiable = false}) {
    if (bytes == null) return null;
    return toBytes(bytes, unmodifiable: unmodifiable);
  }

  /// Validates that every element of [bytes] is in range 0-255, optionally
  /// throwing [onValidationFailed]'s result instead of returning false.
  static bool areBytesValid(
    Iterable<int> bytes, {
    Object Function()? onValidationFailed,
  }) {
    final bool isBytes = BytesUtils.isBytes(bytes);
    if (!isBytes && onValidationFailed != null) {
      throw onValidationFailed();
    }
    return isBytes;
  }

  /// Whether every element of [bytes] is in range 0-255.
  static bool isBytes(Iterable<int> bytes) =>
      bytes.every((e) => e >= 0 && e <= BinaryOps.mask8);

  /// Constant-time variant of [isBytes].
  static bool isBytesConst(List<int> bytes) {
    int invalid = 0;
    for (int i = 0; i < bytes.length; i++) {
      int b = bytes[i];
      invalid |= (b >> 8);
    }
    return invalid == 0;
  }

  /// Constant-time variant of [areBytesValid].
  static bool areBytesValidConst(
    List<int> bytes, {
    Object Function()? onValidationFailed,
  }) {
    final bool isBytes = isBytesConst(bytes);
    if (!isBytes && onValidationFailed != null) throw onValidationFailed();
    return isBytes;
  }

  /// Compares two byte lists lexicographically (-1, 0, or 1).
  static int compareBytes(List<int> a, List<int> b) {
    final length = a.length < b.length ? a.length : b.length;

    for (var i = 0; i < length; i++) {
      if (a[i] < b[i]) {
        return -1;
      } else if (a[i] > b[i]) {
        return 1;
      }
    }

    if (a.length < b.length) {
      return -1;
    } else if (a.length > b.length) {
      return 1;
    }

    return 0;
  }

  /// Whether [part] is equal to any entry in [a].
  static bool isContains(List<List<int>> a, List<int> part) {
    for (final i in a) {
      if (bytesEqual(i, part)) return true;
    }
    return false;
  }

  /// Constant-time equality check for two same-length byte lists.
  static bool bytesEqualConst(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= (a[i] ^ b[i]);
    }
    return diff == 0;
  }

  /// Null-safe equality check for two byte lists.
  static bool bytesEqual(List<int>? a, List<int>? b) {
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
      if (a[index] != b[index]) {
        return false;
      }
    }

    return true;
  }

  /// Left-pads [bytes] with zeros to [length] bytes. If [bytes] is already
  /// [length] bytes or longer, a copy is returned.
  static BuBytes padBytesLeft(List<int> bytes, int length) {
    if (bytes.length >= length) {
      return BuBytes(bytes);
    }

    final result = List<int>.filled(length, 0);
    final start = length - bytes.length;
    result.setRange(start, length, bytes);

    return BuBytes(result);
  }

  /// Whether [a] is lexicographically less than [b].
  static bool isLessThanBytes(List<int> a, List<int> b) {
    for (int i = 0; i < a.length && i < b.length; i++) {
      if (a[i] < b[i]) {
        return true;
      } else if (a[i] > b[i]) {
        return false;
      }
    }
    return a.length < b.length;
  }

  /// Constant-time comparison of two 32-byte big-endian values: 1 if [a] < [b], else 0.
  static int isLessThanConst(List<int> a, List<int> b) {
    assert(a.length == 32);
    assert(b.length == 32);

    int borrow = 0;

    for (int i = 31; i >= 0; i--) {
      final x = a[i];
      final y = b[i];

      final diff = x - y - borrow;

      // borrow = 1 if x < y + borrow
      borrow = (diff >> 8) & 1;
    }

    return borrow;
  }

  /// Constant-time check for whether every byte in [bytes] is zero.
  static bool isZeroConst(List<int> bytes) {
    var nonZero = 0;
    for (final byte in bytes) {
      nonZero |= byte;
    }

    if (nonZero == 0) {
      return true;
    }
    return false;
  }

  /// Computes `(a * b) + c` over 32-byte little-endian values, truncated to 32 bytes.
  static BuBytes mulAddTruncated32(List<int> a, List<int> b, List<int> c) {
    if (a.length < 32 || b.length < 32 || c.length < 32) {
      throw CoreErrors.invalidOperationArguments(
        "mulAddTruncated32",
        reason: "All input lists must have 32 elements.",
      );
    }

    assert(a.length == 32 && b.length == 32 && c.length == 32);

    final r = List<int>.filled(32, 0);
    final tmp = List<int>.filled(64, 0);
    for (int i = 0; i < 32; i++) {
      int carry = 0;
      for (int j = 0; j < 32; j++) {
        int rIndex = i + j;
        int ai = a[i];
        int bj = b[j];
        int mul = ai * bj + tmp[rIndex] + carry;
        tmp[rIndex] = mul & 0xFF;
        carry = mul >> 8;
      }
      tmp[i + 32] += carry;
    }

    int carry = 0;
    for (int i = 0; i < 32; i++) {
      int sum = tmp[i] + c[i] + carry;
      r[i] = sum & 0xFF;
      carry = sum >> 8;
    }

    return BuBytes(r);
  }

  /// Expands [bytes] into individual bits, in the given bit [endian] order.
  static List<bool> bytesToBits(
    List<int> bytes, {
    Endian endian = Endian.little,
  }) {
    final bits = <bool>[];

    for (final b in bytes) {
      if (endian == Endian.little) {
        // LSB first
        for (int i = 0; i < 8; i++) {
          bits.add(((b >> i) & 1) != 0);
        }
      } else {
        // MSB first
        for (int i = 7; i >= 0; i--) {
          bits.add(((b >> i) & 1) != 0);
        }
      }
    }

    return bits;
  }

  /// Drops leading zero bytes from [bytes].
  static BuBytes trimLeadingZero(List<int> bytes) {
    int offset = 0;
    while (offset < bytes.length) {
      if (bytes[offset] != 0) break;
      offset++;
    }
    return BuBytes(bytes.sublist(offset));
  }

  /// Drops trailing zero bytes from [bytes].
  static BuBytes trimTrailingZero(List<int> bytes) {
    int offset = bytes.length;
    while (offset != 0) {
      if (bytes[offset - 1] != 0) break;
      offset--;
    }
    return BuBytes(bytes.sublist(0, offset));
  }
}

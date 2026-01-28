import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/exception.dart';

/// Class container for bit utility functions.
class BitUtils {
  /// Get if the specified bit is set.
  static bool intIsBitSet(int value, int bitNum) {
    return (value & (1 << bitNum)) != 0;
  }

  /// Get if the specified bits are set.
  static bool areBitsSet(int value, int bitMask) {
    return (value & bitMask) != 0;
  }

  /// Set the specified bit.
  static int setBit(int value, int bitNum) {
    return value | (1 << bitNum);
  }

  static List<bool> fromString(String bitString) {
    return bitString
        .split('')
        .map(
          (c) => switch (c) {
            '0' => false,
            "1" => true,
            _ =>
              throw ArgumentException.invalidOperationArguments(
                "fromString",
                reason: "Invalid bit string.",
              ),
          },
        )
        .toList();
  }

  /// Set the specified bits.
  static int setBits(int value, int bitMask) {
    return value | bitMask;
  }

  /// Reset the specified bit.
  static int resetBit(int value, int bitNum) {
    return value & ~(1 << bitNum);
  }

  /// Reset the specified bits.
  static int resetBits(int value, int bitMask) {
    return value & ~bitMask;
  }

  static int reverseBits8(int b) {
    b = ((b & 0xF0) >> 4) | ((b & 0x0F) << 4);
    b = ((b & 0xCC) >> 2) | ((b & 0x33) << 2);
    b = ((b & 0xAA) >> 1) | ((b & 0x55) << 1);
    return b;
  }

  static int bitsToInt(List<bool> bits, {Endian endian = Endian.little}) {
    int value = 0;
    int n = bits.length;
    if (endian == Endian.little) {
      for (int i = 0; i < n; i++) {
        if (bits[i]) {
          value |= (1 << i);
        }
      }
    } else {
      for (int i = 0; i < n; i++) {
        if (bits[i]) {
          value |= (1 << (n - 1 - i));
        }
      }
    }
    return value;
  }

  static BigInt bitsToBigInt(List<bool> bits, {Endian endian = Endian.little}) {
    BigInt value = BigInt.zero;
    int n = bits.length;
    if (endian == Endian.little) {
      for (int i = 0; i < n; i++) {
        if (bits[i]) {
          value |= (BigInt.one << i);
        }
      }
    } else {
      for (int i = 0; i < n; i++) {
        if (bits[i]) {
          value |= (BigInt.one << (n - 1 - i));
        }
      }
    }
    return value;
  }
}

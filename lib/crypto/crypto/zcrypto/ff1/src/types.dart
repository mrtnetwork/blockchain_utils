// import 'dart:math' as IntUtils;
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/bit_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

enum FF1Encoding { flexible, binary }

abstract final class NumeralString<T extends NumeralString<T>> {
  List<T> split();
  int numeralCount();
  bool isValid(int radix);
  T concat(T a, T b);
  List<int> toBytesInternal(int radix, int b);
  T addModExp(Iterable<int> other, int radix, int m);
  T subModExp(Iterable<int> other, int radix, int m);
}

final class FF1Radix {
  final int radix;
  final FF1Encoding type;

  final int minLen;
  int get maxLen => BinaryOps.mask32;
  final bool isPowerOfTwo;
  final int? logRadix;
  const FF1Radix._({
    required this.radix,
    required this.minLen,
    required this.isPowerOfTwo,
    required this.type,
    this.logRadix,
  });
  factory FF1Radix({int radix = 2, required FF1Encoding type}) {
    const int minNsLen = 2;
    const int minRadix2NsLen = 20;
    const int minNsDomainSize = 1000000;
    if (radix < 2 || radix > (1 << 16)) {
      throw ArgumentException.invalidOperationArguments(
        "FF1Radix",
        name: "radix",
        reason: 'Invalid radix.',
      );
    }
    if (type == FF1Encoding.binary && radix != 2) {
      throw ArgumentException.invalidOperationArguments(
        "FF1Radix",
        name: "radix",
        reason: 'Invalid radix.',
      );
    }

    final bool pow2 = (radix & (radix - 1)) == 0;

    if (pow2) {
      int lg = (IntUtils.log(radix) / IntUtils.log(2)).floor();
      int minLen = IntUtils.max((minRadix2NsLen + lg - 1) ~/ lg, minNsLen);
      return FF1Radix._(
        radix: radix,
        minLen: minLen,
        isPowerOfTwo: true,
        logRadix: lg,
        type: type,
      );
    } else {
      int minLen = 1;
      int domain = radix;
      while (domain < minNsDomainSize) {
        domain *= radix;
        minLen++;
      }
      return FF1Radix._(
        radix: radix,
        minLen: minLen,
        isPowerOfTwo: false,
        logRadix: null,
        type: type,
      );
    }
  }

  int calculateB(int v) {
    if (isPowerOfTwo) {
      return ((v * logRadix! + 7) ~/ 8);
    } else {
      return (v * IntUtils.log(radix) / IntUtils.log(2) / 8).ceil();
    }
  }
}

final class FlexibleNumeralString
    implements NumeralString<FlexibleNumeralString> {
  final List<int> digits;

  FlexibleNumeralString(List<int> digits) : digits = digits.immutable;
  @override
  bool isValid(int radix) => digits.every((d) => d < radix);

  @override
  int numeralCount() => digits.length;

  /// Splits the numeral string in half.
  @override
  List<FlexibleNumeralString> split() {
    int mid = digits.length ~/ 2;
    return [
      FlexibleNumeralString(digits.sublist(0, mid)),
      FlexibleNumeralString(digits.sublist(mid)),
    ];
  }

  BigInt numRadix(int radix) {
    BigInt result = BigInt.zero;
    for (var d in digits) {
      result = result * BigInt.from(radix) + BigInt.from(d);
    }
    return result;
  }

  static FlexibleNumeralString strRadix(BigInt x, int radix, int m) {
    List<int> result = List.filled(m, 0);
    BigInt value = x;
    for (int i = 0; i < m; i++) {
      result[m - 1 - i] = (value % BigInt.from(radix)).toInt();
      value ~/= BigInt.from(radix);
    }
    return FlexibleNumeralString(result);
  }

  @override
  FlexibleNumeralString addModExp(Iterable<int> other, int radix, int m) {
    final BigInt value = BigintUtils.fromBytes(other.toList());
    return strRadix(
      numRadix(radix).modAdd(value, BigInt.from(radix).pow(m)),
      radix,
      m,
    );
  }

  @override
  FlexibleNumeralString subModExp(Iterable<int> other, int radix, int m) {
    final BigInt value = BigintUtils.fromBytes(other.toList());
    return strRadix(
      numRadix(radix).modSub(value, BigInt.from(radix).pow(m)),
      radix,
      m,
    );
  }

  @override
  List<int> toBytesInternal(int radix, int b) {
    final c = numRadix(radix);
    return BigintUtils.toBytes(c, length: b);
  }

  @override
  FlexibleNumeralString concat(
    FlexibleNumeralString a,
    FlexibleNumeralString b,
  ) {
    return FlexibleNumeralString([...a.digits, ...b.digits]);
  }
}

final class BinaryNumeralString implements NumeralString<BinaryNumeralString> {
  final List<int> data;
  final int numBits;
  BinaryNumeralString._(List<int> data, int bits)
    : data = data.asImmutableBytes,
      numBits = bits;
  BinaryNumeralString(List<int> data)
    : data = data.asImmutableBytes,
      numBits = data.length * 8;
  @override
  int numeralCount() => numBits;
  @override
  List<BinaryNumeralString> split() {
    final n = numeralCount();
    final u = n ~/ 2;
    final v = n - u;
    final aEnd = (u + 7) ~/ 8;
    final bStart = u ~/ 8;

    final aSlice = data.sublist(0, aEnd);
    final bSlice = data.sublist(bStart);

    late List<int> aProcessed;
    late List<int> bProcessed;

    if (u % 8 == 0) {
      // Simple case: just reverse bits in each byte and reverse the list
      aProcessed =
          aSlice
              .map((b) => BitUtils.reverseBits8(b))
              .toList()
              .reversed
              .toList();
      bProcessed =
          bSlice
              .map((b) => BitUtils.reverseBits8(b))
              .toList()
              .reversed
              .toList();
    } else {
      // Complicated case: shift bits to align halves
      int carried = 0;
      aProcessed =
          aSlice.map((b) {
            final shifted = ((b << 4) | (carried >> 4)) & BinaryOps.mask8;
            carried = b;
            return BitUtils.reverseBits8(shifted);
          }).toList();
      aProcessed = aProcessed.reversed.toList();

      bProcessed =
          bSlice.indexed
              .map((e) {
                final i = e.$1;
                final b = BitUtils.reverseBits8(e.$2);
                return i == 0 ? (b & 0x0F) : b; // clear MS nibble of first byte
              })
              .toList()
              .reversed
              .toList();
    }

    return [
      BinaryNumeralString._(aProcessed, u),
      BinaryNumeralString._(bProcessed, v),
    ];
  }

  @override
  bool isValid(int radix) {
    return radix == 2;
  }

  @override
  BinaryNumeralString concat(BinaryNumeralString a, BinaryNumeralString b) {
    late List<int> out;
    if (a.numeralCount() % 8 == 0) {
      out =
          [
            ...b.data,
            ...a.data,
          ].map((e) => BitUtils.reverseBits8(e)).toList().reversed.toList();
    } else {
      // Non-byte-aligned case: shift nibbles
      final aLast = (a.data[0] & 0x0F) << 4;
      // Process 'a' by shifting forward 4 bits and reversing bits
      int carried = 0;
      final aProcessed = a.data
          .map((next) {
            final shifted = ((next << 4) | carried) & BinaryOps.mask8;
            carried = next >> 4;
            return BitUtils.reverseBits8(shifted);
          })
          .toList()
          .skip(1);
      final bProcessed = b.data.reversed.indexed.toList().reversed.map((e) {
        final combined = e.$1 == 0 ? aLast | e.$2 : e.$2;
        return BitUtils.reverseBits8(combined);
      });
      out = [...bProcessed, ...aProcessed].reversed.toList();
    }

    return BinaryNumeralString(out);
  }

  BigInt numRadix(int radix) {
    assert(radix == 2);
    return BigintUtils.fromBytes(data, byteOrder: Endian.little);
  }

  BinaryNumeralString strRadix(BigInt x) {
    List<int> bytes = BigintUtils.toBytes(x, order: Endian.little);
    final data = this.data.clone();
    for (int i = 0; i < bytes.length; i++) {
      data[i] = bytes[i];
    }
    for (int i = bytes.length; i < data.length; i++) {
      data[i] = 0;
    }
    return BinaryNumeralString._(data, numBits);
  }

  @override
  BinaryNumeralString addModExp(Iterable<int> other, int radix, int m) {
    assert(numBits == m);
    final BigInt value = BigintUtils.fromBytes(other.toList());
    return strRadix(numRadix(radix).modAdd(value, BigInt.from(radix).pow(m)));
  }

  @override
  BinaryNumeralString subModExp(Iterable<int> other, int radix, int m) {
    assert(numBits == m);
    final BigInt value = BigintUtils.fromBytes(other.toList());
    return strRadix(numRadix(radix).modSub(value, BigInt.from(radix).pow(m)));
  }

  @override
  List<int> toBytesInternal(int radix, int b) {
    final c = numRadix(radix);
    return BigintUtils.toBytes(c, length: b);
  }
}

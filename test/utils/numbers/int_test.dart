import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

/// Safe power-of-two for building EXPECTED test values. Never use raw
/// `1 << n` for n >= ~31 in a cross-platform test — dart2js's native `<<`
/// is not reliable past 32 bits (this is exactly the class of bug these
/// tests exist to catch in the implementation, so the test itself must not
/// make the same mistake). Exact for n <= 52 on every platform.
int safePow2(int n) => (BigInt.one << n).toInt();

/// Independent big-endian/little-endian two's-complement encoder, used only
/// to build test vectors — deliberately NOT sharing code with the
/// implementation under test.
List<int> encodeBytes(BigInt value, int len, {Endian byteOrder = Endian.big}) {
  BigInt v = value;
  if (v.isNegative) {
    v += BigInt.one << (len * 8); // two's complement wrap
  }
  final bytes = List<int>.filled(len, 0);
  for (var i = len - 1; i >= 0; i--) {
    bytes[i] = (v & BigInt.from(0xFF)).toInt();
    v >>= 8;
  }
  return byteOrder == Endian.little ? bytes.reversed.toList() : bytes;
}

/// Independent reference decoder via hex-string parsing (never uses native
/// `<<` on plain int), using the same isSafeInt() guard semantics as the
/// implementation, so both the decoded value AND throw/no-throw are checked.
int referenceDecode(
  List<int> bytes, {
  int offset = 0,
  int? length,
  Endian byteOrder = Endian.big,
  bool sign = false,
}) {
  final len = length ?? (bytes.length - offset);
  if (len == 0) return 0;

  final slice = bytes.sublist(offset, offset + len);
  final ordered = byteOrder == Endian.little ? slice.reversed.toList() : slice;
  final hex = ordered.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  BigInt result = BigInt.parse(hex, radix: 16);
  if (sign && (ordered[0] & 0x80) != 0) {
    result -= BigInt.one << (len * 8);
  }

  if (!result.isSafeInt()) {
    throw ArgumentError('not a safe int (reference)');
  }
  return result.toInt();
}

void expectMatchesReference(
  List<int> bytes, {
  int offset = 0,
  int? length,
  Endian byteOrder = Endian.big,
  bool sign = false,
}) {
  final actual = IntUtils.fromBytes(
    bytes,
    offset: offset,
    length: length,
    byteOrder: byteOrder,
    sign: sign,
  );
  final expected = referenceDecode(
    bytes,
    offset: offset,
    length: length,
    byteOrder: byteOrder,
    sign: sign,
  );
  expect(
    actual,
    expected,
    reason:
        'bytes=$bytes offset=$offset length=$length byteOrder=$byteOrder sign=$sign',
  );
}

void intTest() {
  group('empty / zero-length', () {
    test('empty list returns zero', () {
      expect(IntUtils.fromBytes(<int>[]), 0);
    });
    test('explicit length: 0 returns zero', () {
      expect(IntUtils.fromBytes([1, 2, 3], offset: 1, length: 0), 0);
    });
  });

  group('single byte, unsigned', () {
    for (final b in [0x00, 0x01, 0x7F, 0x80, 0xFF]) {
      test('0x${b.toRadixString(16)}', () {
        expectMatchesReference([b], sign: false);
        expect(IntUtils.fromBytes([b], sign: false), b);
      });
    }
  });

  group('single byte, signed', () {
    test('0x00 -> 0', () => expect(IntUtils.fromBytes([0x00], sign: true), 0));
    test(
      '0x7F -> 127',
      () => expect(IntUtils.fromBytes([0x7F], sign: true), 127),
    );
    test(
      '0x80 -> -128',
      () => expect(IntUtils.fromBytes([0x80], sign: true), -128),
    );
    test(
      '0xFF -> -1',
      () => expect(IntUtils.fromBytes([0xFF], sign: true), -1),
    );
  });

  group('native-path boundary (<=4 bytes, single _fromBytesUpTo4 call)', () {
    for (final len in [1, 2, 3, 4]) {
      test('len=$len all-0xFF unsigned == 2^${len * 8}-1', () {
        final bytes = List<int>.filled(len, 0xFF);
        expect(IntUtils.fromBytes(bytes), safePow2(len * 8) - 1);
      });
      test('len=$len all-0xFF signed == -1', () {
        final bytes = List<int>.filled(len, 0xFF);
        expect(IntUtils.fromBytes(bytes, sign: true), -1);
      });
      test('len=$len most-negative pattern', () {
        final bytes = [0x80, ...List<int>.filled(len - 1, 0x00)];
        expect(IntUtils.fromBytes(bytes, sign: true), -safePow2(len * 8 - 1));
      });
    }
  });

  group('native-path boundary (5-6 bytes, upper/lower split)', () {
    for (final len in [5, 6]) {
      test('len=$len all-0xFF unsigned == 2^${len * 8}-1', () {
        final bytes = List<int>.filled(len, 0xFF);
        final expected = safePow2(len * 8) - 1;
        expect(IntUtils.fromBytes(bytes), expected);
        expect(BigInt.from(expected) <= BinaryOps.safeUintBigInt, isTrue);
      });
      test('len=$len all-0xFF signed == -1', () {
        final bytes = List<int>.filled(len, 0xFF);
        // Regression coverage for the web-only sign-extension bug: the
        // implementation's `result -= 1 << (ordered.length * 8)` must not
        // use raw `<<` for n >= 32, or this silently returns the unsigned
        // magnitude instead of -1 on dart2js/dartdevc.
        expect(IntUtils.fromBytes(bytes, sign: true), -1);
      });
      test('len=$len most-negative pattern', () {
        final bytes = [0x80, ...List<int>.filled(len - 1, 0x00)];
        expect(IntUtils.fromBytes(bytes, sign: true), -safePow2(len * 8 - 1));
      });
      test('len=$len max-positive pattern (0x7F + 0xFFs) signed', () {
        final bytes = [0x7F, ...List<int>.filled(len - 1, 0xFF)];
        expect(
          IntUtils.fromBytes(bytes, sign: true),
          safePow2(len * 8 - 1) - 1,
        );
      });
    }

    test('exactly at the 6-byte threshold matches reference, both orders', () {
      final bytes = List<int>.generate(6, (i) => (i * 41 + 3) & 0xFF);
      expectMatchesReference(bytes, sign: true);
      expectMatchesReference(bytes, byteOrder: Endian.little, sign: true);
    });
  });

  group('big/little-endian consistency', () {
    test('reversing bytes + swapping byteOrder yields same value', () {
      final be = [0x12, 0x34, 0x56, 0x78, 0x9A];
      final le = be.reversed.toList();
      expect(
        IntUtils.fromBytes(be, byteOrder: Endian.big, sign: true),
        IntUtils.fromBytes(le, byteOrder: Endian.little, sign: true),
      );
    });

    test('leading zero byte does not flip sign', () {
      expect(IntUtils.fromBytes([0x00, 0xFF], sign: true), 255);
    });
  });

  group('offset / length slicing', () {
    final buf = List<int>.generate(64, (i) => i);

    test('offset only, reads to end (3 bytes)', () {
      expectMatchesReference(buf, offset: 61);
    });

    test('offset + explicit length, middle of buffer', () {
      expectMatchesReference(buf, offset: 10, length: 4, sign: true);
    });

    test('offset + length spanning the 4/5-byte split boundary', () {
      expectMatchesReference(buf, offset: 20, length: 5, sign: true);
      expectMatchesReference(buf, offset: 20, length: 6, sign: true);
    });

    test('large buffer: window extracted correctly, native path', () {
      final big = List<int>.generate(10000, (i) => i & 0xFF);
      expectMatchesReference(big, offset: 9994, length: 6, sign: true);
      expectMatchesReference(
        big,
        offset: 9000,
        length: 4,
        byteOrder: Endian.little,
      );
    });
  });

  group('invalid offset / length', () {
    test('negative offset throws', () {
      expect(
        () => IntUtils.fromBytes([1, 2, 3], offset: -1),
        throwsA(anything),
      );
    });
    test('offset + length exceeds bytes.length throws', () {
      expect(
        () => IntUtils.fromBytes([1, 2, 3], offset: 2, length: 5),
        throwsA(anything),
      );
    });
  });

  group('len > 6 routes through BigInt + isSafeInt() guard', () {
    test('7-byte value within the safe-int range decodes correctly', () {
      final bytes = List<int>.generate(7, (i) => (i * 29 + 5) & 0xFF);
      expectMatchesReference(bytes, sign: true);
    });

    test('7-byte value exceeding the safe-int range throws', () {
      final tooLarge = BinaryOps.safeUintBigInt + BigInt.one;
      final bytes = encodeBytes(tooLarge, 7);
      expect(
        () => IntUtils.fromBytes(bytes, sign: false),
        throwsArgumentException,
      );
    });

    test('8 bytes, value too large for int64 throws (2^64 - 1)', () {
      final bytes = List<int>.filled(8, 0xFF);
      expect(
        () => IntUtils.fromBytes(bytes, sign: false),
        throwsArgumentException,
      );
    });

    test('8 bytes, max signed int64 (2^63 - 1) throws (not a safe int)', () {
      final bytes = [0x7F, ...List<int>.filled(7, 0xFF)];
      expect(
        () => IntUtils.fromBytes(bytes, sign: true),
        throwsArgumentException,
      );
    });

    test('8 bytes, min signed int64 (-2^63) throws (not a safe int)', () {
      final bytes = [0x80, ...List<int>.filled(7, 0x00)];
      expect(
        () => IntUtils.fromBytes(bytes, sign: true),
        throwsArgumentException,
      );
    });
  });

  group('safe-int boundary, derived from BinaryOps constants', () {
    test('exactly at safeUintBigInt does not throw and is exact', () {
      final v = BinaryOps.safeUintBigInt;
      final bytes = encodeBytes(v, 8);
      expect(IntUtils.fromBytes(bytes, sign: false), v.toInt());
    });

    test('one past safeUintBigInt throws', () {
      final v = BinaryOps.safeUintBigInt + BigInt.one;
      final bytes = encodeBytes(v, 8);
      expect(
        () => IntUtils.fromBytes(bytes, sign: false),
        throwsArgumentException,
      );
    });

    test(
      'exactly at safeIntBigInt (negative bound) does not throw and is exact',
      () {
        final v = BinaryOps.safeIntBigInt;
        final bytes = encodeBytes(v, 8);
        expect(IntUtils.fromBytes(bytes, sign: true), v.toInt());
      },
    );

    test('one past safeIntBigInt (more negative) throws', () {
      final v = BinaryOps.safeIntBigInt - BigInt.one;
      final bytes = encodeBytes(v, 8);
      expect(
        () => IntUtils.fromBytes(bytes, sign: true),
        throwsArgumentException,
      );
    });

    test('REGRESSION: this is the exact bug that motivated isSafeInt() — '
        'isValidInt alone previously let 2^63 - 1 through even though it is '
        'not exactly representable as a JS double on web. Note: isValidInt '
        'itself is unreliable near the int64 boundary on web (in both '
        'directions), so we only assert on isSafeInt() and the resulting '
        'throw behavior, not on isValidInt.', () {
      final tooLargeToBeSafe = BigInt.two.pow(63) - BigInt.one;
      expect(tooLargeToBeSafe.isSafeInt(), isFalse);

      final bytes = encodeBytes(tooLargeToBeSafe, 8);
      expect(
        () => IntUtils.fromBytes(bytes, sign: true),
        throwsArgumentException,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(intTest, "Int");
}

import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

/// Independent reference decoder — built via hex-string parsing instead of
/// the accumulate-by-multiplication loop the real implementation uses, so a
/// bug in the loop/sign logic won't silently agree with itself.
BigInt referenceDecode(
  List<int> bytes, {
  int offset = 0,
  int? length,
  Endian byteOrder = Endian.big,
  bool sign = false,
}) {
  final len = length ?? (bytes.length - offset);
  if (len == 0) return BigInt.zero;

  final slice = bytes.sublist(offset, offset + len);
  final ordered = byteOrder == Endian.little ? slice.reversed.toList() : slice;

  final hex = ordered.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  BigInt result = BigInt.parse(hex, radix: 16);

  if (sign && (ordered[0] & 0x80) != 0) {
    result -= BigInt.one << (len * 8);
  }
  return result;
}

void expectMatchesReference(
  List<int> bytes, {
  int offset = 0,
  int? length,
  Endian byteOrder = Endian.big,
  bool sign = false,
}) {
  final actual = BigintUtils.fromBytes(
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

void bigintTest() {
  group('empty / zero-length', () {
    test('empty list returns zero', () {
      expect(BigintUtils.fromBytes(<int>[]), BigInt.zero);
      expect(BigintUtils.fromBytes(<int>[], sign: true), BigInt.zero);
    });

    test('explicit length: 0 returns zero regardless of offset', () {
      expect(
        BigintUtils.fromBytes([1, 2, 3], offset: 1, length: 0),
        BigInt.zero,
      );
    });
  });

  group('single byte, unsigned', () {
    for (final b in [0x00, 0x01, 0x7F, 0x80, 0xFF]) {
      test('0x${b.toRadixString(16)}', () {
        expectMatchesReference([b], sign: false);
        expect(BigintUtils.fromBytes([b], sign: false), BigInt.from(b));
      });
    }
  });

  group('single byte, signed (two\'s complement)', () {
    test('0x00 -> 0', () {
      expect(BigintUtils.fromBytes([0x00], sign: true), BigInt.zero);
    });
    test('0x7F -> 127 (max positive for 1 byte)', () {
      expect(BigintUtils.fromBytes([0x7F], sign: true), BigInt.from(127));
    });
    test('0x80 -> -128 (most negative for 1 byte)', () {
      expect(BigintUtils.fromBytes([0x80], sign: true), BigInt.from(-128));
    });
    test('0xFF -> -1', () {
      expect(BigintUtils.fromBytes([0xFF], sign: true), BigInt.from(-1));
    });
    test('0x01 -> 1', () {
      expect(BigintUtils.fromBytes([0x01], sign: true), BigInt.one);
    });
  });

  group('all-0xFF sequences (all-ones)', () {
    for (final len in [1, 2, 4, 8, 16, 32]) {
      final bytes = List<int>.filled(len, 0xFF);
      test('len=$len unsigned == 2^${len * 8} - 1', () {
        final expected = (BigInt.one << (len * 8)) - BigInt.one;
        expect(BigintUtils.fromBytes(bytes, sign: false), expected);
      });
      test('len=$len signed == -1', () {
        expect(BigintUtils.fromBytes(bytes, sign: true), BigInt.from(-1));
      });
    }
  });

  group('most-negative pattern (0x80 followed by zeros)', () {
    for (final len in [1, 2, 4, 8, 16, 32]) {
      final bytes = [0x80, ...List<int>.filled(len - 1, 0x00)];
      test('len=$len signed == -2^${len * 8 - 1}', () {
        final expected = -(BigInt.one << (len * 8 - 1));
        expect(BigintUtils.fromBytes(bytes, sign: true), expected);
      });
      test('len=$len unsigned == 2^${len * 8 - 1}', () {
        final expected = BigInt.one << (len * 8 - 1);
        expect(BigintUtils.fromBytes(bytes, sign: false), expected);
      });
    }
  });

  group('max-positive pattern (0x7F followed by 0xFFs)', () {
    for (final len in [2, 4, 8, 16, 32]) {
      final bytes = [0x7F, ...List<int>.filled(len - 1, 0xFF)];
      test('len=$len signed == 2^${len * 8 - 1} - 1', () {
        final expected = (BigInt.one << (len * 8 - 1)) - BigInt.one;
        expect(BigintUtils.fromBytes(bytes, sign: true), expected);
      });
    }
  });

  group('leading zero byte does not flip sign', () {
    test('[0x00, 0xFF] signed == 255, not negative', () {
      // The sign bit check only looks at ordered[0] (the true MSB of the
      // given range) — a leading 0x00 means "positive" even though the
      // *next* byte's high bit is set.
      expect(BigintUtils.fromBytes([0x00, 0xFF], sign: true), BigInt.from(255));
    });

    test('little-endian equivalent: [0xFF, 0x00] signed == 255', () {
      expect(
        BigintUtils.fromBytes(
          [0xFF, 0x00],
          byteOrder: Endian.little,
          sign: true,
        ),
        BigInt.from(255),
      );
    });
  });

  group('big-endian vs little-endian consistency', () {
    test('reversing bytes + swapping byteOrder yields same value', () {
      final be = [0x12, 0x34, 0x56, 0x78, 0x9A];
      final le = be.reversed.toList();

      final a = BigintUtils.fromBytes(be, byteOrder: Endian.big, sign: true);
      final b = BigintUtils.fromBytes(le, byteOrder: Endian.little, sign: true);
      expect(a, b);
    });

    test('random-ish vectors match reference for both byte orders', () {
      final vectors = <List<int>>[
        [0x01, 0x02, 0x03, 0x04],
        [0xDE, 0xAD, 0xBE, 0xEF],
        [0x00, 0x7F, 0x80, 0xFF, 0x01],
        List<int>.generate(32, (i) => (i * 37 + 11) & 0xFF), // 32-byte spread
      ];
      for (final v in vectors) {
        for (final order in [Endian.big, Endian.little]) {
          for (final sign in [true, false]) {
            expectMatchesReference(v, byteOrder: order, sign: sign);
          }
        }
      }
    });
  });

  group('offset / length slicing', () {
    final buf = List<int>.generate(64, (i) => i); // 0..63

    test('offset only, reads to end', () {
      expectMatchesReference(buf, offset: 60);
      expect(
        BigintUtils.fromBytes(buf, offset: 60),
        BigintUtils.fromBytes(buf.sublist(60)),
      );
    });

    test('offset + explicit length, middle of buffer', () {
      expectMatchesReference(buf, offset: 10, length: 8, sign: true);
      expect(
        BigintUtils.fromBytes(buf, offset: 10, length: 8, sign: true),
        BigintUtils.fromBytes(buf.sublist(10, 18), sign: true),
      );
    });

    test('offset + length, little endian', () {
      expectMatchesReference(
        buf,
        offset: 5,
        length: 16,
        byteOrder: Endian.little,
      );
    });

    test('offset at exact end with length 0', () {
      expect(
        BigintUtils.fromBytes(buf, offset: buf.length, length: 0),
        BigInt.zero,
      );
    });

    test('large buffer: only the requested window is decoded correctly', () {
      // A big list standing in for "huge input" — verifies offset math
      // doesn't accidentally include/exclude neighboring bytes.
      final big = List<int>.generate(10000, (i) => i & 0xFF);
      expectMatchesReference(big, offset: 9000, length: 32, sign: true);
      expectMatchesReference(
        big,
        offset: 9968,
        length: 32,
        byteOrder: Endian.little,
      );
    });
  });

  group('invalid offset / length', () {
    test('negative offset throws', () {
      expect(
        () => BigintUtils.fromBytes([1, 2, 3], offset: -1),
        throwsA(isA<BuError>()),
      );
    });

    test('negative length throws', () {
      expect(
        () => BigintUtils.fromBytes([1, 2, 3], offset: 1, length: -1),
        throwsA(isA<BuError>()),
      );
    });

    test('offset + length exceeds bytes.length throws', () {
      expect(
        () => BigintUtils.fromBytes([1, 2, 3], offset: 2, length: 5),
        throwsA(isA<BuError>()),
      );
    });

    test('offset == bytes.length with no explicit length is fine (== 0)', () {
      expect(BigintUtils.fromBytes([1, 2, 3], offset: 3), BigInt.zero);
    });

    test('offset > bytes.length throws', () {
      expect(
        () => BigintUtils.fromBytes([1, 2, 3], offset: 4),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('round trip against a very large value (well beyond 2^53)', () {
    // This is the case most likely to expose a *web* (dart2js) regression:
    // if any intermediate step ever used a native `int`/`double` instead of
    // BigInt, precision would silently degrade above 2^53 on web, while
    // native (64-bit int VM) might still happen to be correct or throw
    // differently. This implementation uses BigInt throughout the loop, so
    // both platforms should produce byte-for-byte identical results.
    test('256-byte (2048-bit) value matches reference decoder', () {
      final bytes = List<int>.generate(256, (i) => (i * 251 + 7) & 0xFF);
      expectMatchesReference(bytes, sign: false);
      expectMatchesReference(bytes, sign: true);
      expectMatchesReference(bytes, byteOrder: Endian.little, sign: true);
    });

    test('value exceeds double precision (2^53) sanity check', () {
      // 8 bytes all 0xFF => 2^64 - 1, far above 2^53 ~= 9.007e15.
      final v = BigintUtils.fromBytes(List<int>.filled(8, 0xFF));
      expect(v > BigInt.parse('9007199254740992'), isTrue); // > 2^53
      expect(v, (BigInt.one << 64) - BigInt.one);
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(bigintTest, "Bigint");
}

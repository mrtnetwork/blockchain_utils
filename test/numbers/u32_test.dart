import 'dart:math';
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/numbers.dart';
import 'package:test/test.dart';

import 'helpers/oracle.dart';

const _bits = 32;

void main() {
  final rnd = Random(0xC0FFEE);
  final interesting = interestingUnsigned(_bits);

  group('Uint32 constants', () {
    test('zero/one/two/max match BigInt', () {
      expect(Uint32.zero.toBigInt(), BigInt.zero);
      expect(Uint32.one.toBigInt(), BigInt.one);
      expect(Uint32.two.toBigInt(), BigInt.two);
      expect(Uint32.max.toBigInt(), maxUnsigned(_bits));
    });
  });

  group('Uint32 construction', () {
    test('new throws on negative', () {
      expect(() => Uint32(-1), throwsA(isA<ArgumentException>()));
    });

    test('new matches value for in-range non-negative ints', () {
      for (final v in [0, 1, 2, 0xFFFF, 0xFFFFFFFF]) {
        expect(Uint32(v).toBigInt(), BigInt.from(v));
      }
    });

    test(
      'from wraps negative values via two\'s complement, matches oracle',
      () {
        for (final v in [
          -1,
          -2,
          -0x80000000,
          -0xFFFFFFFF,
          0,
          1,
          0xFFFFFFFF,
          5,
          -5,
        ]) {
          expect(
            Uint32.from(v).toBigInt(),
            wrapUnsigned(BigInt.from(v), _bits),
            reason: 'Uint32.from($v)',
          );
        }
      },
    );

    test('fromBigInt round-trips and rejects negative', () {
      for (final v in interesting) {
        expect(Uint32.fromBigInt(v).toBigInt(), v);
      }
      expect(
        () => Uint32.fromBigInt(-BigInt.one),
        throwsA(isA<ArgumentException>()),
      );
    });

    test('parseHex round-trips with toHexString', () {
      for (final v in interesting) {
        final hex = v.toRadixString(16).padLeft(8, '0');
        expect(Uint32.parseHex('0x$hex').toBigInt(), v);
        expect(Uint32.parseHex(hex).toHexString(), hex);
      }
      expect(
        () => Uint32.parseHex('0xZZZZ'),
        throwsA(isA<ArgumentException>()),
      );
      expect(
        () => Uint32.parseHex('0x1FFFFFFFF'),
        throwsA(isA<ArgumentException>()),
      ); // > 8 hex digits
    });

    test(
      'parseDecimal round-trips with toString, throws on overflow/garbage',
      () {
        for (final v in interesting) {
          expect(Uint32.parseDecimal(v.toString()).toBigInt(), v);
        }
        expect(
          () => Uint32.parseDecimal('4294967296'),
          throwsA(isA<IntegerError>()),
        ); // 2^32
        expect(
          () => Uint32.parseDecimal('-1'),
          throwsA(isA<ArgumentException>()),
        );
        expect(
          () => Uint32.parseDecimal('12x'),
          throwsA(isA<ArgumentException>()),
        );
        expect(
          () => Uint32.parseDecimal(''),
          throwsA(isA<ArgumentException>()),
        );
      },
    );
  });

  group('Uint32 byte encoding', () {
    test('toBytes/fromBytes round-trip, big and little endian', () {
      for (final v in interesting) {
        final x = Uint32.fromBigInt(v);
        for (final e in [Endian.big, Endian.little]) {
          final bytes = x.toBytes(e);
          expect(bytes.length, 4);
          expect(
            Uint32.fromBytes(bytes, endian: e).toBigInt(),
            v,
            reason: '$v / $e',
          );
        }
      }
    });

    test('big-endian byte order is most-significant-first', () {
      final x = Uint32.parseHex('0x01020304');
      expect(x.toBytes(Endian.big), [0x01, 0x02, 0x03, 0x04]);
      expect(x.toBytes(Endian.little), [0x04, 0x03, 0x02, 0x01]);
    });

    test('fromBytes rejects wrong length', () {
      expect(
        () => Uint32.fromBytes([1, 2, 3]),
        throwsA(isA<ArgumentException>()),
      );
    });
  });

  group('Uint32 wrapping arithmetic vs BigInt oracle', () {
    test('addition (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final expected = wrapUnsigned(a + b, _bits);
        expect(
          (Uint32.fromBigInt(a) + Uint32.fromBigInt(b)).toBigInt(),
          expected,
          reason: '$a + $b',
        );
      }
    });

    test('addition (random)', () {
      for (var i = 0; i < 500; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final expected = wrapUnsigned(a + b, _bits);
        expect(
          (Uint32.fromBigInt(a) + Uint32.fromBigInt(b)).toBigInt(),
          expected,
          reason: '$a + $b',
        );
      }
    });

    test('subtraction (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final expected = wrapUnsigned(a - b, _bits);
        expect(
          (Uint32.fromBigInt(a) - Uint32.fromBigInt(b)).toBigInt(),
          expected,
          reason: '$a - $b',
        );
      }
    });

    test('subtraction (random)', () {
      for (var i = 0; i < 500; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final expected = wrapUnsigned(a - b, _bits);
        expect(
          (Uint32.fromBigInt(a) - Uint32.fromBigInt(b)).toBigInt(),
          expected,
          reason: '$a - $b',
        );
      }
    });

    test('multiplication (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final expected = wrapUnsigned(a * b, _bits);
        expect(
          (Uint32.fromBigInt(a) * Uint32.fromBigInt(b)).toBigInt(),
          expected,
          reason: '$a * $b',
        );
      }
    });

    test('multiplication (random)', () {
      for (var i = 0; i < 500; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final expected = wrapUnsigned(a * b, _bits);
        expect(
          (Uint32.fromBigInt(a) * Uint32.fromBigInt(b)).toBigInt(),
          expected,
          reason: '$a * $b',
        );
      }
    });

    test(
      'division/modulo (interesting x interesting, skipping zero divisor)',
      () {
        for (final (a, b) in pairs(interesting, interesting)) {
          if (b == BigInt.zero) continue;
          final x = Uint32.fromBigInt(a);
          final y = Uint32.fromBigInt(b);
          expect((x ~/ y).toBigInt(), a ~/ b, reason: '$a ~/ $b');
          expect((x % y).toBigInt(), a % b, reason: '$a % $b');
        }
      },
    );

    test('division by zero throws', () {
      expect(() => Uint32.one ~/ Uint32.zero, throwsA(isA<IntegerError>()));
      expect(() => Uint32.one % Uint32.zero, throwsA(isA<IntegerError>()));
    });

    test('negation is two\'s complement (wraps), matches oracle', () {
      for (final v in interesting) {
        expect((-Uint32.fromBigInt(v)).toBigInt(), wrapUnsigned(-v, _bits));
      }
    });
  });

  group('Uint32 checked arithmetic vs BigInt oracle', () {
    test('addChecked matches oracle overflow condition', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint32.fromBigInt(a);
        final y = Uint32.fromBigInt(b);
        final trueSum = a + b;
        if (trueSum > maxUnsigned(_bits)) {
          expect(
            () => x.addChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a + $b should overflow',
          );
        } else {
          expect(x.addChecked(y).toBigInt(), trueSum, reason: '$a + $b');
        }
      }
    });

    test('subChecked matches oracle underflow condition', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint32.fromBigInt(a);
        final y = Uint32.fromBigInt(b);
        if (a < b) {
          expect(
            () => x.subChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a - $b should underflow',
          );
        } else {
          expect(x.subChecked(y).toBigInt(), a - b, reason: '$a - $b');
        }
      }
    });

    test('mulChecked matches oracle overflow condition', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint32.fromBigInt(a);
        final y = Uint32.fromBigInt(b);
        final trueProduct = a * b;
        if (trueProduct > maxUnsigned(_bits)) {
          expect(
            () => x.mulChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a * $b should overflow',
          );
        } else {
          expect(x.mulChecked(y).toBigInt(), trueProduct, reason: '$a * $b');
        }
      }
    });
  });

  group('Uint32 bitwise operators vs BigInt oracle', () {
    test('& | ^ ~', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint32.fromBigInt(a);
        final y = Uint32.fromBigInt(b);
        expect((x & y).toBigInt(), a & b, reason: '$a & $b');
        expect((x | y).toBigInt(), a | b, reason: '$a | $b');
        expect((x ^ y).toBigInt(), a ^ b, reason: '$a ^ $b');
      }
      for (final a in interesting) {
        expect(
          (~Uint32.fromBigInt(a)).toBigInt(),
          wrapUnsigned(~a, _bits),
          reason: '~$a',
        );
      }
    });

    test('<< masks the shift amount to width and matches oracle', () {
      for (final v in interesting) {
        for (var shift = 0; shift <= _bits + 4; shift++) {
          final expected = wrapUnsigned(v << (shift & (_bits - 1)), _bits);
          expect(
            (Uint32.fromBigInt(v) << shift).toBigInt(),
            expected,
            reason: '$v << $shift',
          );
        }
      }
    });

    test('>> is logical (unsigned) and matches oracle', () {
      for (final v in interesting) {
        for (var shift = 0; shift <= _bits + 4; shift++) {
          final expected = v >> (shift & (_bits - 1));
          expect(
            (Uint32.fromBigInt(v) >> shift).toBigInt(),
            expected,
            reason: '$v >> $shift',
          );
        }
      }
    });
  });

  group('Uint32 comparisons', () {
    test('compareTo / < / <= / > / >= match BigInt ordering', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint32.fromBigInt(a);
        final y = Uint32.fromBigInt(b);
        expect(x.compareTo(y).sign, a.compareTo(b).sign, reason: '$a <=> $b');
        expect(x < y, a < b);
        expect(x <= y, a <= b);
        expect(x > y, a > b);
        expect(x >= y, a >= b);
        expect(x == y, a == b);
      }
    });

    test('equal values have equal hashCodes', () {
      for (final v in interesting) {
        expect(Uint32.fromBigInt(v).hashCode, Uint32.fromBigInt(v).hashCode);
      }
    });

    test('isZero / isEven', () {
      expect(Uint32.zero.isZero, isTrue);
      expect(Uint32.one.isZero, isFalse);
      for (final v in interesting) {
        expect(Uint32.fromBigInt(v).isEven, v.isEven, reason: '$v');
      }
    });
  });

  group(
    'Uint32 cross-type converter sanity (full matrix lives in conversions_test.dart)',
    () {
      test('toUint64/toInt32 spot checks', () {
        expect(Uint32.max.toUint64().toBigInt(), maxUnsigned(_bits));
        expect(
          Uint32.max.toInt32().toBigInt(),
          -BigInt.one,
        ); // all-ones reinterpreted signed
      });
    },
  );
}

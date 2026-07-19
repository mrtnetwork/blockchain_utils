import 'dart:math';
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:test/test.dart';

import 'helpers/oracle.dart';

const _bits = 128;

void main() {
  final rnd = Random(0xC0FFEE);
  final interesting = interestingUnsigned(_bits);

  group('Uint128 constants', () {
    test('zero/one/max match BigInt', () {
      expect(Uint128.zero.toBigInt(), BigInt.zero);
      expect(Uint128.one.toBigInt(), BigInt.one);
      expect(Uint128.max.toBigInt(), maxUnsigned(_bits));
    });
  });

  group('Uint128 construction', () {
    test('new throws on negative', () {
      expect(() => Uint128(-1), throwsA(isA<ArgumentException>()));
    });

    test(
      'from wraps negative values via two\'s complement, matches oracle, BigInt-free',
      () {
        for (final v in [
          -1,
          -2,
          -0x7FFFFFFF,
          0,
          1,
          5,
          -5,
          9007199254740991,
          -9007199254740991,
        ]) {
          expect(
            Uint128.from(v).toBigInt(),
            wrapUnsigned(BigInt.from(v), _bits),
            reason: 'Uint128.from($v)',
          );
        }
      },
    );

    test('fromUint64 zero-extends', () {
      for (final v in interestingUnsigned(64)) {
        final x = Uint128.fromUint64(Uint64.fromBigInt(v));
        expect(x.hi.toBigInt(), BigInt.zero);
        expect(x.toBigInt(), v);
      }
    });

    test('fromBigInt round-trips and rejects negative', () {
      for (final v in interesting) {
        expect(Uint128.fromBigInt(v).toBigInt(), v);
      }
      expect(() => Uint128.fromBigInt(-BigInt.one), throwsA(isA<ArgumentException>()));
    });

    test('parseHex round-trips with toHexString', () {
      for (final v in interesting) {
        final hex = v.toRadixString(16).padLeft(32, '0');
        expect(Uint128.parseHex('0x$hex').toBigInt(), v);
        expect(Uint128.parseHex(hex).toHexString(), hex);
      }
      expect(() => Uint128.parseHex('0xZZ'), throwsA(isA<ArgumentException>()));
    });

    test('parseDecimal round-trips, throws on overflow/garbage', () {
      for (final v in interesting) {
        expect(Uint128.parseDecimal(v.toString()).toBigInt(), v);
      }
      expect(
        () => Uint128.parseDecimal((maxUnsigned(_bits) + BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(() => Uint128.parseDecimal('-1'), throwsA(isA<ArgumentException>()));
    });
  });

  group('Uint128 conversions', () {
    test('hi/lo limbs are consistent with toBigInt', () {
      for (final v in interesting) {
        final x = Uint128.fromBigInt(v);
        expect((x.hi.toBigInt() << 64) | x.lo.toBigInt(), v);
      }
    });

    test('toInt throws when it would lose precision', () {
      expect(Uint128.fromBigInt(BigInt.from(12345)).toInt(), 12345);
      expect(() => Uint128.max.toInt(), throwsA(isA<IntegerError>()));
    });

    test('toString matches BigInt decimal representation', () {
      for (final v in interesting) {
        expect(Uint128.fromBigInt(v).toString(), v.toString());
      }
    });

    test('toBytes/fromBytes round-trip, big and little endian', () {
      for (final v in interesting) {
        final x = Uint128.fromBigInt(v);
        for (final e in [Endian.big, Endian.little]) {
          final bytes = x.toBytes(e);
          expect(bytes.length, 16);
          expect(Uint128.fromBytes(bytes, endian: e).toBigInt(), v, reason: '$v / $e');
        }
      }
      expect(
        () => Uint128.fromBytes(List.filled(15, 0)),
        throwsA(isA<ArgumentException>()),
      );
    });
  });

  group('Uint128 wrapping arithmetic vs BigInt oracle', () {
    test('add/sub (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint128.fromBigInt(a);
        final y = Uint128.fromBigInt(b);
        expect((x + y).toBigInt(), wrapUnsigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapUnsigned(a - b, _bits), reason: '$a - $b');
      }
    });

    test(
      'multiplication, built from widenMul + cross terms (interesting x interesting)',
      () {
        for (final (a, b) in pairs(interesting, interesting)) {
          final x = Uint128.fromBigInt(a);
          final y = Uint128.fromBigInt(b);
          expect((x * y).toBigInt(), wrapUnsigned(a * b, _bits), reason: '$a * $b');
        }
      },
    );

    test('add/sub/mul (random)', () {
      for (var i = 0; i < 600; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final x = Uint128.fromBigInt(a);
        final y = Uint128.fromBigInt(b);
        expect((x + y).toBigInt(), wrapUnsigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapUnsigned(a - b, _bits), reason: '$a - $b');
        expect((x * y).toBigInt(), wrapUnsigned(a * b, _bits), reason: '$a * $b');
      }
    });

    test('division/modulo (interesting x interesting, skipping zero divisor)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        if (b == BigInt.zero) continue;
        final x = Uint128.fromBigInt(a);
        final y = Uint128.fromBigInt(b);
        expect((x ~/ y).toBigInt(), a ~/ b, reason: '$a ~/ $b');
        expect((x % y).toBigInt(), a % b, reason: '$a % $b');
      }
    });

    test('division by zero throws', () {
      expect(() => Uint128.one ~/ Uint128.zero, throwsA(isA<IntegerError>()));
      expect(() => Uint128.one % Uint128.zero, throwsA(isA<IntegerError>()));
    });
  });

  group('Uint128 checked arithmetic vs BigInt oracle', () {
    test('addChecked / subChecked / mulChecked', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint128.fromBigInt(a);
        final y = Uint128.fromBigInt(b);

        final sum = a + b;
        if (sum > maxUnsigned(_bits)) {
          expect(() => x.addChecked(y), throwsA(isA<IntegerError>()), reason: '$a + $b');
        } else {
          expect(x.addChecked(y).toBigInt(), sum);
        }

        if (a < b) {
          expect(() => x.subChecked(y), throwsA(isA<IntegerError>()), reason: '$a - $b');
        } else {
          expect(x.subChecked(y).toBigInt(), a - b);
        }

        final prod = a * b;
        if (prod > maxUnsigned(_bits)) {
          expect(() => x.mulChecked(y), throwsA(isA<IntegerError>()), reason: '$a * $b');
        } else {
          expect(x.mulChecked(y).toBigInt(), prod);
        }
      }
    });
  });

  group('Uint128 bitwise operators vs BigInt oracle', () {
    test('& | ^ ~', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint128.fromBigInt(a);
        final y = Uint128.fromBigInt(b);
        expect((x & y).toBigInt(), a & b, reason: '$a & $b');
        expect((x | y).toBigInt(), a | b, reason: '$a | $b');
        expect((x ^ y).toBigInt(), a ^ b, reason: '$a ^ $b');
      }
      for (final a in interesting) {
        expect(
          (~Uint128.fromBigInt(a)).toBigInt(),
          wrapUnsigned(~a, _bits),
          reason: '~$a',
        );
      }
    });

    test('<< and >> mask the shift amount to width and match oracle', () {
      for (final v in interesting) {
        for (var shift = 0; shift <= _bits + 8; shift += 7) {
          final s = shift & (_bits - 1);
          expect(
            (Uint128.fromBigInt(v) << shift).toBigInt(),
            wrapUnsigned(v << s, _bits),
            reason: '$v << $shift',
          );
          expect(
            (Uint128.fromBigInt(v) >> shift).toBigInt(),
            v >> s,
            reason: '$v >> $shift',
          );
        }
      }
    });

    test('shift exactly across the 64-bit limb boundary', () {
      final v = interesting[0] == BigInt.zero ? BigInt.one : interesting[0];
      for (final shift in [63, 64, 65]) {
        expect(
          (Uint128.fromBigInt(v) << shift).toBigInt(),
          wrapUnsigned(v << shift, _bits),
        );
        expect((Uint128.fromBigInt(v) >> shift).toBigInt(), v >> shift);
      }
    });
  });

  group('Uint128 comparisons', () {
    test('compareTo / < / <= / > / >= / == match BigInt ordering', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint128.fromBigInt(a);
        final y = Uint128.fromBigInt(b);
        expect(x.compareTo(y).sign, a.compareTo(b).sign, reason: '$a <=> $b');
        expect(x < y, a < b);
        expect(x <= y, a <= b);
        expect(x > y, a > b);
        expect(x >= y, a >= b);
        expect(x == y, a == b);
      }
    });
  });
}

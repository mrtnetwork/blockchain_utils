import 'dart:math';
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/numbers.dart';
import 'package:test/test.dart';

import 'helpers/oracle.dart';

const _bits = 32;

void main() {
  final rnd = Random(0xC0FFEE);
  final interesting = interestingSigned(_bits);

  group('Int32 constants', () {
    test('zero/one/minusOne/max/min/mask8 match BigInt', () {
      expect(Int32.zero.toBigInt(), BigInt.zero);
      expect(Int32.one.toBigInt(), BigInt.one);
      expect(Int32.minusOne.toBigInt(), -BigInt.one);
      expect(Int32.max.toBigInt(), maxSigned(_bits));
      expect(Int32.min.toBigInt(), minSigned(_bits));
      expect(Int32.mask8.toBigInt(), BigInt.from(0xFF));
    });
  });

  group('Int32 construction', () {
    test('new wraps any int via two\'s complement, matches oracle', () {
      for (final v in [
        -1,
        -2,
        0,
        1,
        0x7FFFFFFF,
        -0x80000000,
        0x80000000,
        -0x80000001,
      ]) {
        expect(
          Int32(v).toBigInt(),
          wrapSigned(BigInt.from(v), _bits),
          reason: 'Int32($v)',
        );
      }
    });

    test('fromBigInt wraps any BigInt, matches oracle', () {
      for (final v in interesting) {
        expect(Int32.fromBigInt(v).toBigInt(), wrapSigned(v, _bits));
      }
      expect(
        Int32.fromBigInt(maxUnsigned(_bits) + BigInt.one).toBigInt(),
        wrapSigned(maxUnsigned(_bits) + BigInt.one, _bits),
      );
    });

    test(
      'parseHex round-trips with toHexString (bit pattern, not decimal)',
      () {
        for (final v in interesting) {
          final bits = wrapUnsigned(v, _bits);
          final hex = bits.toRadixString(16).padLeft(8, '0');
          expect(Int32.parseHex('0x$hex').toBigInt(), v);
          expect(Int32.parseHex(hex).toHexString(), hex);
        }
      },
    );

    test('parseDecimal round-trips, throws on overflow/underflow/garbage', () {
      for (final v in interesting) {
        expect(Int32.parseDecimal(v.toString()).toBigInt(), v);
      }
      expect(
        () => Int32.parseDecimal((maxSigned(_bits) + BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(
        () => Int32.parseDecimal((minSigned(_bits) - BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(
        () => Int32.parseDecimal('12x'),
        throwsA(isA<ArgumentException>()),
      );
      expect(() => Int32.parseDecimal(''), throwsA(isA<ArgumentException>()));
      // boundary values must succeed exactly
      expect(Int32.parseDecimal(minSigned(_bits).toString()), Int32.min);
      expect(Int32.parseDecimal(maxSigned(_bits).toString()), Int32.max);
    });
  });

  group('Int32 conversions', () {
    test('toInt/toBigInt/toString/toHexString agree with the oracle', () {
      for (final v in interesting) {
        final x = Int32.fromBigInt(v);
        expect(x.toInt(), v.toInt());
        expect(x.toBigInt(), v);
        expect(x.toString(), v.toString());
        expect(
          x.toHexString(),
          wrapUnsigned(v, _bits).toRadixString(16).padLeft(8, '0'),
        );
      }
    });

    test('toBytes/fromBytes round-trip (two\'s complement bit pattern)', () {
      for (final v in interesting) {
        final x = Int32.fromBigInt(v);
        for (final e in [Endian.big, Endian.little]) {
          final bytes = x.toBytes(e);
          expect(bytes.length, 4);
          expect(
            Int32.fromBytes(bytes, endian: e).toBigInt(),
            v,
            reason: '$v / $e',
          );
        }
      }
    });

    test('isNegative / isZero / isEven match the oracle', () {
      for (final v in interesting) {
        final x = Int32.fromBigInt(v);
        expect(x.isNegative, v.isNegative, reason: '$v');
        expect(x.isZero, v == BigInt.zero, reason: '$v');
        expect(x.isEven, v.isEven, reason: '$v');
      }
    });

    test('toUint8 keeps the low byte regardless of sign', () {
      expect(Int32.minusOne.toUint8(), 0xFF);
      expect(Int32(256).toUint8(), 0);
      expect(Int32(-256).toUint8(), 0);
      expect(Int32(-255).toUint8(), 1);
    });
  });

  group('Int32 wrapping arithmetic vs BigInt oracle', () {
    test('add/sub/mul (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int32.fromBigInt(a);
        final y = Int32.fromBigInt(b);
        expect((x + y).toBigInt(), wrapSigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapSigned(a - b, _bits), reason: '$a - $b');
        expect((x * y).toBigInt(), wrapSigned(a * b, _bits), reason: '$a * $b');
      }
    });

    test('add/sub/mul (random)', () {
      for (var i = 0; i < 800; i++) {
        final a = randomSigned(rnd, _bits);
        final b = randomSigned(rnd, _bits);
        final x = Int32.fromBigInt(a);
        final y = Int32.fromBigInt(b);
        expect((x + y).toBigInt(), wrapSigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapSigned(a - b, _bits), reason: '$a - $b');
        expect((x * y).toBigInt(), wrapSigned(a * b, _bits), reason: '$a * $b');
      }
    });

    test('negation and abs wrap to themselves at min', () {
      expect((-Int32.min).toBigInt(), minSigned(_bits));
      expect(Int32.min.abs().toBigInt(), minSigned(_bits));
      for (final v in interesting) {
        if (v == minSigned(_bits)) continue;
        expect((-Int32.fromBigInt(v)).toBigInt(), -v);
        expect(Int32.fromBigInt(v).abs().toBigInt(), v.abs());
      }
    });

    test(
      'truncating division/remainder toward zero (interesting x interesting)',
      () {
        for (final (a, b) in pairs(interesting, interesting)) {
          if (b == BigInt.zero) continue;
          final x = Int32.fromBigInt(a);
          final y = Int32.fromBigInt(b);
          final expectedQ = wrapSigned(
            a ~/ b,
            _bits,
          ); // covers the min/-1 wrap case too
          expect((x ~/ y).toBigInt(), expectedQ, reason: '$a ~/ $b');
          expect((x % y).toBigInt(), a.remainder(b), reason: '$a % $b');
        }
      },
    );

    test('division by zero throws', () {
      expect(() => Int32.one ~/ Int32.zero, throwsA(isA<IntegerError>()));
      expect(() => Int32.one % Int32.zero, throwsA(isA<IntegerError>()));
    });

    test('min ~/ minusOne wraps to min instead of throwing', () {
      expect(Int32.min ~/ Int32.minusOne, Int32.min);
      expect(Int32.min % Int32.minusOne, Int32.zero);
    });
  });

  group('Int32 checked arithmetic vs BigInt oracle', () {
    test('addChecked / subChecked match signed-overflow oracle', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int32.fromBigInt(a);
        final y = Int32.fromBigInt(b);

        final sum = a + b;
        if (sum > maxSigned(_bits) || sum < minSigned(_bits)) {
          expect(
            () => x.addChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a + $b',
          );
        } else {
          expect(x.addChecked(y).toBigInt(), sum);
        }

        final diff = a - b;
        if (diff > maxSigned(_bits) || diff < minSigned(_bits)) {
          expect(
            () => x.subChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a - $b',
          );
        } else {
          expect(x.subChecked(y).toBigInt(), diff);
        }
      }
    });

    test('mulChecked matches signed-overflow oracle', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int32.fromBigInt(a);
        final y = Int32.fromBigInt(b);
        final prod = a * b;
        if (prod > maxSigned(_bits) || prod < minSigned(_bits)) {
          expect(
            () => x.mulChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a * $b',
          );
        } else {
          expect(x.mulChecked(y).toBigInt(), prod, reason: '$a * $b');
        }
      }
    });

    group('regression: min/-1 edge cases (previously silently wrong)', () {
      test('subChecked(Int32.min) throws unless this is negative', () {
        expect(
          () => Int32.zero.subChecked(Int32.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          () => Int32.one.subChecked(Int32.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          () => Int32.max.subChecked(Int32.min),
          throwsA(isA<IntegerError>()),
        );
        // this - min only fits when this < 0: result = this + 2^31.
        expect(
          Int32.minusOne.subChecked(Int32.min).toBigInt(),
          maxSigned(_bits),
        );
        expect(Int32.min.subChecked(Int32.min), Int32.zero);
      });

      test(
        'mulChecked(Int32.min, Int32.minusOne) throws in both operand orders',
        () {
          expect(
            () => Int32.min.mulChecked(Int32.minusOne),
            throwsA(isA<IntegerError>()),
          );
          expect(
            () => Int32.minusOne.mulChecked(Int32.min),
            throwsA(isA<IntegerError>()),
          );
        },
      );
    });
  });

  group('Int32 bitwise/shift operators vs BigInt oracle', () {
    test('& | ^ ~ operate on the two\'s complement bit pattern', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int32.fromBigInt(a);
        final y = Int32.fromBigInt(b);
        final ua = wrapUnsigned(a, _bits);
        final ub = wrapUnsigned(b, _bits);
        expect(
          (x & y).toBigInt(),
          wrapSigned(ua & ub, _bits),
          reason: '$a & $b',
        );
        expect(
          (x | y).toBigInt(),
          wrapSigned(ua | ub, _bits),
          reason: '$a | $b',
        );
        expect(
          (x ^ y).toBigInt(),
          wrapSigned(ua ^ ub, _bits),
          reason: '$a ^ $b',
        );
      }
    });

    test('<< is logical (bits shifted out the top are discarded)', () {
      for (final v in interesting) {
        final u = wrapUnsigned(v, _bits);
        for (var shift = 0; shift <= _bits + 4; shift++) {
          final s = shift & (_bits - 1);
          final expected = wrapSigned(wrapUnsigned(u << s, _bits), _bits);
          expect(
            (Int32.fromBigInt(v) << shift).toBigInt(),
            expected,
            reason: '$v << $shift',
          );
        }
      }
    });

    test('>> is arithmetic (sign-propagating)', () {
      for (final v in interesting) {
        for (var shift = 0; shift <= _bits + 4; shift++) {
          final s = shift & (_bits - 1);
          // Arithmetic shift of a signed BigInt is just BigInt `>>`.
          expect(
            (Int32.fromBigInt(v) >> shift).toBigInt(),
            v >> s,
            reason: '$v >> $shift',
          );
        }
      }
    });

    test('>>> is logical (zero-filled) regardless of sign', () {
      for (final v in interesting) {
        final u = wrapUnsigned(v, _bits);
        for (var shift = 0; shift <= _bits + 4; shift++) {
          final s = shift & (_bits - 1);
          expect(
            (Int32.fromBigInt(v) >>> shift).toBigInt(),
            wrapSigned(u >> s, _bits),
            reason: '$v >>> $shift',
          );
        }
      }
    });
  });

  group('Int32 comparisons', () {
    test('compareTo / < / <= / > / >= / == match BigInt signed ordering', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int32.fromBigInt(a);
        final y = Int32.fromBigInt(b);
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

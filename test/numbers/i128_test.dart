import 'dart:math';
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/numbers.dart';
import 'package:test/test.dart';

import 'helpers/oracle.dart';

const _bits = 128;

void main() {
  final rnd = Random(0xC0FFEE);
  final interesting = interestingSigned(_bits);

  group('Int128 constants', () {
    test('zero/one/minusOne/max/min match BigInt', () {
      expect(Int128.zero.toBigInt(), BigInt.zero);
      expect(Int128.one.toBigInt(), BigInt.one);
      expect(Int128.minusOne.toBigInt(), -BigInt.one);
      expect(Int128.max.toBigInt(), maxSigned(_bits));
      expect(Int128.min.toBigInt(), minSigned(_bits));
    });
  });

  group('Int128 construction', () {
    test(
      'new wraps any double-safe int via two\'s complement, matches oracle',
      () {
        for (final v in [-1, -2, 0, 1, 9007199254740991, -9007199254740991]) {
          expect(
            Int128(v).toBigInt(),
            wrapSigned(BigInt.from(v), _bits),
            reason: 'Int128($v)',
          );
        }
      },
    );

    test('fromBigInt wraps any BigInt, matches oracle', () {
      for (final v in interesting) {
        expect(Int128.fromBigInt(v).toBigInt(), wrapSigned(v, _bits));
      }
      expect(
        Int128.fromBigInt(maxUnsigned(_bits) + BigInt.one).toBigInt(),
        wrapSigned(maxUnsigned(_bits) + BigInt.one, _bits),
      );
    });

    test(
      'parseHex round-trips with toHexString (bit pattern, not decimal)',
      () {
        for (final v in interesting) {
          final bits = wrapUnsigned(v, _bits);
          final hex = bits.toRadixString(16).padLeft(32, '0');
          expect(Int128.parseHex('0x$hex').toBigInt(), v);
          expect(Int128.parseHex(hex).toHexString(), hex);
        }
      },
    );

    test('parseDecimal round-trips, throws on overflow/underflow/garbage', () {
      for (final v in interesting) {
        expect(Int128.parseDecimal(v.toString()).toBigInt(), v);
      }
      expect(
        () => Int128.parseDecimal((maxSigned(_bits) + BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(
        () => Int128.parseDecimal((minSigned(_bits) - BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(
        () => Int128.parseDecimal('12x'),
        throwsA(isA<ArgumentException>()),
      );
      expect(Int128.parseDecimal(minSigned(_bits).toString()), Int128.min);
      expect(Int128.parseDecimal(maxSigned(_bits).toString()), Int128.max);
    });
  });

  group('Int128 conversions', () {
    test('toBigInt/toHexString agree with the oracle', () {
      for (final v in interesting) {
        final x = Int128.fromBigInt(v);
        expect(x.toBigInt(), v);
        expect(
          x.toHexString(),
          wrapUnsigned(v, _bits).toRadixString(16).padLeft(32, '0'),
        );
      }
    });

    test(
      'toInt throws when it would lose precision, matches oracle otherwise',
      () {
        expect(Int128.fromBigInt(BigInt.from(1234567890)).toInt(), 1234567890);
        expect(() => Int128.min.toInt(), throwsA(isA<IntegerError>()));
        expect(() => Int128.max.toInt(), throwsA(isA<IntegerError>()));
      },
    );

    test('toString matches BigInt decimal representation, incl. min', () {
      for (final v in interesting) {
        expect(Int128.fromBigInt(v).toString(), v.toString());
      }
    });

    test('toBytes/fromBytes round-trip (two\'s complement bit pattern)', () {
      for (final v in interesting) {
        final x = Int128.fromBigInt(v);
        for (final e in [Endian.big, Endian.little]) {
          final bytes = x.toBytes(e);
          expect(bytes.length, 16);
          expect(
            Int128.fromBytes(bytes, endian: e).toBigInt(),
            v,
            reason: '$v / $e',
          );
        }
      }
    });

    test('isNegative / isZero / isEven match the oracle', () {
      for (final v in interesting) {
        final x = Int128.fromBigInt(v);
        expect(x.isNegative, v.isNegative, reason: '$v');
        expect(x.isZero, v == BigInt.zero, reason: '$v');
        expect(x.isEven, v.isEven, reason: '$v');
      }
    });
  });

  group('Int128 wrapping arithmetic vs BigInt oracle', () {
    test('add/sub/mul (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int128.fromBigInt(a);
        final y = Int128.fromBigInt(b);
        expect((x + y).toBigInt(), wrapSigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapSigned(a - b, _bits), reason: '$a - $b');
        expect((x * y).toBigInt(), wrapSigned(a * b, _bits), reason: '$a * $b');
      }
    });

    test('add/sub/mul (random)', () {
      for (var i = 0; i < 600; i++) {
        final a = randomSigned(rnd, _bits);
        final b = randomSigned(rnd, _bits);
        final x = Int128.fromBigInt(a);
        final y = Int128.fromBigInt(b);
        expect((x + y).toBigInt(), wrapSigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapSigned(a - b, _bits), reason: '$a - $b');
        expect((x * y).toBigInt(), wrapSigned(a * b, _bits), reason: '$a * $b');
      }
    });

    test('negation and abs wrap to themselves at min', () {
      expect((-Int128.min).toBigInt(), minSigned(_bits));
      expect(Int128.min.abs().toBigInt(), minSigned(_bits));
      for (final v in interesting) {
        if (v == minSigned(_bits)) continue;
        expect((-Int128.fromBigInt(v)).toBigInt(), -v);
        expect(Int128.fromBigInt(v).abs().toBigInt(), v.abs());
      }
    });

    test(
      'truncating division/remainder toward zero (interesting x interesting)',
      () {
        for (final (a, b) in pairs(interesting, interesting)) {
          if (b == BigInt.zero) continue;
          final x = Int128.fromBigInt(a);
          final y = Int128.fromBigInt(b);
          expect(
            (x ~/ y).toBigInt(),
            wrapSigned(a ~/ b, _bits),
            reason: '$a ~/ $b',
          );
          expect((x % y).toBigInt(), a.remainder(b), reason: '$a % $b');
        }
      },
    );

    test('division by zero throws', () {
      expect(() => Int128.one ~/ Int128.zero, throwsA(isA<IntegerError>()));
      expect(() => Int128.one % Int128.zero, throwsA(isA<IntegerError>()));
    });

    test('min ~/ minusOne wraps to min instead of throwing', () {
      expect(Int128.min ~/ Int128.minusOne, Int128.min);
      expect(Int128.min % Int128.minusOne, Int128.zero);
    });
  });

  group('Int128 checked arithmetic vs BigInt oracle', () {
    test('addChecked / subChecked match signed-overflow oracle', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int128.fromBigInt(a);
        final y = Int128.fromBigInt(b);

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
        final x = Int128.fromBigInt(a);
        final y = Int128.fromBigInt(b);
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
      test('subChecked(Int128.min) throws unless this is negative', () {
        expect(
          () => Int128.zero.subChecked(Int128.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          () => Int128.one.subChecked(Int128.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          () => Int128.max.subChecked(Int128.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          Int128.minusOne.subChecked(Int128.min).toBigInt(),
          maxSigned(_bits),
        );
        expect(Int128.min.subChecked(Int128.min), Int128.zero);
      });

      test(
        'mulChecked(Int128.min, Int128.minusOne) throws in both operand orders',
        () {
          expect(
            () => Int128.min.mulChecked(Int128.minusOne),
            throwsA(isA<IntegerError>()),
          );
          expect(
            () => Int128.minusOne.mulChecked(Int128.min),
            throwsA(isA<IntegerError>()),
          );
        },
      );
    });
  });

  group('Int128 bitwise/shift operators vs BigInt oracle', () {
    test('& | ^ ~ operate on the two\'s complement bit pattern', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int128.fromBigInt(a);
        final y = Int128.fromBigInt(b);
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
        for (var shift = 0; shift <= _bits + 8; shift += 7) {
          final s = shift & (_bits - 1);
          final expected = wrapSigned(wrapUnsigned(u << s, _bits), _bits);
          expect(
            (Int128.fromBigInt(v) << shift).toBigInt(),
            expected,
            reason: '$v << $shift',
          );
        }
      }
    });

    test('>> is arithmetic (sign-propagating)', () {
      for (final v in interesting) {
        for (var shift = 0; shift <= _bits + 8; shift += 7) {
          final s = shift & (_bits - 1);
          expect(
            (Int128.fromBigInt(v) >> shift).toBigInt(),
            v >> s,
            reason: '$v >> $shift',
          );
        }
      }
    });

    test('unsignedShiftRight is logical (zero-filled) regardless of sign', () {
      for (final v in interesting) {
        final u = wrapUnsigned(v, _bits);
        for (var shift = 0; shift <= _bits + 8; shift += 7) {
          final s = shift & (_bits - 1);
          expect(
            Int128.fromBigInt(v).unsignedShiftRight(shift).toBigInt(),
            wrapSigned(u >> s, _bits),
            reason: '$v unsignedShiftRight $shift',
          );
        }
      }
    });

    test('shift exactly across every 64-bit limb boundary', () {
      final v = interesting.firstWhere((e) => e != BigInt.zero);
      final u = wrapUnsigned(v, _bits);
      for (final shift in [63, 64, 65]) {
        expect(
          (Int128.fromBigInt(v) << shift).toBigInt(),
          wrapSigned(wrapUnsigned(u << shift, _bits), _bits),
        );
        expect((Int128.fromBigInt(v) >> shift).toBigInt(), v >> shift);
      }
    });
  });

  group('Int128 comparisons', () {
    test('compareTo / < / <= / > / >= / == match BigInt signed ordering', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Int128.fromBigInt(a);
        final y = Int128.fromBigInt(b);
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

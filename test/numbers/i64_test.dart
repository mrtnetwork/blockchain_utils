import 'dart:math';
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/numbers.dart';
import 'package:test/test.dart';

import 'helpers/oracle.dart';

const _bits = 64;

void main() {
  final rnd = Random(0xC0FFEE);
  final interesting = interestingSigned(_bits);

  group('Int64 constants', () {
    test('zero/one/two/mask8/minusOne/max/min match BigInt', () {
      expect(Int64.zero.toBigInt(), BigInt.zero);
      expect(Int64.one.toBigInt(), BigInt.one);
      expect(Int64.two.toBigInt(), BigInt.two);
      expect(Int64.mask8.toBigInt(), BigInt.from(0xFF));
      expect(Int64.minusOne.toBigInt(), -BigInt.one);
      expect(Int64.max.toBigInt(), maxSigned(_bits));
      expect(Int64.min.toBigInt(), minSigned(_bits));
    });
  });

  group('Int64 construction', () {
    test(
      'new wraps any double-safe int via two\'s complement, matches oracle',
      () {
        for (final v in [
          -1,
          -2,
          0,
          1,
          9007199254740991,
          -9007199254740991,
          0x7FFFFFFF,
          -0x80000000,
        ]) {
          expect(
            Int64(v).toBigInt(),
            wrapSigned(BigInt.from(v), _bits),
            reason: 'Int64($v)',
          );
        }
      },
    );

    test(
      'fromBigInt wraps any BigInt, matches oracle; toBigInt round-trips',
      () {
        for (final v in interesting) {
          expect(Int64.fromBigInt(v).toBigInt(), wrapSigned(v, _bits));
        }
        expect(
          Int64.fromBigInt(maxUnsigned(_bits) + BigInt.one).toBigInt(),
          wrapSigned(maxUnsigned(_bits) + BigInt.one, _bits),
        );
      },
    );

    test(
      'parseHex round-trips with toHexString (bit pattern, not decimal)',
      () {
        for (final v in interesting) {
          final bits = wrapUnsigned(v, _bits);
          final hex = bits.toRadixString(16).padLeft(16, '0');
          expect(Int64.parseHex('0x$hex').toBigInt(), v);
          expect(Int64.parseHex(hex).toHexString(), hex);
        }
      },
    );

    test('parseDecimal round-trips, throws on overflow/underflow/garbage', () {
      for (final v in interesting) {
        expect(Int64.parseDecimal(v.toString()).toBigInt(), v);
      }
      expect(
        () => Int64.parseDecimal((maxSigned(_bits) + BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(
        () => Int64.parseDecimal((minSigned(_bits) - BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(
        () => Int64.parseDecimal('12x'),
        throwsA(isA<ArgumentException>()),
      );
      expect(Int64.parseDecimal(minSigned(_bits).toString()), Int64.min);
      expect(Int64.parseDecimal(maxSigned(_bits).toString()), Int64.max);
    });
  });

  group('Int64 conversions', () {
    test('toBigInt/toHexString agree with the oracle', () {
      for (final v in interesting) {
        final x = Int64.fromBigInt(v);
        expect(x.toBigInt(), v);
        expect(
          x.toHexString(),
          wrapUnsigned(v, _bits).toRadixString(16).padLeft(16, '0'),
        );
      }
    });

    test(
      'toInt throws when it would lose precision, matches oracle otherwise',
      () {
        expect(Int64(1234567890).toInt(), 1234567890);
        expect(() => Int64.min.toInt(), throwsA(isA<IntegerError>()));
        expect(() => Int64.max.toInt(), throwsA(isA<IntegerError>()));
      },
    );

    test('toString: regression test for the fixed dead-code bug', () {
      // Previously `toString()` had an unconditional early return before its
      // real logic and always printed "Int64.unsafe(...)" instead of the
      // decimal value — this must never regress.
      expect(Int64.zero.toString(), '0');
      expect(Int64.one.toString(), '1');
      expect(Int64.minusOne.toString(), '-1');
      expect(Int64.max.toString(), maxSigned(_bits).toString());
      expect(Int64.min.toString(), minSigned(_bits).toString());
      for (final v in interesting) {
        expect(
          Int64.fromBigInt(v).toString(),
          v.toString(),
          reason: v.toString(),
        );
      }
    });

    test('toBytes/fromBytes round-trip (two\'s complement bit pattern)', () {
      for (final v in interesting) {
        final x = Int64.fromBytes(_twosComplementBytes(v, _bits));
        for (final e in [Endian.big, Endian.little]) {
          final bytes = x.toBytes(e);
          expect(bytes.length, 8);
          expect(
            Int64.fromBytes(bytes, endian: e).toBigInt(),
            v,
            reason: '$v / $e',
          );
        }
      }
    });

    test('isNegative / isZero / isEven match the oracle', () {
      for (final v in interesting) {
        final x = Int64.fromBigInt(v);
        expect(x.isNegative, v.isNegative, reason: '$v');
        expect(x.isZero, v == BigInt.zero, reason: '$v');
        expect(x.isEven, v.isEven, reason: '$v');
      }
    });

    test('toUint8 keeps the low byte regardless of sign', () {
      expect(Int64.minusOne.toUint8(), 0xFF);
      expect(Int64(256).toUint8(), 0);
      expect(Int64(-255).toUint8(), 1);
    });
  });

  group('Int64 wrapping arithmetic vs BigInt oracle', () {
    test('add/sub/mul (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = _fromSigned(a);
        final y = _fromSigned(b);
        expect((x + y).toBigInt(), wrapSigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapSigned(a - b, _bits), reason: '$a - $b');
        expect((x * y).toBigInt(), wrapSigned(a * b, _bits), reason: '$a * $b');
      }
    });

    test('add/sub/mul (random)', () {
      for (var i = 0; i < 800; i++) {
        final a = randomSigned(rnd, _bits);
        final b = randomSigned(rnd, _bits);
        final x = _fromSigned(a);
        final y = _fromSigned(b);
        expect((x + y).toBigInt(), wrapSigned(a + b, _bits), reason: '$a + $b');
        expect((x - y).toBigInt(), wrapSigned(a - b, _bits), reason: '$a - $b');
        expect((x * y).toBigInt(), wrapSigned(a * b, _bits), reason: '$a * $b');
      }
    });

    test('negation and abs wrap to themselves at min', () {
      expect((-Int64.min).toBigInt(), minSigned(_bits));
      expect(Int64.min.abs().toBigInt(), minSigned(_bits));
      for (final v in interesting) {
        if (v == minSigned(_bits)) continue;
        expect((-_fromSigned(v)).toBigInt(), -v);
        expect(_fromSigned(v).abs().toBigInt(), v.abs());
      }
    });

    test(
      'truncating division/remainder toward zero (interesting x interesting)',
      () {
        for (final (a, b) in pairs(interesting, interesting)) {
          if (b == BigInt.zero) continue;
          final x = _fromSigned(a);
          final y = _fromSigned(b);
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
      expect(() => Int64.one ~/ Int64.zero, throwsA(isA<IntegerError>()));
      expect(() => Int64.one % Int64.zero, throwsA(isA<IntegerError>()));
    });

    test('min ~/ minusOne wraps to min instead of throwing', () {
      expect(Int64.min ~/ Int64.minusOne, Int64.min);
      expect(Int64.min % Int64.minusOne, Int64.zero);
    });
  });

  group('Int64 checked arithmetic vs BigInt oracle', () {
    test('addChecked / subChecked match signed-overflow oracle', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = _fromSigned(a);
        final y = _fromSigned(b);

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
        final x = _fromSigned(a);
        final y = _fromSigned(b);
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
      test('subChecked(Int64.min) throws unless this is negative', () {
        expect(
          () => Int64.zero.subChecked(Int64.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          () => Int64.one.subChecked(Int64.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          () => Int64.max.subChecked(Int64.min),
          throwsA(isA<IntegerError>()),
        );
        expect(
          Int64.minusOne.subChecked(Int64.min).toBigInt(),
          maxSigned(_bits),
        );
        expect(Int64.min.subChecked(Int64.min), Int64.zero);
      });

      test(
        'mulChecked(Int64.min, Int64.minusOne) throws in both operand orders',
        () {
          expect(
            () => Int64.min.mulChecked(Int64.minusOne),
            throwsA(isA<IntegerError>()),
          );
          expect(
            () => Int64.minusOne.mulChecked(Int64.min),
            throwsA(isA<IntegerError>()),
          );
        },
      );
    });
  });

  group('Int64 bitwise/shift operators vs BigInt oracle', () {
    test('& | ^ ~ operate on the two\'s complement bit pattern', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = _fromSigned(a);
        final y = _fromSigned(b);
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
        for (var shift = 0; shift <= _bits + 4; shift += 3) {
          final s = shift & (_bits - 1);
          final expected = wrapSigned(wrapUnsigned(u << s, _bits), _bits);
          expect(
            (_fromSigned(v) << shift).toBigInt(),
            expected,
            reason: '$v << $shift',
          );
        }
      }
    });

    test('>> is arithmetic (sign-propagating)', () {
      for (final v in interesting) {
        for (var shift = 0; shift <= _bits + 4; shift += 3) {
          final s = shift & (_bits - 1);
          expect(
            (_fromSigned(v) >> shift).toBigInt(),
            v >> s,
            reason: '$v >> $shift',
          );
        }
      }
    });

    test('unsignedShiftRight is logical (zero-filled) regardless of sign', () {
      for (final v in interesting) {
        final u = wrapUnsigned(v, _bits);
        for (var shift = 0; shift <= _bits + 4; shift += 3) {
          final s = shift & (_bits - 1);
          expect(
            _fromSigned(v).unsignedShiftRight(shift).toBigInt(),
            wrapSigned(u >> s, _bits),
            reason: '$v unsignedShiftRight $shift',
          );
        }
      }
    });
  });

  group('Int64 comparisons', () {
    test('compareTo / < / <= / > / >= / == match BigInt signed ordering', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = _fromSigned(a);
        final y = _fromSigned(b);
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

Int64 _fromSigned(BigInt v) => Int64.fromBigInt(v);

List<int> _twosComplementBytes(BigInt v, int bits) {
  final u = v.toUnsigned(bits);
  final out = List<int>.filled(bits ~/ 8, 0);
  var rem = u;
  for (var i = out.length - 1; i >= 0; i--) {
    out[i] = (rem & BigInt.from(0xFF)).toInt();
    rem = rem >> 8;
  }
  return out;
}

import 'dart:math';
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart'
    show IntegerError;
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

import 'helpers/oracle.dart';

const _bits = 64;

void main() {
  final rnd = Random(0xC0FFEE);
  final interesting = interestingUnsigned(_bits);

  group('Uint64 constants', () {
    test('zero/one/two/max/maxU32/mask8 match BigInt', () {
      expect(Uint64.zero.toBigInt(), BigInt.zero);
      expect(Uint64.one.toBigInt(), BigInt.one);
      expect(Uint64.two.toBigInt(), BigInt.two);
      expect(Uint64.max.toBigInt(), maxUnsigned(_bits));
      expect(Uint64.maxU32.toBigInt(), BigInt.from(0xFFFFFFFF));
      expect(Uint64.mask8.toBigInt(), BigInt.from(0xFF));
    });
  });

  group('Uint64 construction', () {
    test('new throws on negative', () {
      expect(() => Uint64(-1), throwsA(isA<ArgumentException>()));
    });

    test(
      'from wraps negative values via two\'s complement, matches oracle',
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
            Uint64.from(v).toBigInt(),
            wrapUnsigned(BigInt.from(v), _bits),
            reason: 'Uint64.from($v)',
          );
        }
      },
    );

    test('fromParts / fromBigInt round-trip and reject negative BigInt', () {
      for (final v in interesting) {
        expect(Uint64.fromBigInt(v).toBigInt(), v);
        final hi = (v >> 32).toUnsigned(32).toInt();
        final lo = v.toUnsigned(32).toInt();
        expect(Uint64.fromParts(hi, lo).toBigInt(), v);
      }
      expect(
        () => Uint64.fromBigInt(-BigInt.one),
        throwsA(isA<ArgumentException>()),
      );
    });

    test('parseHex round-trips with toHexString', () {
      for (final v in interesting) {
        final hex = v.toRadixString(16).padLeft(16, '0');
        expect(Uint64.parseHex('0x$hex').toBigInt(), v);
        expect(Uint64.parseHex(hex).toHexString(), hex);
      }
      expect(() => Uint64.parseHex('0xZZ'), throwsA(isA<ArgumentException>()));
    });

    test('parseDecimal round-trips, throws on overflow/garbage', () {
      for (final v in interesting) {
        expect(Uint64.parseDecimal(v.toString()).toBigInt(), v);
      }
      expect(
        () => Uint64.parseDecimal((maxUnsigned(_bits) + BigInt.one).toString()),
        throwsA(isA<IntegerError>()),
      );
      expect(
        () => Uint64.parseDecimal('-1'),
        throwsA(isA<ArgumentException>()),
      );
      expect(
        () => Uint64.parseDecimal('12x'),
        throwsA(isA<ArgumentException>()),
      );
    });
  });

  group('Uint64 conversions', () {
    test(
      'toInt throws when it would lose precision, matches oracle otherwise',
      () {
        expect(
          Uint64.fromBigInt(BigInt.from(9007199254740991)).toInt(),
          9007199254740991,
        );
        expect(() => Uint64.max.toInt(), throwsA(isA<IntegerError>()));
      },
    );

    test('toBytes/fromBytes round-trip, big and little endian', () {
      for (final v in interesting) {
        final x = Uint64.fromBigInt(v);
        for (final e in [Endian.big, Endian.little]) {
          final bytes = x.toBytes(e);
          expect(bytes.length, 8);
          expect(
            Uint64.fromBytes(bytes, endian: e).toBigInt(),
            v,
            reason: '$v / $e',
          );
        }
      }
    });

    test('BE/LE alias methods match toBytes/fromBytes', () {
      final x = Uint64.fromBigInt(interesting.first);
      expect(x.toBytesBE(), x.toBytes(Endian.big));
      expect(x.toBytesLE(), x.toBytes(Endian.little));
    });

    test('toString matches BigInt decimal representation', () {
      for (final v in interesting) {
        expect(Uint64.fromBigInt(v).toString(), v.toString());
      }
    });
  });

  group('Uint64 wrapping arithmetic vs BigInt oracle', () {
    test('add/sub/mul (interesting x interesting)', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint64.fromBigInt(a);
        final y = Uint64.fromBigInt(b);
        expect(
          (x + y).toBigInt(),
          wrapUnsigned(a + b, _bits),
          reason: '$a + $b',
        );
        expect(
          (x - y).toBigInt(),
          wrapUnsigned(a - b, _bits),
          reason: '$a - $b',
        );
        expect(
          (x * y).toBigInt(),
          wrapUnsigned(a * b, _bits),
          reason: '$a * $b',
        );
      }
    });

    test('add/sub/mul (random)', () {
      for (var i = 0; i < 800; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final x = Uint64.fromBigInt(a);
        final y = Uint64.fromBigInt(b);
        expect(
          (x + y).toBigInt(),
          wrapUnsigned(a + b, _bits),
          reason: '$a + $b',
        );
        expect(
          (x - y).toBigInt(),
          wrapUnsigned(a - b, _bits),
          reason: '$a - $b',
        );
        expect(
          (x * y).toBigInt(),
          wrapUnsigned(a * b, _bits),
          reason: '$a * $b',
        );
      }
    });

    test(
      'division/modulo (interesting x interesting, skipping zero divisor)',
      () {
        for (final (a, b) in pairs(interesting, interesting)) {
          if (b == BigInt.zero) continue;
          final x = Uint64.fromBigInt(a);
          final y = Uint64.fromBigInt(b);
          expect((x ~/ y).toBigInt(), a ~/ b, reason: '$a ~/ $b');
          expect((x % y).toBigInt(), a % b, reason: '$a % $b');
        }
      },
    );

    test('division by zero throws', () {
      expect(() => Uint64.one ~/ Uint64.zero, throwsA(isA<IntegerError>()));
      expect(() => Uint64.one % Uint64.zero, throwsA(isA<IntegerError>()));
    });

    test('negation is two\'s complement (wraps), matches oracle', () {
      for (final v in interesting) {
        expect((-Uint64.fromBigInt(v)).toBigInt(), wrapUnsigned(-v, _bits));
      }
    });
  });

  group('Uint64 checked arithmetic vs BigInt oracle', () {
    test('addChecked / subChecked / mulChecked', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint64.fromBigInt(a);
        final y = Uint64.fromBigInt(b);

        final sum = a + b;
        if (sum > maxUnsigned(_bits)) {
          expect(
            () => x.addChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a + $b',
          );
        } else {
          expect(x.addChecked(y).toBigInt(), sum);
        }

        if (a < b) {
          expect(
            () => x.subChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a - $b',
          );
        } else {
          expect(x.subChecked(y).toBigInt(), a - b);
        }

        final prod = a * b;
        if (prod > maxUnsigned(_bits)) {
          expect(
            () => x.mulChecked(y),
            throwsA(isA<IntegerError>()),
            reason: '$a * $b',
          );
        } else {
          expect(x.mulChecked(y).toBigInt(), prod);
        }
      }
    });
  });

  group('Uint64 bitwise operators vs BigInt oracle', () {
    test('& | ^ ~', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint64.fromBigInt(a);
        final y = Uint64.fromBigInt(b);
        expect((x & y).toBigInt(), a & b, reason: '$a & $b');
        expect((x | y).toBigInt(), a | b, reason: '$a | $b');
        expect((x ^ y).toBigInt(), a ^ b, reason: '$a ^ $b');
      }
      for (final a in interesting) {
        expect(
          (~Uint64.fromBigInt(a)).toBigInt(),
          wrapUnsigned(~a, _bits),
          reason: '~$a',
        );
      }
    });

    test('<< and >> mask the shift amount to width and match oracle', () {
      for (final v in interesting) {
        for (var shift = 0; shift <= _bits + 4; shift += 3) {
          final s = shift & (_bits - 1);
          expect(
            (Uint64.fromBigInt(v) << shift).toBigInt(),
            wrapUnsigned(v << s, _bits),
            reason: '$v << $shift',
          );
          expect(
            (Uint64.fromBigInt(v) >> shift).toBigInt(),
            v >> s,
            reason: '$v >> $shift',
          );
        }
      }
    });
  });

  group('Uint64 comparisons', () {
    test('compareTo / < / <= / > / >= / == match BigInt ordering', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint64.fromBigInt(a);
        final y = Uint64.fromBigInt(b);
        expect(x.compareTo(y).sign, a.compareTo(b).sign, reason: '$a <=> $b');
        expect(x < y, a < b);
        expect(x <= y, a <= b);
        expect(x > y, a > b);
        expect(x >= y, a >= b);
        expect(x == y, a == b);
      }
    });
  });

  group('Uint64 carry-chain primitives (Comba/Montgomery building blocks)', () {
    test('widenMul matches the true 128-bit BigInt product', () {
      for (final (a, b) in pairs(interesting, interesting)) {
        final x = Uint64.fromBigInt(a);
        final y = Uint64.fromBigInt(b);
        final (hi, lo) = Uint64.widenMul(x, y);
        final product = a * b;
        expect(hi.toBigInt(), product >> 64, reason: 'hi($a*$b)');
        expect(lo.toBigInt(), product.toUnsigned(64), reason: 'lo($a*$b)');
      }
    });

    test('widenMul matches BigInt product (random, includes max*max)', () {
      for (var i = 0; i < 500; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final (hi, lo) = Uint64.widenMul(
          Uint64.fromBigInt(a),
          Uint64.fromBigInt(b),
        );
        final product = a * b;
        expect(hi.toBigInt(), product >> 64, reason: '$a * $b');
        expect(lo.toBigInt(), product.toUnsigned(64), reason: '$a * $b');
      }
    });

    test('mac: a + b*c + carry as a full 128-bit value', () {
      for (var i = 0; i < 500; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final c = randomUnsigned(rnd, _bits);
        final carry = randomUnsigned(rnd, _bits);
        final (lo, hi) = Uint64.mac(
          Uint64.fromBigInt(a),
          Uint64.fromBigInt(b),
          Uint64.fromBigInt(c),
          Uint64.fromBigInt(carry),
        );
        final full = a + b * c + carry;
        expect(lo.toBigInt(), full.toUnsigned(64), reason: 'mac lo');
        expect(hi.toBigInt(), full >> 64, reason: 'mac hi');
      }
    });

    test('adc: a + b + carry, with numeric carry-out (0, 1, or 2)', () {
      for (var i = 0; i < 500; i++) {
        final a = randomUnsigned(rnd, _bits);
        final b = randomUnsigned(rnd, _bits);
        final carryIn = randomUnsigned(
          rnd,
          _bits,
        ); // adc accepts a full carry-in from mac
        final (result, carryOut) = Uint64.adc(
          Uint64.fromBigInt(a),
          Uint64.fromBigInt(b),
          Uint64.fromBigInt(carryIn),
        );
        final full = a + b + carryIn;
        expect(result.toBigInt(), full.toUnsigned(64), reason: 'adc result');
        expect(carryOut.toBigInt(), full >> 64, reason: 'adc carryOut');
      }
      // Boundary: max + max + max should carry out by 2.
      final (result, carryOut) = Uint64.adc(Uint64.max, Uint64.max, Uint64.max);
      final full = maxUnsigned(_bits) * BigInt.from(3);
      expect(result.toBigInt(), full.toUnsigned(64));
      expect(carryOut.toBigInt(), full >> 64);
    });

    test(
      'sbb: a - b - borrowBit, with an all-zero/all-one borrow-out mask',
      () {
        for (var i = 0; i < 500; i++) {
          final a = randomUnsigned(rnd, _bits);
          final b = randomUnsigned(rnd, _bits);
          final borrowIn = rnd.nextBool();
          final (result, borrowOutMask) = Uint64.sbb(
            Uint64.fromBigInt(a),
            Uint64.fromBigInt(b),
            borrowIn ? Uint64.one : Uint64.zero,
          );
          final full = a - b - (borrowIn ? BigInt.one : BigInt.zero);
          expect(
            result.toBigInt(),
            wrapUnsigned(full, _bits),
            reason: 'sbb result',
          );
          expect(
            borrowOutMask.toBigInt(),
            full.isNegative ? maxUnsigned(_bits) : BigInt.zero,
            reason: 'sbb borrowOutMask',
          );
        }
      },
    );

    test('ctSelect returns a if !choice else b', () {
      final a = Uint64.fromBigInt(interesting[0]);
      final b = Uint64.fromBigInt(interesting[interesting.length ~/ 2]);
      expect(Uint64.ctSelect(a, b, false), a);
      expect(Uint64.ctSelect(a, b, true), b);
    });

    test(
      'ctEquals matches element-wise equality, including length mismatch',
      () {
        final a = [Uint64.zero, Uint64.one, Uint64.max];
        final b = [Uint64.zero, Uint64.one, Uint64.max];
        final c = [Uint64.zero, Uint64.one, Uint64.zero];
        expect(Uint64.ctEquals(a, b), isTrue);
        expect(Uint64.ctEquals(a, c), isFalse);
        expect(Uint64.ctEquals(a, [Uint64.zero]), isFalse);
      },
    );
  });
}

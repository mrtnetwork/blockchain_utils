// Uint512 test suite, BigInt-oracle based.
//
// Adjust the import below to match your package layout. Run with
// `dart test test/numbers/u512_test.dart` (native) and
// `dart test test/numbers/u512_test.dart -p chrome` (web) — both
// should pass identically, since Uint512's public behavior is
// platform-independent even though the implementation is split.
import 'dart:math';
import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/numbers/src/u256/u256.dart';
import 'package:blockchain_utils/numbers/src/u512/u512.dart';
import 'package:test/test.dart';

final _rand = Random(0xC0FFEE);
final _bigMask512 = (BigInt.one << 512) - BigInt.one;

BigInt _randBigInt(int maxBits) {
  final bits = 1 + _rand.nextInt(maxBits);
  var v = BigInt.zero;
  for (var i = 0; i < bits; i += 32) {
    v = (v << 32) | BigInt.from(_rand.nextInt(0x100000000));
  }
  return v.toUnsigned(bits);
}

BigInt _randBigInt512Full() {
  var v = BigInt.zero;
  for (var i = 0; i < 16; i++) {
    v = (v << 32) | BigInt.from(_rand.nextInt(0x100000000));
  }
  return v;
}

/// Interesting boundary values every operator should be stressed
/// against: zero, one, max, values that straddle every limb boundary
/// (64, 128, ..., 448 bits — where carry/borrow chains can break) and
/// every 32-bit digit boundary the native division algorithm cares
/// about, plus every 16-bit digit boundary the web division algorithm
/// cares about.
List<BigInt> get _interestingValues => [
  BigInt.zero,
  BigInt.one,
  BigInt.two,
  _bigMask512, // max
  _bigMask512 - BigInt.one, // max - 1
  for (var bit in [
    16,
    31,
    32,
    33,
    63,
    64,
    65,
    127,
    128,
    129,
    191,
    192,
    193,
    255,
    256,
    257,
    319,
    320,
    321,
    383,
    384,
    385,
    447,
    448,
    449,
    511,
  ]) ...[
    BigInt.one << bit,
    (BigInt.one << bit) - BigInt.one,
    (BigInt.one << bit) + BigInt.one,
  ],
];

void main() {
  group('Uint512 construction', () {
    test('fromBigInt / toBigInt round-trips (random)', () {
      for (var i = 0; i < 20000; i++) {
        final b = _randBigInt(512);
        expect(Uint512.fromBigInt(b).toBigInt(), b);
      }
    });

    test('fromBigInt / toBigInt round-trips (interesting values)', () {
      for (final b in _interestingValues) {
        final v = b.toUnsigned(512);
        expect(Uint512.fromBigInt(v).toBigInt(), v);
      }
    });

    test('fromBigInt throws on negative', () {
      expect(() => Uint512.fromBigInt(BigInt.from(-1)), throwsA(anything));
    });

    test('parseDecimal round-trips, throws on overflow/garbage', () {
      for (var i = 0; i < 5000; i++) {
        final b = _randBigInt(512);
        expect(Uint512.parseDecimal(b.toString()).toBigInt(), b);
      }
      for (final b in _interestingValues) {
        final v = b.toUnsigned(512);
        expect(Uint512.parseDecimal(v.toString()).toBigInt(), v);
      }
      // one past max: must throw, not silently wrap
      final overflow = (_bigMask512 + BigInt.one).toString();
      expect(() => Uint512.parseDecimal(overflow), throwsA(anything));
      expect(() => Uint512.parseDecimal(''), throwsA(anything));
      expect(() => Uint512.parseDecimal('12a3'), throwsA(anything));
      expect(() => Uint512.parseDecimal('-5'), throwsA(anything));
    });

    test('parseHex / toHexString round-trips', () {
      for (var i = 0; i < 5000; i++) {
        final b = _randBigInt(512);
        final v = Uint512.fromBigInt(b);
        expect(Uint512.parseHex(v.toHexString()).toBigInt(), b);
        expect(Uint512.parseHex('0x${v.toHexString()}').toBigInt(), b);
      }
      expect(Uint512.parseHex('0').toBigInt(), BigInt.zero);
      expect(Uint512.parseHex('ff').toBigInt(), BigInt.from(0xff));
    });

    test('toBytes / fromBytes round-trips, big and little endian', () {
      for (var i = 0; i < 5000; i++) {
        final b = _randBigInt(512);
        final v = Uint512.fromBigInt(b);
        final be = v.toBytes();
        expect(be.length, 64);
        expect(Uint512.fromBytes(be).toBigInt(), b);
        final le = v.toBytes(Endian.little);
        expect(Uint512.fromBytes(le, endian: Endian.little).toBigInt(), b);
      }
    });
  });

  group('Uint512 wrapping arithmetic vs BigInt oracle', () {
    test('add/sub (interesting x interesting)', () {
      for (final ab in _interestingValues) {
        for (final bb in _interestingValues) {
          final a = ab.toUnsigned(512);
          final b = bb.toUnsigned(512);
          final ua = Uint512.fromBigInt(a);
          final ub = Uint512.fromBigInt(b);
          expect((ua + ub).toBigInt(), (a + b).toUnsigned(512));
          expect((ua - ub).toBigInt(), (a - b).toUnsigned(512));
        }
      }
    });

    test('add/sub/mul (random)', () {
      for (var i = 0; i < 20000; i++) {
        final a = _randBigInt512Full();
        final b = _randBigInt512Full();
        final ua = Uint512.fromBigInt(a);
        final ub = Uint512.fromBigInt(b);
        expect((ua + ub).toBigInt(), (a + b).toUnsigned(512));
        expect((ua - ub).toBigInt(), (a - b).toUnsigned(512));
        expect((ua * ub).toBigInt(), (a * b) & _bigMask512);
      }
    });

    test('mul (interesting x interesting)', () {
      for (final ab in _interestingValues) {
        for (final bb in _interestingValues) {
          final a = ab.toUnsigned(512);
          final b = bb.toUnsigned(512);
          final ua = Uint512.fromBigInt(a);
          final ub = Uint512.fromBigInt(b);
          expect((ua * ub).toBigInt(), (a * b) & _bigMask512);
        }
      }
    });

    test('div/mod (random)', () {
      for (var i = 0; i < 20000; i++) {
        final a = _randBigInt512Full();
        var b = _randBigInt512Full();
        if (b == BigInt.zero) b = BigInt.one;
        final ua = Uint512.fromBigInt(a);
        final ub = Uint512.fromBigInt(b);
        expect((ua ~/ ub).toBigInt(), a ~/ b);
        expect((ua % ub).toBigInt(), a % b);
      }
    });

    test('div/mod throws on divide by zero', () {
      final one = Uint512(1);
      expect(() => one ~/ Uint512.zero, throwsA(anything));
      expect(() => one % Uint512.zero, throwsA(anything));
    });

    test('div/mod (interesting x interesting, skipping zero divisor)', () {
      for (final ab in _interestingValues) {
        for (final bb in _interestingValues) {
          if (bb == BigInt.zero) continue;
          final a = ab.toUnsigned(512);
          final b = bb.toUnsigned(512);
          final ua = Uint512.fromBigInt(a);
          final ub = Uint512.fromBigInt(b);
          expect((ua ~/ ub).toBigInt(), a ~/ b, reason: 'a=$a b=$b');
          expect((ua % ub).toBigInt(), a % b, reason: 'a=$a b=$b');
        }
      }
    });

    test('div/mod: every divisor digit-length is exercised (1-16 x '
        '32-bit digits, and by extension every 16-bit digit length too)', () {
      // Sweep divisor bit-lengths so the divisor's significant digit
      // count varies across the full range both the native (32-bit
      // digit) and web (16-bit digit) division algorithms handle
      // differently internally (single-digit fast path vs full Knuth,
      // and every possible normalization shift amount).
      for (var bits = 1; bits <= 512; bits += 7) {
        for (var i = 0; i < 50; i++) {
          final a = _randBigInt512Full();
          var b = _randBigInt(bits);
          if (b == BigInt.zero) b = BigInt.one;
          final ua = Uint512.fromBigInt(a);
          final ub = Uint512.fromBigInt(b);
          expect((ua ~/ ub).toBigInt(), a ~/ b, reason: 'bits=$bits a=$a b=$b');
          expect((ua % ub).toBigInt(), a % b, reason: 'bits=$bits a=$a b=$b');
        }
      }
    });

    test('div/mod: divisor top digit near a normalization boundary '
        '(stresses the Knuth add-back correction path)', () {
      // Divisors whose top digit is just above/below the 0x80000000
      // (32-bit) or 0x8000 (16-bit) normalization threshold are where
      // the quotient-digit estimate is most likely to need correction.
      final trickyTops = [
        0x80000000,
        0x80000001,
        0xFFFFFFFF,
        0x7FFFFFFF,
        0x8000,
        0x8001,
        0xFFFF,
        0x7FFF,
      ];
      for (final top in trickyTops) {
        for (var extraDigits = 0; extraDigits < 8; extraDigits++) {
          final lowerBits =
              extraDigits == 0 ? BigInt.zero : _randBigInt(32 * extraDigits);
          final b = (BigInt.from(top) << (32 * extraDigits)) + lowerBits;
          if (b == BigInt.zero || b > _bigMask512) continue;
          for (var i = 0; i < 20; i++) {
            final a = _randBigInt512Full();
            final ua = Uint512.fromBigInt(a);
            final ub = Uint512.fromBigInt(b);
            expect((ua ~/ ub).toBigInt(), a ~/ b, reason: 'a=$a b=$b');
            expect((ua % ub).toBigInt(), a % b, reason: 'a=$a b=$b');
          }
        }
      }
    });

    test('toString round-trips through repeated small-divisor division '
        '(the highest-traffic real-world path)', () {
      for (var i = 0; i < 5000; i++) {
        final b = _randBigInt(512);
        expect(Uint512.fromBigInt(b).toString(), b.toString());
      }
      for (final b in _interestingValues) {
        final v = b.toUnsigned(512);
        expect(Uint512.fromBigInt(v).toString(), v.toString());
      }
      expect(Uint512.zero.toString(), '0');
      expect(Uint512.one.toString(), '1');
      expect(Uint512.max.toString(), _bigMask512.toString());
    });
  });

  group('Uint512 checked arithmetic vs BigInt oracle', () {
    test('addChecked / subChecked / mulChecked (random, no overflow)', () {
      for (var i = 0; i < 10000; i++) {
        // keep operands small enough that add/mul shouldn't overflow
        final a = _randBigInt(255);
        final b = _randBigInt(255);
        final ua = Uint512.fromBigInt(a);
        final ub = Uint512.fromBigInt(b);
        expect(ua.addChecked(ub).toBigInt(), a + b);
        expect(ua.mulChecked(ub).toBigInt(), a * b);
        if (a >= b) {
          expect(ua.subChecked(ub).toBigInt(), a - b);
        } else {
          expect(() => ua.subChecked(ub), throwsA(anything));
        }
      }
    });

    test('addChecked overflows correctly at the 512-bit boundary', () {
      expect(() => Uint512.one.addChecked(Uint512.max), throwsA(anything));
      expect(
        () => Uint512.fromBigInt(
          BigInt.two,
        ).addChecked(Uint512.fromBigInt(_bigMask512 - BigInt.one)),
        throwsA(anything),
      );
      // exactly at the boundary should NOT throw
      expect(
        Uint512.one.addChecked(Uint512.fromBigInt(_bigMask512 - BigInt.one)).toBigInt(),
        _bigMask512,
      );
    });

    test('subChecked underflows correctly', () {
      expect(() => Uint512.zero.subChecked(Uint512.one), throwsA(anything));
      expect(Uint512.max.subChecked(Uint512.max).toBigInt(), BigInt.zero);
    });

    test('mulChecked overflows correctly, and zero short-circuits', () {
      expect(Uint512.zero.mulChecked(Uint512.max).toBigInt(), BigInt.zero);
      expect(Uint512.max.mulChecked(Uint512.zero).toBigInt(), BigInt.zero);
      expect(() => Uint512.max.mulChecked(Uint512.two), throwsA(anything));
      // largest value that should NOT overflow when doubled
      final half = _bigMask512 ~/ BigInt.two;
      expect(
        Uint512.fromBigInt(half).mulChecked(Uint512.two).toBigInt(),
        half * BigInt.two,
      );
    });
  });

  group('Uint512 comparisons', () {
    test('compareTo / operators match BigInt ordering (random)', () {
      for (var i = 0; i < 10000; i++) {
        final a = _randBigInt512Full();
        final b = _randBigInt512Full();
        final ua = Uint512.fromBigInt(a);
        final ub = Uint512.fromBigInt(b);
        expect(ua.compareTo(ub).sign, a.compareTo(b).sign);
        expect(ua < ub, a < b);
        expect(ua <= ub, a <= b);
        expect(ua > ub, a > b);
        expect(ua >= ub, a >= b);
        expect(ua == ub, a == b);
      }
    });

    test('== and hashCode are consistent', () {
      for (var i = 0; i < 2000; i++) {
        final b = _randBigInt512Full();
        final ua = Uint512.fromBigInt(b);
        final ub = Uint512.fromBigInt(b);
        expect(ua, ub);
        expect(ua.hashCode, ub.hashCode);
      }
    });

    test('isZero / isEven / isOdd', () {
      expect(Uint512.zero.isZero, isTrue);
      expect(Uint512.one.isZero, isFalse);
      for (var i = 0; i < 2000; i++) {
        final b = _randBigInt512Full();
        final u = Uint512.fromBigInt(b);
        expect(u.isEven, b.isEven);
        expect(u.isOdd, !b.isEven);
      }
    });
  });

  group('Uint512 bitwise operators', () {
    test('& | ^ ~ match BigInt masked equivalents (random)', () {
      for (var i = 0; i < 10000; i++) {
        final a = _randBigInt512Full();
        final b = _randBigInt512Full();
        final ua = Uint512.fromBigInt(a);
        final ub = Uint512.fromBigInt(b);
        expect((ua & ub).toBigInt(), a & b);
        expect((ua | ub).toBigInt(), a | b);
        expect((ua ^ ub).toBigInt(), a ^ b);
        expect((~ua).toBigInt(), (~a).toUnsigned(512));
      }
    });

    test('<< >> match BigInt, including every limb-boundary shift '
        'amount and wraparound at 512', () {
      final shiftAmounts = [
        0,
        1,
        7,
        8,
        15,
        16,
        31,
        32,
        63,
        64,
        65,
        127,
        128,
        129,
        191,
        192,
        255,
        256,
        319,
        320,
        383,
        384,
        447,
        448,
        511,
        512,
        600,
      ];
      for (var i = 0; i < 500; i++) {
        final a = _randBigInt512Full();
        final ua = Uint512.fromBigInt(a);
        for (final shift in shiftAmounts) {
          final effShift = shift & 511;
          expect(
            (ua << shift).toBigInt(),
            (a << effShift).toUnsigned(512),
            reason: 'a=$a shift=$shift',
          );
          expect((ua >> shift).toBigInt(), a >> effShift, reason: 'a=$a shift=$shift');
        }
      }
    });
  });

  group('Uint512 cross-type conversions', () {
    test('fromUint256 / toUint256 round-trip the low 256 bits', () {
      for (var i = 0; i < 5000; i++) {
        final b = _randBigInt(256);
        final u256 = Uint256.fromBigInt(b);
        final u512 = Uint512.fromUint256(u256);
        expect(u512.toBigInt(), b);
        expect(u512.toUint256().toBigInt(), b);
      }
    });

    test('toUint128 / toUint64 / toUint32 truncate correctly', () {
      for (var i = 0; i < 5000; i++) {
        final b = _randBigInt512Full();
        final u = Uint512.fromBigInt(b);
        expect(u.toUint128().toBigInt(), b.toUnsigned(128));
        expect(u.toUint64().toBigInt(), b.toUnsigned(64));
        expect(u.toUint32().toBigInt(), b.toUnsigned(32));
      }
    });
  });
}

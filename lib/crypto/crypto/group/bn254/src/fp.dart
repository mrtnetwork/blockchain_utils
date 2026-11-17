// BN254 base field Fp = GF(p), p = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
// 4x64 limbs, Montgomery, branchless / straight-line like Bls12Fp.
//
// Layout mirrors `blockchain_utils .../bls12_381/src/fp.dart`:
//  - limbs are LE (limbs[0] = low word), values held in Montgomery form.
//  - `mac`/`adc`/`sbb` chains are fixed-length (public bounds only).
//  - secret selects use `conditionalSelectMask` (Uint64 0/1 bit), never bool.
import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class BnSqrtResult<T> {
  final T result;
  final bool isSquare;
  const BnSqrtResult(this.result, this.isSquare);
}

class Bn254FpConst {
  static const Uint64 inv = Uint64.unsafe(2278688642, 3834012553);
  static const modulus = Bn254Fp.unsafe([
    Uint64.unsafe(1008765974, 3632069959),
    Uint64.unsafe(2541841041, 1752287885),
    Uint64.unsafe(3092268470, 2172737629),
    Uint64.unsafe(811880050, 3778125865),
  ]);
}

class Bn254Fp with ConstantEquality<Bn254Fp> {
  final List<Uint64> limbs;
  const Bn254Fp.unsafe(this.limbs);
  Bn254Fp(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: 'Bn254Fp').immutable;

  static const zero = Bn254Fp.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);

  // ONE in Montgomery form: R mod p
  static const one = Bn254Fp.unsafe([
    Uint64.unsafe(3546104717, 3314486685),
    Uint64.unsafe(175696680, 4123462461),
    Uint64.unsafe(1718526831, 2021213740),
    Uint64.unsafe(235567041, 2584207151),
  ]);

  static const r2 = Bn254Fp.unsafe([
    Uint64.unsafe(4079811675, 1401617033),
    Uint64.unsafe(3051821329, 3561292283),
    Uint64.unsafe(1202396927, 172064758),
    Uint64.unsafe(114859889, 3401069855),
  ]);

  // b = 3 in Montgomery form
  static const b = Bn254Fp.unsafe([
    Uint64.unsafe(2048379561, 1353525463),
    Uint64.unsafe(527090042, 3780452793),
    Uint64.unsafe(860613198, 1768673924),
    Uint64.unsafe(706701124, 3457654158),
  ]);

  static const r3 = Bn254Fp.unsafe([
    Uint64.unsafe(465102405, 2921426343),
    Uint64.unsafe(1409170097, 3814480355),
    Uint64.unsafe(2353627965, 1404797061),
    Uint64.unsafe(35049649, 2135835813),
  ]);

  /// Montgomery reduction of an 8-limb product into Montgomery form.
  /// Fixed 4-iteration CIOS, no secret branches.
  factory Bn254Fp.montgomeryReduce(List<Uint64> t) {
    assert(t.length == 8);
    final a = List<Uint64>.from(t);
    final inv = Bn254FpConst.inv;
    final mod = Bn254FpConst.modulus.limbs;
    for (int i = 0; i < 4; i++) {
      final k = a[i] * inv;
      var carry = Uint64.zero;
      for (int j = 0; j < 4; j++) {
        final res = Uint64.mac(a[i + j], k, mod[j], carry);
        a[i + j] = res.$1;
        carry = res.$2;
      }
      // propagate carry through the upper words
      for (int j = i + 4; j < 8; j++) {
        final res = Uint64.adc(a[j], Uint64.zero, carry);
        a[j] = res.$1;
        carry = res.$2;
      }
    }
    return Bn254Fp([a[4], a[5], a[6], a[7]])._subtractP();
  }

  factory Bn254Fp.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        'Bn254Fp',
        reason: 'Invalid field bytes length.',
      );
    }
    final tmp = Bn254Fp([
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 24),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 16),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 8),
      Uint64.fromBytes(bytes, endian: Endian.big),
    ]);
    // constant-time range check would be nicer, but fromBytes input is
    // public encoding data (not secret), matching Bls12Fp.fromBytes style
    // which throws on >= p.
    Uint64 borrow = Uint64.zero;
    var temp = Uint64.sbb(tmp.limbs[0], Bn254FpConst.modulus.limbs[0], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[1], Bn254FpConst.modulus.limbs[1], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[2], Bn254FpConst.modulus.limbs[2], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[3], Bn254FpConst.modulus.limbs[3], borrow);
    borrow = temp.$2;
    if ((borrow & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        'Bn254Fp',
        reason: 'Invalid field encoding bytes.',
      );
    }
    return tmp * Bn254Fp.r2;
  }

  factory Bn254Fp.conditionalSelect(Bn254Fp a, Bn254Fp b, bool choice) {
    return Bn254Fp([
      Uint64.ctSelect(a.limbs[0], b.limbs[0], choice),
      Uint64.ctSelect(a.limbs[1], b.limbs[1], choice),
      Uint64.ctSelect(a.limbs[2], b.limbs[2], choice),
      Uint64.ctSelect(a.limbs[3], b.limbs[3], choice),
    ]);
  }

  /// Mask form: [bit] is a 0/1 Uint64, never a bool.
  factory Bn254Fp.conditionalSelectMask(Bn254Fp a, Bn254Fp b, Uint64 bit) {
    return Bn254Fp([
      Uint64.selectBit(a.limbs[0], b.limbs[0], bit),
      Uint64.selectBit(a.limbs[1], b.limbs[1], bit),
      Uint64.selectBit(a.limbs[2], b.limbs[2], bit),
      Uint64.selectBit(a.limbs[3], b.limbs[3], bit),
    ]);
  }

  Bn254Fp _subtractP() {
    var tmp = Uint64.sbb(limbs[0], Bn254FpConst.modulus.limbs[0], Uint64.zero);
    Uint64 r0 = tmp.$1;
    Uint64 borrow = tmp.$2;
    tmp = Uint64.sbb(limbs[1], Bn254FpConst.modulus.limbs[1], borrow);
    Uint64 r1 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(limbs[2], Bn254FpConst.modulus.limbs[2], borrow);
    Uint64 r2 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(limbs[3], Bn254FpConst.modulus.limbs[3], borrow);
    Uint64 r3 = tmp.$1;
    borrow = tmp.$2;
    r0 = ((limbs[0] & borrow) | (r0 & ~borrow));
    r1 = ((limbs[1] & borrow) | (r1 & ~borrow));
    r2 = ((limbs[2] & borrow) | (r2 & ~borrow));
    r3 = ((limbs[3] & borrow) | (r3 & ~borrow));
    return Bn254Fp([r0, r1, r2, r3]);
  }

  Bn254Fp _add(Bn254Fp rhs) {
    var tmp = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    final d0 = tmp.$1;
    var carry = tmp.$2;
    tmp = Uint64.adc(limbs[1], rhs.limbs[1], carry);
    final d1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(limbs[2], rhs.limbs[2], carry);
    final d2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(limbs[3], rhs.limbs[3], carry);
    final d3 = tmp.$1;
    return Bn254Fp([d0, d1, d2, d3])._subtractP();
  }

  Bn254Fp _neg() {
    var tmp = Uint64.sbb(Bn254FpConst.modulus.limbs[0], limbs[0], Uint64.zero);
    final d0 = tmp.$1;
    var borrow = tmp.$2;
    tmp = Uint64.sbb(Bn254FpConst.modulus.limbs[1], limbs[1], borrow);
    final d1 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(Bn254FpConst.modulus.limbs[2], limbs[2], borrow);
    final d2 = tmp.$1;
    borrow = tmp.$2;
    tmp = Uint64.sbb(Bn254FpConst.modulus.limbs[3], limbs[3], borrow);
    final d3 = tmp.$1;
    final x = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    final mask = (x == Uint64.zero) ? Uint64.zero : Uint64.max;
    return Bn254Fp([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  Bn254Fp _sub(Bn254Fp rhs) => rhs._neg()._add(this);

  Bn254Fp _mul(Bn254Fp rhs) {
    final t = List<Uint64>.filled(8, Uint64.zero);
    for (int i = 0; i < 4; i++) {
      var carry = Uint64.zero;
      for (int j = 0; j < 4; j++) {
        final res = Uint64.mac(t[i + j], limbs[i], rhs.limbs[j], carry);
        t[i + j] = res.$1;
        carry = res.$2;
      }
      int k = i + 4;
      while (carry != Uint64.zero && k < 8) {
        final res = Uint64.adc(t[k], Uint64.zero, carry);
        t[k] = res.$1;
        carry = res.$2;
        k++;
      }
    }
    return Bn254Fp.montgomeryReduce(t);
  }

  Bn254Fp square() => _mul(this);

  Bn254Fp? invert() {
    if (isZero()) return null;
    // p - 2
    const m = [
      Uint64.unsafe(1008765974, 3632069957),
      Uint64.unsafe(2541841041, 1752287885),
      Uint64.unsafe(3092268470, 2172737629),
      Uint64.unsafe(811880050, 3778125865),
    ];
    return pow(m);
  }

  /// Square-and-multiply over a PUBLIC exponent (LE limbs).
  /// Callers pass constants (p-2, (p+1)/4); secret scalars never go here.
  Bn254Fp pow(List<Uint64> by) {
    Bn254Fp res = Bn254Fp.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) {
          res = res * this;
        }
      }
    }
    return res;
  }

  BnSqrtResult<Bn254Fp> sqrt() {
    // p % 4 == 3, exponent (p+1)/4
    const m = [
      Uint64.unsafe(1325933317, 3055501138),
      Uint64.unsafe(1709202084, 1511813795),
      Uint64.unsafe(1846808941, 2690668055),
      Uint64.unsafe(202970012, 3092015114),
    ];
    final cand = pow(m);
    return BnSqrtResult(cand, cand.square() == this);
  }

  bool isZero() => this == Bn254Fp.zero;

  Bn254Fp double() => _add(this);

  Bn254Fp operator +(Bn254Fp rhs) => _add(rhs);
  Bn254Fp operator -(Bn254Fp rhs) => _sub(rhs);
  Bn254Fp operator *(Bn254Fp rhs) => _mul(rhs);
  Bn254Fp operator -() => _neg();

  bool lexicographicallyLargest() {
    final tmp = Bn254Fp.montgomeryReduce([
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    ]);
    // threshold (p+1)/2
    const d = [
      Uint64.unsafe(2651866635, 1816034980),
      Uint64.unsafe(3418404168, 3023627590),
      Uint64.unsafe(3693617883, 1086368814),
      Uint64.unsafe(405940025, 1889062932),
    ];
    Uint64 borrow = Uint64.zero;
    var r = Uint64.sbb(tmp.limbs[0], d[0], borrow);
    borrow = r.$2;
    r = Uint64.sbb(tmp.limbs[1], d[1], borrow);
    borrow = r.$2;
    r = Uint64.sbb(tmp.limbs[2], d[2], borrow);
    borrow = r.$2;
    r = Uint64.sbb(tmp.limbs[3], d[3], borrow);
    borrow = r.$2;
    return borrow == Uint64.zero;
  }

  BuBytes toBytes() {
    final tmp = Bn254Fp.montgomeryReduce([
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    ]);
    return BuBytes(
      tmp.limbs.reversed.expand((e) => e.toBytes(Endian.big)).toList(),
    );
  }

  bool sgn0() => (toBytes().last & 1) == 1;

  @override
  bool constantEquality(Bn254Fp other) => Uint64.ctEquals(limbs, other.limbs);
}

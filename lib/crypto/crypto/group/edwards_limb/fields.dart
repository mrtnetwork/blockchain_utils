import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/constants.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

abstract class EdwardsPrimeField<F extends EdwardsPrimeField<F>>
    extends CryptoField<F> {
  const EdwardsPrimeField();
  BuBytes toBytes();
}

abstract class EdwardsField<F extends EdwardsField<F>>
    extends EdwardsPrimeField<F> {
  const EdwardsField();
}

abstract class EdwardsScalar<F extends EdwardsScalar<F>>
    extends EdwardsPrimeField<F> {
  const EdwardsScalar();
}

class Ed25519Fp extends EdwardsField<Ed25519Fp> with Equality {
  final List<Uint64> limbs;
  const Ed25519Fp.unsafe(this.limbs);
  Ed25519Fp(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "Ed25519Fp").immutable;
  @override
  List<dynamic> get variables => limbs;
  static const Ed25519Fp zero = Ed25519Fp.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const Ed25519Fp one = r;

  static const Ed25519Fp r = Ed25519Fp.unsafe([
    Uint64.unsafe(0, 38),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);
  static const Ed25519Fp r2 = Ed25519Fp.unsafe([
    Uint64.unsafe(0, 1444),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);
  static const Ed25519Fp r3 = Ed25519Fp.unsafe([
    Uint64.unsafe(0, 54872),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);
  factory Ed25519Fp.from(Uint64 v) =>
      Ed25519Fp([v, Uint64.zero, Uint64.zero, Uint64.zero]).mul(Ed25519Fp.r2);
  factory Ed25519Fp.fromRaw(List<Uint64> v) => Ed25519Fp(v).mul(Ed25519Fp.r2);
  factory Ed25519Fp._fromU512(List<Uint64> l) {
    final d0 = Ed25519Fp([l[0], l[1], l[2], l[3]]);
    final d1 = Ed25519Fp([l[4], l[5], l[6], l[7]]);
    return d0 * Ed25519Fp.r2 + d1 * Ed25519Fp.r3;
  }
  factory Ed25519Fp.conditionalSelect(Ed25519Fp a, Ed25519Fp b, bool c) =>
      Ed25519Fp([
        Uint64.ctSelect(a.limbs[0], b.limbs[0], c),
        Uint64.ctSelect(a.limbs[1], b.limbs[1], c),
        Uint64.ctSelect(a.limbs[2], b.limbs[2], c),
        Uint64.ctSelect(a.limbs[3], b.limbs[3], c),
      ]);

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so the whole select is straight-line limb arithmetic.
  factory Ed25519Fp.conditionalSelectMask(
    Ed25519Fp a,
    Ed25519Fp b,
    Uint64 bit,
  ) => Ed25519Fp([
    Uint64.selectBit(a.limbs[0], b.limbs[0], bit),
    Uint64.selectBit(a.limbs[1], b.limbs[1], bit),
    Uint64.selectBit(a.limbs[2], b.limbs[2], bit),
    Uint64.selectBit(a.limbs[3], b.limbs[3], bit),
  ]);
  factory Ed25519Fp.fromBytes(List<int> b, {Endian endian = Endian.little}) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    final t = Ed25519Fp(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
    var bm = Uint64.zero;
    var tp = Uint64.sbb(t.limbs[0], Ed25519FpConst.modulusLimbs[0], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[1], Ed25519FpConst.modulusLimbs[1], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[2], Ed25519FpConst.modulusLimbs[2], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[3], Ed25519FpConst.modulusLimbs[3], bm);
    bm = tp.$2;
    final r = t * Ed25519Fp.r2;
    if ((bm & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid encoding.",
      );
    }
    return r;
  }
  factory Ed25519Fp.fromBytesUnchecked(
    List<int> b, {
    Endian endian = Endian.little,
  }) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    return Ed25519Fp.fromRaw(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Ed25519Fp.fromBytes64(List<int> b) {
    if (b.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid length.",
      );
    }
    return Ed25519Fp._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Ed25519Fp.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * Ed25519FpConst.inv;
    var tmp = Uint64.mac(r0, k, Ed25519FpConst.modulusLimbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, Ed25519FpConst.modulusLimbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Ed25519FpConst.modulusLimbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Ed25519FpConst.modulusLimbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var n4 = Uint64.adc(r4, Uint64.zero, carry);
    r4 = n4.$1;
    var c2 = n4.$2;
    k = r1 * Ed25519FpConst.inv;
    tmp = Uint64.mac(r1, k, Ed25519FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Ed25519FpConst.modulusLimbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Ed25519FpConst.modulusLimbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Ed25519FpConst.modulusLimbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var n5 = Uint64.adc(r5, c2, carry);
    r5 = n5.$1;
    c2 = n5.$2;
    k = r2 * Ed25519FpConst.inv;
    tmp = Uint64.mac(r2, k, Ed25519FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Ed25519FpConst.modulusLimbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Ed25519FpConst.modulusLimbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Ed25519FpConst.modulusLimbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var n6 = Uint64.adc(r6, c2, carry);
    r6 = n6.$1;
    c2 = n6.$2;
    k = r3 * Ed25519FpConst.inv;
    tmp = Uint64.mac(r3, k, Ed25519FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Ed25519FpConst.modulusLimbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Ed25519FpConst.modulusLimbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, Ed25519FpConst.modulusLimbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var n7 = Uint64.adc(r7, c2, carry);
    r7 = n7.$1;
    // V = carry3 * 2^256 + (r4, r5, r6, r7) with V < 2p: every field value
    // in the system is maintained < p (all entry points reduce), products
    // are < p^2, and the Montgomery bound gives V < 2p. Two unconditional
    // subtract-p passes with mask-selects therefore always fully reduce V,
    // independent of its value. Each pass keeps d = R - p iff V >= p
    // (carry3 != 0 or R >= p) and keeps R otherwise; carry3 tracks the
    // high part in both cases.
    var carry3 = n7.$2;
    var result = [r4, r5, r6, r7];
    for (var k = 0; k < 2; k++) {
      var t = Uint64.sbb(
        result[0],
        Ed25519FpConst.modulusLimbs[0],
        Uint64.zero,
      );
      final d0 = t.$1;
      var b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[1], Ed25519FpConst.modulusLimbs[1], b);
      final d1 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[2], Ed25519FpConst.modulusLimbs[2], b);
      final d2 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[3], Ed25519FpConst.modulusLimbs[3], b);
      final d3 = t.$1;
      final doSub = (~t.$2) | (~Uint64.isZeroMask(carry3));
      final b01 = (t.$2 & Uint64.one) & (doSub & Uint64.one);
      carry3 = carry3 - b01;
      result = [
        (d0 & doSub) | (result[0] & ~doSub),
        (d1 & doSub) | (result[1] & ~doSub),
        (d2 & doSub) | (result[2] & ~doSub),
        (d3 & doSub) | (result[3] & ~doSub),
      ];
    }
    return Ed25519Fp(result);
  }
  Ed25519Fp subMod() {
    var t = Uint64.sbb(limbs[0], Ed25519FpConst.modulusLimbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], Ed25519FpConst.modulusLimbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], Ed25519FpConst.modulusLimbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], Ed25519FpConst.modulusLimbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    // Keep d iff no borrow (limbs >= mod), else keep limbs — mask blend,
    // no early return. t.$2 is a borrow mask (all-ones iff borrow).
    final d = Ed25519Fp([d0, d1, d2, d3]);
    return Ed25519Fp.conditionalSelectMask(this, d, (~b) & Uint64.one);
  }

  @override
  BuBytes toBytes({Endian endian = Endian.little}) {
    final t = Ed25519Fp.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );
    final r = BuBytes.fill(32);
    for (int i = 0; i < 4; i++) {
      if (endian == Endian.big) {
        r.setRange(
          (3 - i) * 8,
          (3 - i) * 8 + 8,
          t.limbs[i].toBytes(Endian.big),
        );
      } else {
        r.setRange(i * 8, i * 8 + 8, t.limbs[i].toBytes(Endian.little));
      }
    }
    return r;
  }

  @override
  bool isZero() => this == Ed25519Fp.zero;
  Ed25519Fp sub(Ed25519Fp rhs) {
    var t = Uint64.sbb(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], rhs.limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], rhs.limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], rhs.limbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    var a = Uint64.adc(d0, Ed25519FpConst.modulusLimbs[0] & b, Uint64.zero);
    d0 = a.$1;
    var c = a.$2;
    a = Uint64.adc(d1, Ed25519FpConst.modulusLimbs[1] & b, c);
    d1 = a.$1;
    c = a.$2;
    a = Uint64.adc(d2, Ed25519FpConst.modulusLimbs[2] & b, c);
    d2 = a.$1;
    c = a.$2;
    a = Uint64.adc(d3, Ed25519FpConst.modulusLimbs[3] & b, c);
    d3 = a.$1;
    return Ed25519Fp([d0, d1, d2, d3]);
  }

  Ed25519Fp add(Ed25519Fp rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 cc = t.$2;
    t = Uint64.adc(limbs[1], rhs.limbs[1], cc);
    Uint64 d1 = t.$1;
    cc = t.$2;
    t = Uint64.adc(limbs[2], rhs.limbs[2], cc);
    Uint64 d2 = t.$1;
    cc = t.$2;
    t = Uint64.adc(limbs[3], rhs.limbs[3], cc);
    Uint64 d3 = t.$1;
    Uint64 carry = t.$2;
    // Branch-free Montgomery correction: add r iff carry != 0. carry is
    // 0/1 for reduced inputs; the mask form also stays correct if a
    // wider carry ever appears.
    final m = ~Uint64.isZeroMask(carry);
    var u = Uint64.adc(d0, r.limbs[0] & m, Uint64.zero);
    d0 = u.$1;
    var cc2 = u.$2;
    u = Uint64.adc(d1, r.limbs[1] & m, cc2);
    d1 = u.$1;
    cc2 = u.$2;
    u = Uint64.adc(d2, r.limbs[2] & m, cc2);
    d2 = u.$1;
    cc2 = u.$2;
    u = Uint64.adc(d3, r.limbs[3] & m, cc2);
    d3 = u.$1;
    return Ed25519Fp([d0, d1, d2, d3]).subMod();
  }

  Ed25519Fp neg() {
    var t = Uint64.sbb(Ed25519FpConst.modulusLimbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(Ed25519FpConst.modulusLimbs[1], limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Ed25519FpConst.modulusLimbs[2], limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Ed25519FpConst.modulusLimbs[3], limbs[3], b);
    Uint64 d3 = t.$1;
    final z = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    // Branch-free zero mask: all-ones iff this == 0 (neg(0) == 0).
    final m = ~Uint64.isZeroMask(z);
    return Ed25519Fp([d0 & m, d1 & m, d2 & m, d3 & m]);
  }

  Ed25519Fp mul(Ed25519Fp rhs) {
    var t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 r0 = t.$1;
    Uint64 c = t.$2;
    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[1], c);
    Uint64 r1 = t.$1;
    c = t.$2;
    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[2], c);
    Uint64 r2 = t.$1;
    c = t.$2;
    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[3], c);
    Uint64 r3 = t.$1;
    Uint64 r4 = t.$2;
    t = Uint64.mac(r1, limbs[1], rhs.limbs[0], Uint64.zero);
    r1 = t.$1;
    c = t.$2;
    t = Uint64.mac(r2, limbs[1], rhs.limbs[1], c);
    r2 = t.$1;
    c = t.$2;
    t = Uint64.mac(r3, limbs[1], rhs.limbs[2], c);
    r3 = t.$1;
    c = t.$2;
    t = Uint64.mac(r4, limbs[1], rhs.limbs[3], c);
    r4 = t.$1;
    Uint64 r5 = t.$2;
    t = Uint64.mac(r2, limbs[2], rhs.limbs[0], Uint64.zero);
    r2 = t.$1;
    c = t.$2;
    t = Uint64.mac(r3, limbs[2], rhs.limbs[1], c);
    r3 = t.$1;
    c = t.$2;
    t = Uint64.mac(r4, limbs[2], rhs.limbs[2], c);
    r4 = t.$1;
    c = t.$2;
    t = Uint64.mac(r5, limbs[2], rhs.limbs[3], c);
    r5 = t.$1;
    Uint64 r6 = t.$2;
    t = Uint64.mac(r3, limbs[3], rhs.limbs[0], Uint64.zero);
    r3 = t.$1;
    c = t.$2;
    t = Uint64.mac(r4, limbs[3], rhs.limbs[1], c);
    r4 = t.$1;
    c = t.$2;
    t = Uint64.mac(r5, limbs[3], rhs.limbs[2], c);
    r5 = t.$1;
    c = t.$2;
    t = Uint64.mac(r6, limbs[3], rhs.limbs[3], c);
    r6 = t.$1;
    Uint64 r7 = t.$2;
    return Ed25519Fp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Ed25519Fp square() {
    var tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[1], Uint64.zero);
    Uint64 r1 = tmp.$1;
    Uint64 carry = tmp.$2;
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[2], carry);
    Uint64 r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[3], carry);
    Uint64 r3 = tmp.$1;
    Uint64 r4 = tmp.$2;
    tmp = Uint64.mac(r3, limbs[1], limbs[2], Uint64.zero);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, limbs[1], limbs[3], carry);
    r4 = tmp.$1;
    Uint64 r5 = tmp.$2;
    tmp = Uint64.mac(r5, limbs[2], limbs[3], Uint64.zero);
    r5 = tmp.$1;
    Uint64 r6 = tmp.$2;
    Uint64 r7 = r6 >> 63;
    r6 = (r6 << 1) | (r5 >> 63);
    r5 = (r5 << 1) | (r4 >> 63);
    r4 = (r4 << 1) | (r3 >> 63);
    r3 = (r3 << 1) | (r2 >> 63);
    r2 = (r2 << 1) | (r1 >> 63);
    r1 = r1 << 1;
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[0], Uint64.zero);
    Uint64 r0 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r1, carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, limbs[1], limbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r3, carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, limbs[2], limbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r5, carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, limbs[3], limbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r7, carry);
    r7 = tmp.$1;
    return Ed25519Fp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Ed25519Fp operator +(Ed25519Fp o) => add(o);
  @override
  Ed25519Fp operator -(Ed25519Fp o) => sub(o);
  @override
  Ed25519Fp operator *(Ed25519Fp o) => mul(o);
  @override
  Ed25519Fp operator -() => neg();
  @override
  Ed25519Fp double() => add(this);
  @override
  bool operator ==(Object other) =>
      other is Ed25519Fp && Uint64.ctEquals(limbs, other.limbs);
  @override
  int get hashCode => Object.hashAll(limbs);
  Ed25519Fp pow(List<Uint64> by) {
    var res = Ed25519Fp.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        final tmp = res * this;
        res = Ed25519Fp.conditionalSelectMask(res, tmp, (e >> i) & Uint64.one);
      }
    }
    return res;
  }

  Ed25519Fp powVartime(List<Uint64> by) {
    var res = Ed25519Fp.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) res = res * this;
      }
    }
    return res;
  }

  @override
  Ed25519Fp? invert() {
    if (isZero()) return null;
    const exp = [
      Uint64.unsafe(4294967295, 4294967275),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(2147483647, 4294967295),
    ];
    return pow(exp);
  }

  @override
  FieldSqrtResult<Ed25519Fp> sqrt() {
    const tm1d2 = [
      Uint64.unsafe(4294967295, 4294967293),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(268435455, 4294967295),
    ];
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powVartime(tm1d2),
      rootOfUnity: Ed25519Fp.unsafe([
        Uint64.unsafe(995624916, 4264286980),
        Uint64.unsafe(66425085, 3038505453),
        Uint64.unsafe(1835931327, 862061265),
        Uint64.unsafe(1970760459, 3603372968),
      ]),
      s: Ed25519FpConst.s,
      one: Ed25519Fp.r,
      conditionalSelect: (a, b, c) => Ed25519Fp.conditionalSelect(a, b, c),
    );
  }
}

class Ed25519Fr extends EdwardsScalar<Ed25519Fr> with Equality {
  final List<Uint64> limbs;
  const Ed25519Fr.unsafe(this.limbs);
  Ed25519Fr(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "Ed25519Fr").immutable;
  @override
  List<dynamic> get variables => limbs;
  static const Ed25519Fr zero = Ed25519Fr.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const Ed25519Fr one = r;

  static const Ed25519Fr r = Ed25519Fr.unsafe([
    Uint64.unsafe(3605803380, 2375587101),
    Uint64.unsafe(3337575412, 1937624944),
    Uint64.unsafe(4294967295, 4294967294),
    Uint64.unsafe(268435455, 4294967295),
  ]);
  static const Ed25519Fr r2 = Ed25519Fr.unsafe([
    Uint64.unsafe(2751861219, 1151078145),
    Uint64.unsafe(3490585511, 1753584455),
    Uint64.unsafe(3471602642, 401981029),
    Uint64.unsafe(60375323, 2083559997),
  ]);
  static const Ed25519Fr r3 = Ed25519Fr.unsafe([
    Uint64.unsafe(715016552, 2072224475),
    Uint64.unsafe(662906086, 2935485420),
    Uint64.unsafe(2154159212, 82598757),
    Uint64.unsafe(240323447, 899272391),
  ]);
  factory Ed25519Fr.from(Uint64 v) =>
      Ed25519Fr([v, Uint64.zero, Uint64.zero, Uint64.zero]).mul(Ed25519Fr.r2);
  factory Ed25519Fr.fromRaw(List<Uint64> v) => Ed25519Fr(v).mul(Ed25519Fr.r2);
  factory Ed25519Fr._fromU512(List<Uint64> l) {
    final d0 = Ed25519Fr([l[0], l[1], l[2], l[3]]);
    final d1 = Ed25519Fr([l[4], l[5], l[6], l[7]]);
    return d0 * Ed25519Fr.r2 + d1 * Ed25519Fr.r3;
  }
  factory Ed25519Fr.conditionalSelect(Ed25519Fr a, Ed25519Fr b, bool c) =>
      Ed25519Fr([
        Uint64.ctSelect(a.limbs[0], b.limbs[0], c),
        Uint64.ctSelect(a.limbs[1], b.limbs[1], c),
        Uint64.ctSelect(a.limbs[2], b.limbs[2], c),
        Uint64.ctSelect(a.limbs[3], b.limbs[3], c),
      ]);

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so the whole select is straight-line limb arithmetic.
  factory Ed25519Fr.conditionalSelectMask(
    Ed25519Fr a,
    Ed25519Fr b,
    Uint64 bit,
  ) => Ed25519Fr([
    Uint64.selectBit(a.limbs[0], b.limbs[0], bit),
    Uint64.selectBit(a.limbs[1], b.limbs[1], bit),
    Uint64.selectBit(a.limbs[2], b.limbs[2], bit),
    Uint64.selectBit(a.limbs[3], b.limbs[3], bit),
  ]);
  factory Ed25519Fr.fromBytes(List<int> b, {Endian endian = Endian.little}) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    final t = Ed25519Fr(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
    var bm = Uint64.zero;
    var tp = Uint64.sbb(t.limbs[0], Ed25519FrConst.modulusLimbs[0], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[1], Ed25519FrConst.modulusLimbs[1], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[2], Ed25519FrConst.modulusLimbs[2], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[3], Ed25519FrConst.modulusLimbs[3], bm);
    bm = tp.$2;
    final r = t * Ed25519Fr.r2;
    if ((bm & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid encoding.",
      );
    }
    return r;
  }
  factory Ed25519Fr.fromBytesUnchecked(
    List<int> b, {
    Endian endian = Endian.little,
  }) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    return Ed25519Fr.fromRaw(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Ed25519Fr.fromBytes64(List<int> b) {
    if (b.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid length.",
      );
    }
    return Ed25519Fr._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Ed25519Fr.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * Ed25519FrConst.inv;
    var tmp = Uint64.mac(r0, k, Ed25519FrConst.modulusLimbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, Ed25519FrConst.modulusLimbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Ed25519FrConst.modulusLimbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Ed25519FrConst.modulusLimbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var n4 = Uint64.adc(r4, Uint64.zero, carry);
    r4 = n4.$1;
    var c2 = n4.$2;
    k = r1 * Ed25519FrConst.inv;
    tmp = Uint64.mac(r1, k, Ed25519FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Ed25519FrConst.modulusLimbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Ed25519FrConst.modulusLimbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Ed25519FrConst.modulusLimbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var n5 = Uint64.adc(r5, c2, carry);
    r5 = n5.$1;
    c2 = n5.$2;
    k = r2 * Ed25519FrConst.inv;
    tmp = Uint64.mac(r2, k, Ed25519FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Ed25519FrConst.modulusLimbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Ed25519FrConst.modulusLimbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Ed25519FrConst.modulusLimbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var n6 = Uint64.adc(r6, c2, carry);
    r6 = n6.$1;
    c2 = n6.$2;
    k = r3 * Ed25519FrConst.inv;
    tmp = Uint64.mac(r3, k, Ed25519FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Ed25519FrConst.modulusLimbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Ed25519FrConst.modulusLimbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, Ed25519FrConst.modulusLimbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var n7 = Uint64.adc(r7, c2, carry);
    r7 = n7.$1;
    // V = carry3 * 2^256 + (r4, r5, r6, r7) with V < 2L: every scalar-field
    // value in the system is maintained < L (all entry points reduce),
    // products are < L^2, and the Montgomery bound gives V < 2L. Two
    // unconditional subtract-L passes with mask-selects therefore always
    // fully reduce V, independent of its value. Each pass keeps d = R - L
    // iff V >= L (carry3 != 0 or R >= L) and keeps R otherwise; carry3
    // tracks the high part in both cases.
    var carry3 = n7.$2;
    var result = [r4, r5, r6, r7];
    for (var k = 0; k < 2; k++) {
      var t = Uint64.sbb(
        result[0],
        Ed25519FrConst.modulusLimbs[0],
        Uint64.zero,
      );
      final d0 = t.$1;
      var b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[1], Ed25519FrConst.modulusLimbs[1], b);
      final d1 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[2], Ed25519FrConst.modulusLimbs[2], b);
      final d2 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[3], Ed25519FrConst.modulusLimbs[3], b);
      final d3 = t.$1;
      final doSub = (~t.$2) | (~Uint64.isZeroMask(carry3));
      final b01 = (t.$2 & Uint64.one) & (doSub & Uint64.one);
      carry3 = carry3 - b01;
      result = [
        (d0 & doSub) | (result[0] & ~doSub),
        (d1 & doSub) | (result[1] & ~doSub),
        (d2 & doSub) | (result[2] & ~doSub),
        (d3 & doSub) | (result[3] & ~doSub),
      ];
    }
    return Ed25519Fr(result);
  }
  Ed25519Fr subMod() {
    var t = Uint64.sbb(limbs[0], Ed25519FrConst.modulusLimbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], Ed25519FrConst.modulusLimbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], Ed25519FrConst.modulusLimbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], Ed25519FrConst.modulusLimbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    // Keep d iff no borrow (limbs >= mod), else keep limbs — mask blend,
    // no early return. t.$2 is a borrow mask (all-ones iff borrow).
    final d = Ed25519Fr([d0, d1, d2, d3]);
    return Ed25519Fr.conditionalSelectMask(this, d, (~b) & Uint64.one);
  }

  @override
  BuBytes toBytes({Endian endian = Endian.little}) {
    final t = Ed25519Fr.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );
    final r = BuBytes.fill(32);
    for (int i = 0; i < 4; i++) {
      if (endian == Endian.big) {
        r.setRange(
          (3 - i) * 8,
          (3 - i) * 8 + 8,
          t.limbs[i].toBytes(Endian.big),
        );
      } else {
        r.setRange(i * 8, i * 8 + 8, t.limbs[i].toBytes(Endian.little));
      }
    }
    return r;
  }

  @override
  bool isZero() => this == Ed25519Fr.zero;
  Ed25519Fr sub(Ed25519Fr rhs) {
    var t = Uint64.sbb(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], rhs.limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], rhs.limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], rhs.limbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    var a = Uint64.adc(d0, Ed25519FrConst.modulusLimbs[0] & b, Uint64.zero);
    d0 = a.$1;
    var c = a.$2;
    a = Uint64.adc(d1, Ed25519FrConst.modulusLimbs[1] & b, c);
    d1 = a.$1;
    c = a.$2;
    a = Uint64.adc(d2, Ed25519FrConst.modulusLimbs[2] & b, c);
    d2 = a.$1;
    c = a.$2;
    a = Uint64.adc(d3, Ed25519FrConst.modulusLimbs[3] & b, c);
    d3 = a.$1;
    return Ed25519Fr([d0, d1, d2, d3]);
  }

  Ed25519Fr add(Ed25519Fr rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 cc = t.$2;
    t = Uint64.adc(limbs[1], rhs.limbs[1], cc);
    Uint64 d1 = t.$1;
    cc = t.$2;
    t = Uint64.adc(limbs[2], rhs.limbs[2], cc);
    Uint64 d2 = t.$1;
    cc = t.$2;
    t = Uint64.adc(limbs[3], rhs.limbs[3], cc);
    Uint64 d3 = t.$1;
    Uint64 carry = t.$2;
    // Branch-free Montgomery correction: add r iff carry != 0. carry is
    // 0/1 for reduced inputs; the mask form also stays correct if a
    // wider carry ever appears.
    final m = ~Uint64.isZeroMask(carry);
    var u = Uint64.adc(d0, r.limbs[0] & m, Uint64.zero);
    d0 = u.$1;
    var cc2 = u.$2;
    u = Uint64.adc(d1, r.limbs[1] & m, cc2);
    d1 = u.$1;
    cc2 = u.$2;
    u = Uint64.adc(d2, r.limbs[2] & m, cc2);
    d2 = u.$1;
    cc2 = u.$2;
    u = Uint64.adc(d3, r.limbs[3] & m, cc2);
    d3 = u.$1;
    return Ed25519Fr([d0, d1, d2, d3]).subMod();
  }

  Ed25519Fr neg() {
    var t = Uint64.sbb(Ed25519FrConst.modulusLimbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(Ed25519FrConst.modulusLimbs[1], limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Ed25519FrConst.modulusLimbs[2], limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Ed25519FrConst.modulusLimbs[3], limbs[3], b);
    Uint64 d3 = t.$1;
    final z = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    // Branch-free zero mask: all-ones iff this == 0 (neg(0) == 0).
    final m = ~Uint64.isZeroMask(z);
    return Ed25519Fr([d0 & m, d1 & m, d2 & m, d3 & m]);
  }

  Ed25519Fr mul(Ed25519Fr rhs) {
    var t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 r0 = t.$1;
    Uint64 c = t.$2;
    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[1], c);
    Uint64 r1 = t.$1;
    c = t.$2;
    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[2], c);
    Uint64 r2 = t.$1;
    c = t.$2;
    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[3], c);
    Uint64 r3 = t.$1;
    Uint64 r4 = t.$2;
    t = Uint64.mac(r1, limbs[1], rhs.limbs[0], Uint64.zero);
    r1 = t.$1;
    c = t.$2;
    t = Uint64.mac(r2, limbs[1], rhs.limbs[1], c);
    r2 = t.$1;
    c = t.$2;
    t = Uint64.mac(r3, limbs[1], rhs.limbs[2], c);
    r3 = t.$1;
    c = t.$2;
    t = Uint64.mac(r4, limbs[1], rhs.limbs[3], c);
    r4 = t.$1;
    Uint64 r5 = t.$2;
    t = Uint64.mac(r2, limbs[2], rhs.limbs[0], Uint64.zero);
    r2 = t.$1;
    c = t.$2;
    t = Uint64.mac(r3, limbs[2], rhs.limbs[1], c);
    r3 = t.$1;
    c = t.$2;
    t = Uint64.mac(r4, limbs[2], rhs.limbs[2], c);
    r4 = t.$1;
    c = t.$2;
    t = Uint64.mac(r5, limbs[2], rhs.limbs[3], c);
    r5 = t.$1;
    Uint64 r6 = t.$2;
    t = Uint64.mac(r3, limbs[3], rhs.limbs[0], Uint64.zero);
    r3 = t.$1;
    c = t.$2;
    t = Uint64.mac(r4, limbs[3], rhs.limbs[1], c);
    r4 = t.$1;
    c = t.$2;
    t = Uint64.mac(r5, limbs[3], rhs.limbs[2], c);
    r5 = t.$1;
    c = t.$2;
    t = Uint64.mac(r6, limbs[3], rhs.limbs[3], c);
    r6 = t.$1;
    Uint64 r7 = t.$2;
    return Ed25519Fr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Ed25519Fr square() {
    var tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[1], Uint64.zero);
    Uint64 r1 = tmp.$1;
    Uint64 carry = tmp.$2;
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[2], carry);
    Uint64 r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[3], carry);
    Uint64 r3 = tmp.$1;
    Uint64 r4 = tmp.$2;
    tmp = Uint64.mac(r3, limbs[1], limbs[2], Uint64.zero);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, limbs[1], limbs[3], carry);
    r4 = tmp.$1;
    Uint64 r5 = tmp.$2;
    tmp = Uint64.mac(r5, limbs[2], limbs[3], Uint64.zero);
    r5 = tmp.$1;
    Uint64 r6 = tmp.$2;
    Uint64 r7 = r6 >> 63;
    r6 = (r6 << 1) | (r5 >> 63);
    r5 = (r5 << 1) | (r4 >> 63);
    r4 = (r4 << 1) | (r3 >> 63);
    r3 = (r3 << 1) | (r2 >> 63);
    r2 = (r2 << 1) | (r1 >> 63);
    r1 = r1 << 1;
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[0], Uint64.zero);
    Uint64 r0 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r1, carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, limbs[1], limbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r3, carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, limbs[2], limbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r5, carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, limbs[3], limbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.adc(Uint64.zero, r7, carry);
    r7 = tmp.$1;
    return Ed25519Fr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Ed25519Fr operator +(Ed25519Fr o) => add(o);
  @override
  Ed25519Fr operator -(Ed25519Fr o) => sub(o);
  @override
  Ed25519Fr operator *(Ed25519Fr o) => mul(o);
  @override
  Ed25519Fr operator -() => neg();
  @override
  Ed25519Fr double() => add(this);
  @override
  bool operator ==(Object other) =>
      other is Ed25519Fr && Uint64.ctEquals(limbs, other.limbs);
  @override
  int get hashCode => Object.hashAll(limbs);
  Ed25519Fr pow(List<Uint64> by) {
    var res = Ed25519Fr.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        final tmp = res * this;
        res = Ed25519Fr.conditionalSelectMask(res, tmp, (e >> i) & Uint64.one);
      }
    }
    return res;
  }

  Ed25519Fr powVartime(List<Uint64> by) {
    var res = Ed25519Fr.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) res = res * this;
      }
    }
    return res;
  }

  @override
  Ed25519Fr? invert() {
    if (isZero()) return null;
    const exp = [
      Uint64.unsafe(1477600026, 1559614443),
      Uint64.unsafe(350157278, 2734136534),
      Uint64.unsafe(0, 0),
      Uint64.unsafe(268435456, 0),
    ];
    return pow(exp);
  }

  @override
  FieldSqrtResult<Ed25519Fr> sqrt() {
    const tm1d2 = [
      Uint64.unsafe(3405925475, 1268693629),
      Uint64.unsafe(43769659, 3562992538),
      Uint64.unsafe(0, 0),
      Uint64.unsafe(33554432, 0),
    ];
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powVartime(tm1d2),
      rootOfUnity: Ed25519Fr.unsafe([
        Uint64.unsafe(2088308274, 3022982781),
        Uint64.unsafe(1284302598, 2813209800),
        Uint64.unsafe(3610780620, 2451012013),
        Uint64.unsafe(89758041, 2302629418),
      ]),
      s: Ed25519FrConst.s,
      one: Ed25519Fr.r,
      conditionalSelect: (a, b, c) => Ed25519Fr.conditionalSelect(a, b, c),
    );
  }
}

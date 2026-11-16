import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/src/constants.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

abstract class WeierstrassPrimeField<F extends WeierstrassPrimeField<F>>
    extends CryptoField<F> {
  const WeierstrassPrimeField();
  BuBytes toBytes();
}

abstract class WeierstrassField<F extends WeierstrassField<F>>
    extends WeierstrassPrimeField<F> {
  const WeierstrassField();
}

abstract class WeierstrassScalar<F extends WeierstrassScalar<F>>
    extends WeierstrassPrimeField<F> {
  const WeierstrassScalar();
}

class Secp256k1Fp extends WeierstrassField<Secp256k1Fp> with Equality {
  final List<Uint64> limbs;
  const Secp256k1Fp.unsafe(this.limbs);
  Secp256k1Fp(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "Secp256k1Fp").immutable;
  @override
  List<dynamic> get variables => limbs;
  static const Secp256k1Fp zero = Secp256k1Fp.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const Secp256k1Fp one = r;
  static const Secp256k1Fp r = Secp256k1Fp.unsafe([
    Uint64.unsafe(1, 977),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);
  static const Secp256k1Fp r2 = Secp256k1Fp.unsafe([
    Uint64.unsafe(1954, 954529),
    Uint64.unsafe(0, 1),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);

  static const Secp256k1Fp r3 = Secp256k1Fp.unsafe([
    Uint64.unsafe(2863587, 932574833),
    Uint64.unsafe(1, 2931),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 0),
  ]);
  factory Secp256k1Fp.from(Uint64 v) => Secp256k1Fp([
    v,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]).mul(Secp256k1Fp.r2);
  factory Secp256k1Fp.fromRaw(List<Uint64> v) =>
      Secp256k1Fp(v).mul(Secp256k1Fp.r2);
  factory Secp256k1Fp._fromU512(List<Uint64> l) {
    final d0 = Secp256k1Fp([l[0], l[1], l[2], l[3]]);
    final d1 = Secp256k1Fp([l[4], l[5], l[6], l[7]]);
    return d0 * Secp256k1Fp.r2 + d1 * Secp256k1Fp.r3;
  }
  factory Secp256k1Fp.conditionalSelect(Secp256k1Fp a, Secp256k1Fp b, bool c) =>
      Secp256k1Fp([
        Uint64.ctSelect(a.limbs[0], b.limbs[0], c),
        Uint64.ctSelect(a.limbs[1], b.limbs[1], c),
        Uint64.ctSelect(a.limbs[2], b.limbs[2], c),
        Uint64.ctSelect(a.limbs[3], b.limbs[3], c),
      ]);

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so the whole select is straight-line limb arithmetic.
  factory Secp256k1Fp.conditionalSelectMask(
    Secp256k1Fp a,
    Secp256k1Fp b,
    Uint64 bit,
  ) => Secp256k1Fp([
    Uint64.selectBit(a.limbs[0], b.limbs[0], bit),
    Uint64.selectBit(a.limbs[1], b.limbs[1], bit),
    Uint64.selectBit(a.limbs[2], b.limbs[2], bit),
    Uint64.selectBit(a.limbs[3], b.limbs[3], bit),
  ]);
  factory Secp256k1Fp.fromBytes(List<int> b, {Endian endian = Endian.big}) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    final t = Secp256k1Fp(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
    var bm = Uint64.zero;
    var tp = Uint64.sbb(t.limbs[0], Secp256k1FpConst.modulusLimbs[0], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[1], Secp256k1FpConst.modulusLimbs[1], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[2], Secp256k1FpConst.modulusLimbs[2], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[3], Secp256k1FpConst.modulusLimbs[3], bm);
    bm = tp.$2;
    final r = t * Secp256k1Fp.r2;
    if ((bm & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid encoding.",
      );
    }
    return r;
  }
  factory Secp256k1Fp.fromBytesUnchecked(
    List<int> b, {
    Endian endian = Endian.big,
  }) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    return Secp256k1Fp.fromRaw(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256k1Fp.fromBytes64(List<int> b) {
    if (b.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid length.",
      );
    }
    return Secp256k1Fp._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256k1Fp.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * Secp256k1FpConst.inv;
    var tmp = Uint64.mac(r0, k, Secp256k1FpConst.modulusLimbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, Secp256k1FpConst.modulusLimbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256k1FpConst.modulusLimbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256k1FpConst.modulusLimbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var n4 = Uint64.adc(r4, Uint64.zero, carry);
    r4 = n4.$1;
    var c2 = n4.$2;
    k = r1 * Secp256k1FpConst.inv;
    tmp = Uint64.mac(r1, k, Secp256k1FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256k1FpConst.modulusLimbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256k1FpConst.modulusLimbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256k1FpConst.modulusLimbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var n5 = Uint64.adc(r5, c2, carry);
    r5 = n5.$1;
    c2 = n5.$2;
    k = r2 * Secp256k1FpConst.inv;
    tmp = Uint64.mac(r2, k, Secp256k1FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256k1FpConst.modulusLimbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256k1FpConst.modulusLimbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256k1FpConst.modulusLimbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var n6 = Uint64.adc(r6, c2, carry);
    r6 = n6.$1;
    c2 = n6.$2;
    k = r3 * Secp256k1FpConst.inv;
    tmp = Uint64.mac(r3, k, Secp256k1FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256k1FpConst.modulusLimbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256k1FpConst.modulusLimbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, Secp256k1FpConst.modulusLimbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var n7 = Uint64.adc(r7, c2, carry);
    r7 = n7.$1;
    // The pre-reduction value is V = carry3 * 2^256 + (r4, r5, r6, r7).
    // Fixed passes (no early exit): V < 3*2^256 < 5p (carry3 <= 2 and every
    // modulus here exceeds 2^255), so four unconditional passes always fully
    // reduce V, independent of its value. Each pass keeps d = R - p iff
    // V >= p (carry3 != 0 or R >= p) and keeps R otherwise; carry3 tracks
    // the high part in both cases.
    var carry3 = n7.$2;
    var result = [r4, r5, r6, r7];
    for (var k = 0; k < 4; k++) {
      var t = Uint64.sbb(
        result[0],
        Secp256k1FpConst.modulusLimbs[0],
        Uint64.zero,
      );
      final d0 = t.$1;
      var b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[1], Secp256k1FpConst.modulusLimbs[1], b);
      final d1 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[2], Secp256k1FpConst.modulusLimbs[2], b);
      final d2 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[3], Secp256k1FpConst.modulusLimbs[3], b);
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
    return Secp256k1Fp(result);
  }
  Secp256k1Fp subMod() {
    var t = Uint64.sbb(limbs[0], Secp256k1FpConst.modulusLimbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], Secp256k1FpConst.modulusLimbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], Secp256k1FpConst.modulusLimbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], Secp256k1FpConst.modulusLimbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    // Keep d iff no borrow (limbs >= mod), else keep limbs — mask blend,
    // no early return.
    final d = Secp256k1Fp([d0, d1, d2, d3]);
    return Secp256k1Fp.conditionalSelectMask(this, d, (~b) & Uint64.one);
  }

  @override
  BuBytes toBytes({Endian endian = Endian.big}) {
    final t = Secp256k1Fp.montgomeryReduce(
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
  bool isZero() => this == Secp256k1Fp.zero;
  Secp256k1Fp sub(Secp256k1Fp rhs) {
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
    var a = Uint64.adc(d0, Secp256k1FpConst.modulusLimbs[0] & b, Uint64.zero);
    d0 = a.$1;
    var c = a.$2;
    a = Uint64.adc(d1, Secp256k1FpConst.modulusLimbs[1] & b, c);
    d1 = a.$1;
    c = a.$2;
    a = Uint64.adc(d2, Secp256k1FpConst.modulusLimbs[2] & b, c);
    d2 = a.$1;
    c = a.$2;
    a = Uint64.adc(d3, Secp256k1FpConst.modulusLimbs[3] & b, c);
    d3 = a.$1;
    return Secp256k1Fp([d0, d1, d2, d3]);
  }

  Secp256k1Fp add(Secp256k1Fp rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 c = t.$2;
    t = Uint64.adc(limbs[1], rhs.limbs[1], c);
    Uint64 d1 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[2], rhs.limbs[2], c);
    Uint64 d2 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[3], rhs.limbs[3], c);
    Uint64 d3 = t.$1;
    Uint64 carry = t.$2;
    // Branch-free Montgomery correction: add r iff carry != 0.
    final m = Uint64.zero - carry;
    var u = Uint64.adc(d0, r.limbs[0] & m, Uint64.zero);
    d0 = u.$1;
    var cc = u.$2;
    u = Uint64.adc(d1, r.limbs[1] & m, cc);
    d1 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d2, r.limbs[2] & m, cc);
    d2 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d3, r.limbs[3] & m, cc);
    d3 = u.$1;
    return Secp256k1Fp([d0, d1, d2, d3]).subMod();
  }

  Secp256k1Fp neg() {
    var t = Uint64.sbb(Secp256k1FpConst.modulusLimbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(Secp256k1FpConst.modulusLimbs[1], limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256k1FpConst.modulusLimbs[2], limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256k1FpConst.modulusLimbs[3], limbs[3], b);
    Uint64 d3 = t.$1;
    final m = ~Uint64.isZeroMask(limbs[0] | limbs[1] | limbs[2] | limbs[3]);
    return Secp256k1Fp([d0 & m, d1 & m, d2 & m, d3 & m]);
  }

  Secp256k1Fp mul(Secp256k1Fp rhs) {
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
    return Secp256k1Fp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256k1Fp square() {
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
    return Secp256k1Fp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256k1Fp operator +(Secp256k1Fp o) => add(o);
  @override
  Secp256k1Fp operator -(Secp256k1Fp o) => sub(o);
  @override
  Secp256k1Fp operator *(Secp256k1Fp o) => mul(o);
  @override
  Secp256k1Fp operator -() => neg();
  @override
  Secp256k1Fp double() => add(this);
  @override
  bool operator ==(Object other) =>
      other is Secp256k1Fp && Uint64.ctEquals(limbs, other.limbs);
  @override
  int get hashCode => Object.hashAll(limbs);
  Secp256k1Fp pow(List<Uint64> by) {
    var res = Secp256k1Fp.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        final tmp = res * this;
        res = Secp256k1Fp.conditionalSelectMask(
          res,
          tmp,
          (e >> i) & Uint64.one,
        );
      }
    }
    return res;
  }

  Secp256k1Fp powVartime(List<Uint64> by) {
    var res = Secp256k1Fp.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) res = res * this;
      }
    }
    return res;
  }

  @override
  Secp256k1Fp? invert() {
    if (isZero()) return null;
    const exp = [
      Uint64.unsafe(4294967294, 4294966317),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(4294967295, 4294967295),
    ];
    return pow(exp);
  }

  @override
  FieldSqrtResult<Secp256k1Fp> sqrt() {
    const exp = [
      Uint64.unsafe(4294967295, 3221225228),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ];
    final c = powVartime(exp);
    return FieldSqrtResult(c, (c * c) == this);
  }
}

class Secp256k1Fr extends WeierstrassScalar<Secp256k1Fr> with Equality {
  final List<Uint64> limbs;
  const Secp256k1Fr.unsafe(this.limbs);
  Secp256k1Fr(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "Secp256k1Fr").immutable;
  @override
  List<dynamic> get variables => limbs;
  static const Secp256k1Fr zero = Secp256k1Fr.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const Secp256k1Fr one = r;
  static const Secp256k1Fr r = Secp256k1Fr.unsafe([
    Uint64.unsafe(1076732275, 801750719),
    Uint64.unsafe(1162945305, 1354194884),
    Uint64.unsafe(0, 1),
    Uint64.unsafe(0, 0),
  ]);
  static const Secp256k1Fr r2 = Secp256k1Fr.unsafe([
    Uint64.unsafe(2305618452, 1742197056),
    Uint64.unsafe(1947506370, 243071096),
    Uint64.unsafe(3868718564, 1540163526),
    Uint64.unsafe(2640780501, 2177276869),
  ]);

  static const Secp256k1Fr r3 = Secp256k1Fr.unsafe([
    Uint64.unsafe(2076233696, 3925819885),
    Uint64.unsafe(1533060, 1154757164),
    Uint64.unsafe(2981303111, 4056986330),
    Uint64.unsafe(1432190988, 418320749),
  ]);
  factory Secp256k1Fr.from(Uint64 v) => Secp256k1Fr([
    v,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]).mul(Secp256k1Fr.r2);
  factory Secp256k1Fr.fromRaw(List<Uint64> v) =>
      Secp256k1Fr(v).mul(Secp256k1Fr.r2);
  factory Secp256k1Fr._fromU512(List<Uint64> l) {
    final d0 = Secp256k1Fr([l[0], l[1], l[2], l[3]]);
    final d1 = Secp256k1Fr([l[4], l[5], l[6], l[7]]);
    return d0 * Secp256k1Fr.r2 + d1 * Secp256k1Fr.r3;
  }
  factory Secp256k1Fr.conditionalSelect(Secp256k1Fr a, Secp256k1Fr b, bool c) =>
      Secp256k1Fr([
        Uint64.ctSelect(a.limbs[0], b.limbs[0], c),
        Uint64.ctSelect(a.limbs[1], b.limbs[1], c),
        Uint64.ctSelect(a.limbs[2], b.limbs[2], c),
        Uint64.ctSelect(a.limbs[3], b.limbs[3], c),
      ]);

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so the whole select is straight-line limb arithmetic.
  factory Secp256k1Fr.conditionalSelectMask(
    Secp256k1Fr a,
    Secp256k1Fr b,
    Uint64 bit,
  ) => Secp256k1Fr([
    Uint64.selectBit(a.limbs[0], b.limbs[0], bit),
    Uint64.selectBit(a.limbs[1], b.limbs[1], bit),
    Uint64.selectBit(a.limbs[2], b.limbs[2], bit),
    Uint64.selectBit(a.limbs[3], b.limbs[3], bit),
  ]);
  factory Secp256k1Fr.fromBytes(List<int> b, {Endian endian = Endian.big}) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    final t = Secp256k1Fr(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
    var bm = Uint64.zero;
    var tp = Uint64.sbb(t.limbs[0], Secp256k1FrConst.modulusLimbs[0], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[1], Secp256k1FrConst.modulusLimbs[1], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[2], Secp256k1FrConst.modulusLimbs[2], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[3], Secp256k1FrConst.modulusLimbs[3], bm);
    bm = tp.$2;
    final r = t * Secp256k1Fr.r2;
    if ((bm & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid encoding.",
      );
    }
    return r;
  }
  factory Secp256k1Fr.fromBytesUnchecked(
    List<int> b, {
    Endian endian = Endian.big,
  }) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    return Secp256k1Fr.fromRaw(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256k1Fr.fromBytes64(List<int> b) {
    if (b.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid length.",
      );
    }
    return Secp256k1Fr._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256k1Fr.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * Secp256k1FrConst.inv;
    var tmp = Uint64.mac(r0, k, Secp256k1FrConst.modulusLimbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, Secp256k1FrConst.modulusLimbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256k1FrConst.modulusLimbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256k1FrConst.modulusLimbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var n4 = Uint64.adc(r4, Uint64.zero, carry);
    r4 = n4.$1;
    var c2 = n4.$2;
    k = r1 * Secp256k1FrConst.inv;
    tmp = Uint64.mac(r1, k, Secp256k1FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256k1FrConst.modulusLimbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256k1FrConst.modulusLimbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256k1FrConst.modulusLimbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var n5 = Uint64.adc(r5, c2, carry);
    r5 = n5.$1;
    c2 = n5.$2;
    k = r2 * Secp256k1FrConst.inv;
    tmp = Uint64.mac(r2, k, Secp256k1FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256k1FrConst.modulusLimbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256k1FrConst.modulusLimbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256k1FrConst.modulusLimbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var n6 = Uint64.adc(r6, c2, carry);
    r6 = n6.$1;
    c2 = n6.$2;
    k = r3 * Secp256k1FrConst.inv;
    tmp = Uint64.mac(r3, k, Secp256k1FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256k1FrConst.modulusLimbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256k1FrConst.modulusLimbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, Secp256k1FrConst.modulusLimbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var n7 = Uint64.adc(r7, c2, carry);
    r7 = n7.$1;
    // The pre-reduction value is V = carry3 * 2^256 + (r4, r5, r6, r7).
    // Fixed passes (no early exit): V < 3*2^256 < 5p (carry3 <= 2 and every
    // modulus here exceeds 2^255), so four unconditional passes always fully
    // reduce V, independent of its value. Each pass keeps d = R - p iff
    // V >= p (carry3 != 0 or R >= p) and keeps R otherwise; carry3 tracks
    // the high part in both cases.
    var carry3 = n7.$2;
    var result = [r4, r5, r6, r7];
    for (var k = 0; k < 4; k++) {
      var t = Uint64.sbb(
        result[0],
        Secp256k1FrConst.modulusLimbs[0],
        Uint64.zero,
      );
      final d0 = t.$1;
      var b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[1], Secp256k1FrConst.modulusLimbs[1], b);
      final d1 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[2], Secp256k1FrConst.modulusLimbs[2], b);
      final d2 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[3], Secp256k1FrConst.modulusLimbs[3], b);
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
    return Secp256k1Fr(result);
  }
  Secp256k1Fr subMod() {
    var t = Uint64.sbb(limbs[0], Secp256k1FrConst.modulusLimbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], Secp256k1FrConst.modulusLimbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], Secp256k1FrConst.modulusLimbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], Secp256k1FrConst.modulusLimbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    // Keep d iff no borrow (limbs >= mod), else keep limbs — mask blend,
    // no early return.
    final d = Secp256k1Fr([d0, d1, d2, d3]);
    return Secp256k1Fr.conditionalSelectMask(this, d, (~b) & Uint64.one);
  }

  @override
  BuBytes toBytes({Endian endian = Endian.big}) {
    final t = Secp256k1Fr.montgomeryReduce(
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
  bool isZero() => this == Secp256k1Fr.zero;
  Secp256k1Fr sub(Secp256k1Fr rhs) {
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
    var a = Uint64.adc(d0, Secp256k1FrConst.modulusLimbs[0] & b, Uint64.zero);
    d0 = a.$1;
    var c = a.$2;
    a = Uint64.adc(d1, Secp256k1FrConst.modulusLimbs[1] & b, c);
    d1 = a.$1;
    c = a.$2;
    a = Uint64.adc(d2, Secp256k1FrConst.modulusLimbs[2] & b, c);
    d2 = a.$1;
    c = a.$2;
    a = Uint64.adc(d3, Secp256k1FrConst.modulusLimbs[3] & b, c);
    d3 = a.$1;
    return Secp256k1Fr([d0, d1, d2, d3]);
  }

  Secp256k1Fr add(Secp256k1Fr rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 c = t.$2;
    t = Uint64.adc(limbs[1], rhs.limbs[1], c);
    Uint64 d1 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[2], rhs.limbs[2], c);
    Uint64 d2 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[3], rhs.limbs[3], c);
    Uint64 d3 = t.$1;
    Uint64 carry = t.$2;
    // Branch-free Montgomery correction: add r iff carry != 0.
    final m = Uint64.zero - carry;
    var u = Uint64.adc(d0, r.limbs[0] & m, Uint64.zero);
    d0 = u.$1;
    var cc = u.$2;
    u = Uint64.adc(d1, r.limbs[1] & m, cc);
    d1 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d2, r.limbs[2] & m, cc);
    d2 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d3, r.limbs[3] & m, cc);
    d3 = u.$1;
    return Secp256k1Fr([d0, d1, d2, d3]).subMod();
  }

  Secp256k1Fr neg() {
    var t = Uint64.sbb(Secp256k1FrConst.modulusLimbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(Secp256k1FrConst.modulusLimbs[1], limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256k1FrConst.modulusLimbs[2], limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256k1FrConst.modulusLimbs[3], limbs[3], b);
    Uint64 d3 = t.$1;
    final m = ~Uint64.isZeroMask(limbs[0] | limbs[1] | limbs[2] | limbs[3]);
    return Secp256k1Fr([d0 & m, d1 & m, d2 & m, d3 & m]);
  }

  Secp256k1Fr mul(Secp256k1Fr rhs) {
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
    return Secp256k1Fr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256k1Fr square() {
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
    return Secp256k1Fr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256k1Fr operator +(Secp256k1Fr o) => add(o);
  @override
  Secp256k1Fr operator -(Secp256k1Fr o) => sub(o);
  @override
  Secp256k1Fr operator *(Secp256k1Fr o) => mul(o);
  @override
  Secp256k1Fr operator -() => neg();
  @override
  Secp256k1Fr double() => add(this);
  @override
  bool operator ==(Object other) =>
      other is Secp256k1Fr && Uint64.ctEquals(limbs, other.limbs);
  @override
  int get hashCode => Object.hashAll(limbs);
  Secp256k1Fr pow(List<Uint64> by) {
    var res = Secp256k1Fr.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        final tmp = res * this;
        res = Secp256k1Fr.conditionalSelectMask(
          res,
          tmp,
          (e >> i) & Uint64.one,
        );
      }
    }
    return res;
  }

  Secp256k1Fr powVartime(List<Uint64> by) {
    var res = Secp256k1Fr.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) res = res * this;
      }
    }
    return res;
  }

  @override
  Secp256k1Fr? invert() {
    if (isZero()) return null;
    const exp = [
      Uint64.unsafe(3218235020, 3493216575),
      Uint64.unsafe(3132021990, 2940772411),
      Uint64.unsafe(4294967295, 4294967294),
      Uint64.unsafe(4294967295, 4294967295),
    ];
    return pow(exp);
  }

  @override
  FieldSqrtResult<Secp256k1Fr> sqrt() {
    const tm1d2 = [
      Uint64.unsafe(2004853949, 429943938),
      Uint64.unsafe(4252327353, 3445526848),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(33554431, 4294967295),
    ];
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powVartime(tm1d2),
      rootOfUnity: Secp256k1Fr.unsafe([
        Uint64.unsafe(3894670777, 1314617295),
        Uint64.unsafe(3401084808, 3973704682),
        Uint64.unsafe(3554230181, 677539855),
        Uint64.unsafe(3593489695, 1467935422),
      ]),
      s: Secp256k1FrConst.s,
      one: Secp256k1Fr.r,
      conditionalSelect: (a, b, c) => Secp256k1Fr.conditionalSelect(a, b, c),
    );
  }
}

class Secp256r1Fp extends WeierstrassField<Secp256r1Fp> with Equality {
  final List<Uint64> limbs;
  const Secp256r1Fp.unsafe(this.limbs);
  Secp256r1Fp(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "Secp256r1Fp").immutable;
  @override
  List<dynamic> get variables => limbs;
  static const Secp256r1Fp zero = Secp256r1Fp.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const Secp256r1Fp one = r;
  static const Secp256r1Fp r = Secp256r1Fp.unsafe([
    Uint64.unsafe(0, 1),
    Uint64.unsafe(4294967295, 0),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(0, 4294967294),
  ]);
  static const Secp256r1Fp r2 = Secp256r1Fp.unsafe([
    Uint64.unsafe(0, 3),
    Uint64.unsafe(4294967291, 4294967295),
    Uint64.unsafe(4294967295, 4294967294),
    Uint64.unsafe(4, 4294967293),
  ]);

  static const Secp256r1Fp r3 = Secp256r1Fp.unsafe([
    Uint64.unsafe(4294967293, 10),
    Uint64.unsafe(4294967277, 4294967287),
    Uint64.unsafe(5, 4294967292),
    Uint64.unsafe(24, 1),
  ]);
  factory Secp256r1Fp.from(Uint64 v) => Secp256r1Fp([
    v,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]).mul(Secp256r1Fp.r2);
  factory Secp256r1Fp.fromRaw(List<Uint64> v) =>
      Secp256r1Fp(v).mul(Secp256r1Fp.r2);
  factory Secp256r1Fp._fromU512(List<Uint64> l) {
    final d0 = Secp256r1Fp([l[0], l[1], l[2], l[3]]);
    final d1 = Secp256r1Fp([l[4], l[5], l[6], l[7]]);
    return d0 * Secp256r1Fp.r2 + d1 * Secp256r1Fp.r3;
  }
  factory Secp256r1Fp.conditionalSelect(Secp256r1Fp a, Secp256r1Fp b, bool c) =>
      Secp256r1Fp([
        Uint64.ctSelect(a.limbs[0], b.limbs[0], c),
        Uint64.ctSelect(a.limbs[1], b.limbs[1], c),
        Uint64.ctSelect(a.limbs[2], b.limbs[2], c),
        Uint64.ctSelect(a.limbs[3], b.limbs[3], c),
      ]);

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so the whole select is straight-line limb arithmetic.
  factory Secp256r1Fp.conditionalSelectMask(
    Secp256r1Fp a,
    Secp256r1Fp b,
    Uint64 bit,
  ) => Secp256r1Fp([
    Uint64.selectBit(a.limbs[0], b.limbs[0], bit),
    Uint64.selectBit(a.limbs[1], b.limbs[1], bit),
    Uint64.selectBit(a.limbs[2], b.limbs[2], bit),
    Uint64.selectBit(a.limbs[3], b.limbs[3], bit),
  ]);
  factory Secp256r1Fp.fromBytes(List<int> b, {Endian endian = Endian.big}) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    final t = Secp256r1Fp(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
    var bm = Uint64.zero;
    var tp = Uint64.sbb(t.limbs[0], Secp256r1FpConst.modulusLimbs[0], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[1], Secp256r1FpConst.modulusLimbs[1], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[2], Secp256r1FpConst.modulusLimbs[2], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[3], Secp256r1FpConst.modulusLimbs[3], bm);
    bm = tp.$2;
    final r = t * Secp256r1Fp.r2;
    if ((bm & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid encoding.",
      );
    }
    return r;
  }
  factory Secp256r1Fp.fromBytesUnchecked(
    List<int> b, {
    Endian endian = Endian.big,
  }) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    return Secp256r1Fp.fromRaw(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256r1Fp.fromBytes64(List<int> b) {
    if (b.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid length.",
      );
    }
    return Secp256r1Fp._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256r1Fp.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * Secp256r1FpConst.inv;
    var tmp = Uint64.mac(r0, k, Secp256r1FpConst.modulusLimbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, Secp256r1FpConst.modulusLimbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256r1FpConst.modulusLimbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256r1FpConst.modulusLimbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var n4 = Uint64.adc(r4, Uint64.zero, carry);
    r4 = n4.$1;
    var c2 = n4.$2;
    k = r1 * Secp256r1FpConst.inv;
    tmp = Uint64.mac(r1, k, Secp256r1FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256r1FpConst.modulusLimbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256r1FpConst.modulusLimbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256r1FpConst.modulusLimbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var n5 = Uint64.adc(r5, c2, carry);
    r5 = n5.$1;
    c2 = n5.$2;
    k = r2 * Secp256r1FpConst.inv;
    tmp = Uint64.mac(r2, k, Secp256r1FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256r1FpConst.modulusLimbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256r1FpConst.modulusLimbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256r1FpConst.modulusLimbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var n6 = Uint64.adc(r6, c2, carry);
    r6 = n6.$1;
    c2 = n6.$2;
    k = r3 * Secp256r1FpConst.inv;
    tmp = Uint64.mac(r3, k, Secp256r1FpConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256r1FpConst.modulusLimbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256r1FpConst.modulusLimbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, Secp256r1FpConst.modulusLimbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var n7 = Uint64.adc(r7, c2, carry);
    r7 = n7.$1;
    // The pre-reduction value is V = carry3 * 2^256 + (r4, r5, r6, r7).
    // Fixed passes (no early exit): V < 3*2^256 < 5p (carry3 <= 2 and every
    // modulus here exceeds 2^255), so four unconditional passes always fully
    // reduce V, independent of its value. Each pass keeps d = R - p iff
    // V >= p (carry3 != 0 or R >= p) and keeps R otherwise; carry3 tracks
    // the high part in both cases.
    var carry3 = n7.$2;
    var result = [r4, r5, r6, r7];
    for (var k = 0; k < 4; k++) {
      var t = Uint64.sbb(
        result[0],
        Secp256r1FpConst.modulusLimbs[0],
        Uint64.zero,
      );
      final d0 = t.$1;
      var b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[1], Secp256r1FpConst.modulusLimbs[1], b);
      final d1 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[2], Secp256r1FpConst.modulusLimbs[2], b);
      final d2 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[3], Secp256r1FpConst.modulusLimbs[3], b);
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
    return Secp256r1Fp(result);
  }
  Secp256r1Fp subMod() {
    var t = Uint64.sbb(limbs[0], Secp256r1FpConst.modulusLimbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], Secp256r1FpConst.modulusLimbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], Secp256r1FpConst.modulusLimbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], Secp256r1FpConst.modulusLimbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    // Keep d iff no borrow (limbs >= mod), else keep limbs — mask blend,
    // no early return.
    final d = Secp256r1Fp([d0, d1, d2, d3]);
    return Secp256r1Fp.conditionalSelectMask(this, d, (~b) & Uint64.one);
  }

  @override
  BuBytes toBytes({Endian endian = Endian.big}) {
    final t = Secp256r1Fp.montgomeryReduce(
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
  bool isZero() => this == Secp256r1Fp.zero;
  Secp256r1Fp sub(Secp256r1Fp rhs) {
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
    var a = Uint64.adc(d0, Secp256r1FpConst.modulusLimbs[0] & b, Uint64.zero);
    d0 = a.$1;
    var c = a.$2;
    a = Uint64.adc(d1, Secp256r1FpConst.modulusLimbs[1] & b, c);
    d1 = a.$1;
    c = a.$2;
    a = Uint64.adc(d2, Secp256r1FpConst.modulusLimbs[2] & b, c);
    d2 = a.$1;
    c = a.$2;
    a = Uint64.adc(d3, Secp256r1FpConst.modulusLimbs[3] & b, c);
    d3 = a.$1;
    return Secp256r1Fp([d0, d1, d2, d3]);
  }

  Secp256r1Fp add(Secp256r1Fp rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 c = t.$2;
    t = Uint64.adc(limbs[1], rhs.limbs[1], c);
    Uint64 d1 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[2], rhs.limbs[2], c);
    Uint64 d2 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[3], rhs.limbs[3], c);
    Uint64 d3 = t.$1;
    Uint64 carry = t.$2;
    // Branch-free Montgomery correction: add r iff carry != 0.
    final m = Uint64.zero - carry;
    var u = Uint64.adc(d0, r.limbs[0] & m, Uint64.zero);
    d0 = u.$1;
    var cc = u.$2;
    u = Uint64.adc(d1, r.limbs[1] & m, cc);
    d1 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d2, r.limbs[2] & m, cc);
    d2 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d3, r.limbs[3] & m, cc);
    d3 = u.$1;
    return Secp256r1Fp([d0, d1, d2, d3]).subMod();
  }

  Secp256r1Fp neg() {
    var t = Uint64.sbb(Secp256r1FpConst.modulusLimbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(Secp256r1FpConst.modulusLimbs[1], limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256r1FpConst.modulusLimbs[2], limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256r1FpConst.modulusLimbs[3], limbs[3], b);
    Uint64 d3 = t.$1;
    final m = ~Uint64.isZeroMask(limbs[0] | limbs[1] | limbs[2] | limbs[3]);
    return Secp256r1Fp([d0 & m, d1 & m, d2 & m, d3 & m]);
  }

  Secp256r1Fp mul(Secp256r1Fp rhs) {
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
    return Secp256r1Fp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256r1Fp square() {
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
    return Secp256r1Fp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256r1Fp operator +(Secp256r1Fp o) => add(o);
  @override
  Secp256r1Fp operator -(Secp256r1Fp o) => sub(o);
  @override
  Secp256r1Fp operator *(Secp256r1Fp o) => mul(o);
  @override
  Secp256r1Fp operator -() => neg();
  @override
  Secp256r1Fp double() => add(this);
  @override
  bool operator ==(Object other) =>
      other is Secp256r1Fp && Uint64.ctEquals(limbs, other.limbs);
  @override
  int get hashCode => Object.hashAll(limbs);
  Secp256r1Fp pow(List<Uint64> by) {
    var res = Secp256r1Fp.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        final tmp = res * this;
        res = Secp256r1Fp.conditionalSelectMask(
          res,
          tmp,
          (e >> i) & Uint64.one,
        );
      }
    }
    return res;
  }

  Secp256r1Fp powVartime(List<Uint64> by) {
    var res = Secp256r1Fp.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) res = res * this;
      }
    }
    return res;
  }

  @override
  Secp256r1Fp? invert() {
    if (isZero()) return null;
    const exp = [
      Uint64.unsafe(4294967295, 4294967293),
      Uint64.unsafe(0, 4294967295),
      Uint64.unsafe(0, 0),
      Uint64.unsafe(4294967295, 1),
    ];
    return pow(exp);
  }

  @override
  FieldSqrtResult<Secp256r1Fp> sqrt() {
    const exp = [
      Uint64.unsafe(0, 0),
      Uint64.unsafe(0, 1073741824),
      Uint64.unsafe(1073741824, 0),
      Uint64.unsafe(1073741823, 3221225472),
    ];
    final c = powVartime(exp);
    return FieldSqrtResult(c, (c * c) == this);
  }
}

class Secp256r1Fr extends WeierstrassScalar<Secp256r1Fr> with Equality {
  final List<Uint64> limbs;
  const Secp256r1Fr.unsafe(this.limbs);
  Secp256r1Fr(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "Secp256r1Fr").immutable;
  @override
  List<dynamic> get variables => limbs;
  static const Secp256r1Fr zero = Secp256r1Fr.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const Secp256r1Fr one = r;
  static const Secp256r1Fr r = Secp256r1Fr.unsafe([
    Uint64.unsafe(205927741, 60611247),
    Uint64.unsafe(1125713234, 1491624315),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(0, 4294967295),
  ]);
  static const Secp256r1Fr r2 = Secp256r1Fr.unsafe([
    Uint64.unsafe(2200194197, 3195661986),
    Uint64.unsafe(1184463260, 1237151654),
    Uint64.unsafe(675656249, 728493145),
    Uint64.unsafe(1726033300, 4091106848),
  ]);

  static const Secp256r1Fr r3 = Secp256r1Fr.unsafe([
    Uint64.unsafe(2895036105, 191211044),
    Uint64.unsafe(287254702, 201676233),
    Uint64.unsafe(625195300, 1806035263),
    Uint64.unsafe(1346000103, 1678229093),
  ]);
  factory Secp256r1Fr.from(Uint64 v) => Secp256r1Fr([
    v,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]).mul(Secp256r1Fr.r2);
  factory Secp256r1Fr.fromRaw(List<Uint64> v) =>
      Secp256r1Fr(v).mul(Secp256r1Fr.r2);
  factory Secp256r1Fr._fromU512(List<Uint64> l) {
    final d0 = Secp256r1Fr([l[0], l[1], l[2], l[3]]);
    final d1 = Secp256r1Fr([l[4], l[5], l[6], l[7]]);
    return d0 * Secp256r1Fr.r2 + d1 * Secp256r1Fr.r3;
  }
  factory Secp256r1Fr.conditionalSelect(Secp256r1Fr a, Secp256r1Fr b, bool c) =>
      Secp256r1Fr([
        Uint64.ctSelect(a.limbs[0], b.limbs[0], c),
        Uint64.ctSelect(a.limbs[1], b.limbs[1], c),
        Uint64.ctSelect(a.limbs[2], b.limbs[2], c),
        Uint64.ctSelect(a.limbs[3], b.limbs[3], c),
      ]);

  /// Mask form of [conditionalSelect]: [bit] is a 0/1 [Uint64] (never a
  /// `bool`), so the whole select is straight-line limb arithmetic.
  factory Secp256r1Fr.conditionalSelectMask(
    Secp256r1Fr a,
    Secp256r1Fr b,
    Uint64 bit,
  ) => Secp256r1Fr([
    Uint64.selectBit(a.limbs[0], b.limbs[0], bit),
    Uint64.selectBit(a.limbs[1], b.limbs[1], bit),
    Uint64.selectBit(a.limbs[2], b.limbs[2], bit),
    Uint64.selectBit(a.limbs[3], b.limbs[3], bit),
  ]);
  factory Secp256r1Fr.fromBytes(List<int> b, {Endian endian = Endian.big}) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    final t = Secp256r1Fr(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
    var bm = Uint64.zero;
    var tp = Uint64.sbb(t.limbs[0], Secp256r1FrConst.modulusLimbs[0], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[1], Secp256r1FrConst.modulusLimbs[1], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[2], Secp256r1FrConst.modulusLimbs[2], bm);
    bm = tp.$2;
    tp = Uint64.sbb(t.limbs[3], Secp256r1FrConst.modulusLimbs[3], bm);
    bm = tp.$2;
    final r = t * Secp256r1Fr.r2;
    if ((bm & Uint64.one) != Uint64.one) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid encoding.",
      );
    }
    return r;
  }
  factory Secp256r1Fr.fromBytesUnchecked(
    List<int> b, {
    Endian endian = Endian.big,
  }) {
    if (b.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid length.",
      );
    }
    return Secp256r1Fr.fromRaw(
      List.generate(
        4,
        (i) =>
            endian == Endian.big
                ? Uint64.fromBytes(b, endian: Endian.big, offset: (3 - i) * 8)
                : Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256r1Fr.fromBytes64(List<int> b) {
    if (b.length != 64) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid length.",
      );
    }
    return Secp256r1Fr._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(b, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory Secp256r1Fr.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * Secp256r1FrConst.inv;
    var tmp = Uint64.mac(r0, k, Secp256r1FrConst.modulusLimbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, Secp256r1FrConst.modulusLimbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256r1FrConst.modulusLimbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256r1FrConst.modulusLimbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var n4 = Uint64.adc(r4, Uint64.zero, carry);
    r4 = n4.$1;
    var c2 = n4.$2;
    k = r1 * Secp256r1FrConst.inv;
    tmp = Uint64.mac(r1, k, Secp256r1FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, Secp256r1FrConst.modulusLimbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256r1FrConst.modulusLimbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256r1FrConst.modulusLimbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var n5 = Uint64.adc(r5, c2, carry);
    r5 = n5.$1;
    c2 = n5.$2;
    k = r2 * Secp256r1FrConst.inv;
    tmp = Uint64.mac(r2, k, Secp256r1FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, Secp256r1FrConst.modulusLimbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256r1FrConst.modulusLimbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256r1FrConst.modulusLimbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var n6 = Uint64.adc(r6, c2, carry);
    r6 = n6.$1;
    c2 = n6.$2;
    k = r3 * Secp256r1FrConst.inv;
    tmp = Uint64.mac(r3, k, Secp256r1FrConst.modulusLimbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, Secp256r1FrConst.modulusLimbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, Secp256r1FrConst.modulusLimbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, Secp256r1FrConst.modulusLimbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var n7 = Uint64.adc(r7, c2, carry);
    r7 = n7.$1;
    // The pre-reduction value is V = carry3 * 2^256 + (r4, r5, r6, r7).
    // Fixed passes (no early exit): V < 3*2^256 < 5p (carry3 <= 2 and every
    // modulus here exceeds 2^255), so four unconditional passes always fully
    // reduce V, independent of its value. Each pass keeps d = R - p iff
    // V >= p (carry3 != 0 or R >= p) and keeps R otherwise; carry3 tracks
    // the high part in both cases.
    var carry3 = n7.$2;
    var result = [r4, r5, r6, r7];
    for (var k = 0; k < 4; k++) {
      var t = Uint64.sbb(
        result[0],
        Secp256r1FrConst.modulusLimbs[0],
        Uint64.zero,
      );
      final d0 = t.$1;
      var b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[1], Secp256r1FrConst.modulusLimbs[1], b);
      final d1 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[2], Secp256r1FrConst.modulusLimbs[2], b);
      final d2 = t.$1;
      b = t.$2 & Uint64.one;
      t = Uint64.sbb(result[3], Secp256r1FrConst.modulusLimbs[3], b);
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
    return Secp256r1Fr(result);
  }
  Secp256r1Fr subMod() {
    var t = Uint64.sbb(limbs[0], Secp256r1FrConst.modulusLimbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(limbs[1], Secp256r1FrConst.modulusLimbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[2], Secp256r1FrConst.modulusLimbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(limbs[3], Secp256r1FrConst.modulusLimbs[3], b);
    Uint64 d3 = t.$1;
    b = t.$2;
    // Keep d iff no borrow (limbs >= mod), else keep limbs — mask blend,
    // no early return.
    final d = Secp256r1Fr([d0, d1, d2, d3]);
    return Secp256r1Fr.conditionalSelectMask(this, d, (~b) & Uint64.one);
  }

  @override
  BuBytes toBytes({Endian endian = Endian.big}) {
    final t = Secp256r1Fr.montgomeryReduce(
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
  bool isZero() => this == Secp256r1Fr.zero;
  Secp256r1Fr sub(Secp256r1Fr rhs) {
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
    var a = Uint64.adc(d0, Secp256r1FrConst.modulusLimbs[0] & b, Uint64.zero);
    d0 = a.$1;
    var c = a.$2;
    a = Uint64.adc(d1, Secp256r1FrConst.modulusLimbs[1] & b, c);
    d1 = a.$1;
    c = a.$2;
    a = Uint64.adc(d2, Secp256r1FrConst.modulusLimbs[2] & b, c);
    d2 = a.$1;
    c = a.$2;
    a = Uint64.adc(d3, Secp256r1FrConst.modulusLimbs[3] & b, c);
    d3 = a.$1;
    return Secp256r1Fr([d0, d1, d2, d3]);
  }

  Secp256r1Fr add(Secp256r1Fr rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 c = t.$2;
    t = Uint64.adc(limbs[1], rhs.limbs[1], c);
    Uint64 d1 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[2], rhs.limbs[2], c);
    Uint64 d2 = t.$1;
    c = t.$2;
    t = Uint64.adc(limbs[3], rhs.limbs[3], c);
    Uint64 d3 = t.$1;
    Uint64 carry = t.$2;
    // Branch-free Montgomery correction: add r iff carry != 0.
    final m = Uint64.zero - carry;
    var u = Uint64.adc(d0, r.limbs[0] & m, Uint64.zero);
    d0 = u.$1;
    var cc = u.$2;
    u = Uint64.adc(d1, r.limbs[1] & m, cc);
    d1 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d2, r.limbs[2] & m, cc);
    d2 = u.$1;
    cc = u.$2;
    u = Uint64.adc(d3, r.limbs[3] & m, cc);
    d3 = u.$1;
    return Secp256r1Fr([d0, d1, d2, d3]).subMod();
  }

  Secp256r1Fr neg() {
    var t = Uint64.sbb(Secp256r1FrConst.modulusLimbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 b = t.$2;
    t = Uint64.sbb(Secp256r1FrConst.modulusLimbs[1], limbs[1], b);
    Uint64 d1 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256r1FrConst.modulusLimbs[2], limbs[2], b);
    Uint64 d2 = t.$1;
    b = t.$2;
    t = Uint64.sbb(Secp256r1FrConst.modulusLimbs[3], limbs[3], b);
    Uint64 d3 = t.$1;
    final m = ~Uint64.isZeroMask(limbs[0] | limbs[1] | limbs[2] | limbs[3]);
    return Secp256r1Fr([d0 & m, d1 & m, d2 & m, d3 & m]);
  }

  Secp256r1Fr mul(Secp256r1Fr rhs) {
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
    return Secp256r1Fr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256r1Fr square() {
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
    return Secp256r1Fr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  Secp256r1Fr operator +(Secp256r1Fr o) => add(o);
  @override
  Secp256r1Fr operator -(Secp256r1Fr o) => sub(o);
  @override
  Secp256r1Fr operator *(Secp256r1Fr o) => mul(o);
  @override
  Secp256r1Fr operator -() => neg();
  @override
  Secp256r1Fr double() => add(this);
  @override
  bool operator ==(Object other) =>
      other is Secp256r1Fr && Uint64.ctEquals(limbs, other.limbs);
  @override
  int get hashCode => Object.hashAll(limbs);
  Secp256r1Fr pow(List<Uint64> by) {
    var res = Secp256r1Fr.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        final tmp = res * this;
        res = Secp256r1Fr.conditionalSelectMask(
          res,
          tmp,
          (e >> i) & Uint64.one,
        );
      }
    }
    return res;
  }

  Secp256r1Fr powVartime(List<Uint64> by) {
    var res = Secp256r1Fr.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) res = res * this;
      }
    }
    return res;
  }

  @override
  Secp256r1Fr? invert() {
    if (isZero()) return null;
    const exp = [
      Uint64.unsafe(4089039554, 4234356047),
      Uint64.unsafe(3169254061, 2803342980),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(4294967295, 0),
    ];
    return pow(exp);
  }

  @override
  FieldSqrtResult<Secp256r1Fr> sqrt() {
    const tm1d2 = [
      Uint64.unsafe(664653398, 400759082),
      Uint64.unsafe(4259788757, 1832434932),
      Uint64.unsafe(134217727, 4294967295),
      Uint64.unsafe(134217727, 4160749568),
    ];
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powVartime(tm1d2),
      rootOfUnity: Secp256r1Fr.unsafe([
        Uint64.unsafe(269840527, 2117504993),
        Uint64.unsafe(835110213, 1858880785),
        Uint64.unsafe(1384251017, 2560728737),
        Uint64.unsafe(41486494, 281427944),
      ]),
      s: Secp256r1FrConst.s,
      one: Secp256r1Fr.r,
      conditionalSelect: (a, b, c) => Secp256r1Fr.conditionalSelect(a, b, c),
    );
  }
}

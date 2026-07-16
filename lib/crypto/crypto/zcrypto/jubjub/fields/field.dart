import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/constants/constants.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

abstract class JubJubPrimeField<F extends JubJubPrimeField<F>>
    extends CryptoField<F> {
  const JubJubPrimeField();
  List<int> toBytes();
  List<bool> toBits() {
    final toBytes = this.toBytes();
    final tmpLimbs = List<BigInt>.generate(4, (i) {
      return BigintUtils.fromBytes(
        toBytes.sublist(i * 8, (i * 8) + 8),
        byteOrder: Endian.little,
      );
    });
    return tmpLimbs
        .map((e) => BigintUtils.toBinaryBool(e, bitLength: 64))
        .expand((e) => e)
        .toList();
  }

  List<bool> charBits();
}

abstract class JubJubField<F extends JubJubField<F>>
    extends JubJubPrimeField<F> {
  const JubJubField();
  @override
  List<bool> charBits() {
    return BigintUtils.toBinaryBool(JubJubNativeConst.qJ, bitLength: 256);
  }
}

abstract class JubJubScalar<F extends JubJubScalar<F>>
    extends JubJubPrimeField<F> {
  const JubJubScalar();
  @override
  List<bool> charBits() {
    return BigintUtils.toBinaryBool(JubJubNativeConst.rJ, bitLength: 256);
  }
}

/// Element of the JubJub scalar field Fr, internally represented as 4
/// 64-bit limbs (Uint64, not BigInt) in Montgomery form.
class JubJubFr extends JubJubScalar<JubJubFr> {
  final List<Uint64> limbs;
  const JubJubFr.unsafe(this.limbs);
  JubJubFr(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "JubJubFr").immutable;

  factory JubJubFr.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * JubJubFrConst.inv;
    var t = Uint64.mac(r0, k, JubJubFrConst.modulus.limbs[0], Uint64.zero);
    Uint64 carry = t.$2;
    t = Uint64.mac(r1, k, JubJubFrConst.modulus.limbs[1], carry);
    r1 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r2, k, JubJubFrConst.modulus.limbs[2], carry);
    r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r3, k, JubJubFrConst.modulus.limbs[3], carry);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.adc(r4, Uint64.zero, carry);
    r4 = t.$1;
    Uint64 carry2 = t.$2;

    // --- 2nd iteration --------------------------------------------------------
    k = r1 * JubJubFrConst.inv;

    t = Uint64.mac(r1, k, JubJubFrConst.modulus.limbs[0], Uint64.zero);
    carry = t.$2;

    t = Uint64.mac(r2, k, JubJubFrConst.modulus.limbs[1], carry);
    r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r3, k, JubJubFrConst.modulus.limbs[2], carry);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, k, JubJubFrConst.modulus.limbs[3], carry);
    r4 = t.$1;
    carry = t.$2;

    t = Uint64.adc(r5, carry2, carry);
    r5 = t.$1;
    carry2 = t.$2;

    // --- 3rd iteration --------------------------------------------------------
    k = r2 * JubJubFrConst.inv;

    t = Uint64.mac(r2, k, JubJubFrConst.modulus.limbs[0], Uint64.zero);
    carry = t.$2;

    t = Uint64.mac(r3, k, JubJubFrConst.modulus.limbs[1], carry);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, k, JubJubFrConst.modulus.limbs[2], carry);
    r4 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r5, k, JubJubFrConst.modulus.limbs[3], carry);
    r5 = t.$1;
    carry = t.$2;

    t = Uint64.adc(r6, carry2, carry);
    r6 = t.$1;
    carry2 = t.$2;

    // --- 4th iteration --------------------------------------------------------
    k = r3 * JubJubFrConst.inv;

    t = Uint64.mac(r3, k, JubJubFrConst.modulus.limbs[0], Uint64.zero);
    carry = t.$2;

    t = Uint64.mac(r4, k, JubJubFrConst.modulus.limbs[1], carry);
    r4 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r5, k, JubJubFrConst.modulus.limbs[2], carry);
    r5 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r6, k, JubJubFrConst.modulus.limbs[3], carry);
    r6 = t.$1;
    carry = t.$2;

    t = Uint64.adc(r7, carry2, carry);
    r7 = t.$1;
    return JubJubFr([r4, r5, r6, r7]).sub(JubJubFrConst.modulus);
  }

  factory JubJubFr.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 32,
      operation: "fromBytes",
      reason: "Invalid field bytes length.",
    );
    final tmp = JubJubFr(
      List.generate(
        4,
        (i) => Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8),
      ),
    );
    Uint64 borrowMask = Uint64.zero;
    var temp = Uint64.sbb(
      tmp.limbs[0],
      JubJubFrConst.modulus.limbs[0],
      borrowMask,
    );
    borrowMask = temp.$2;
    temp = Uint64.sbb(tmp.limbs[1], JubJubFrConst.modulus.limbs[1], borrowMask);
    borrowMask = temp.$2;
    temp = Uint64.sbb(tmp.limbs[2], JubJubFrConst.modulus.limbs[2], borrowMask);
    borrowMask = temp.$2;
    temp = Uint64.sbb(tmp.limbs[3], JubJubFrConst.modulus.limbs[3], borrowMask);
    borrowMask = temp.$2;
    final result = tmp * JubJubFr.r2;
    if ((borrowMask & Uint64.one) != Uint64.one) {
      throw ArgumentException.invalidOperationArguments(
        "JubJubFr",
        reason: "Invalid point encoding bytes.",
      );
    }
    return result;
  }

  factory JubJubFr._fromU512(List<Uint64> limbs) {
    assert(limbs.length == 8);
    JubJubFr d0 = JubJubFr([limbs[0], limbs[1], limbs[2], limbs[3]]);
    JubJubFr d1 = JubJubFr([limbs[4], limbs[5], limbs[6], limbs[7]]);
    return d0 * JubJubFr.r2 + d1 * JubJubFr.r3;
  }

  factory JubJubFr.fromBytes64(List<int> bytes) {
    return JubJubFr._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8),
      ),
    );
  }

  factory JubJubFr.from(Uint64 val) {
    return JubJubFr([
      val,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    ]).mul(JubJubFr.r2);
  }

  factory JubJubFr.fromRaw(List<Uint64> val) {
    if (val.length != 4) {
      throw ArgumentException.invalidOperationArguments(
        "fromRaw",
        reason: "Invalid limbs length.",
      );
    }
    return JubJubFr(val).mul(JubJubFr.r2);
  }

  static const JubJubFr zero = JubJubFr.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const JubJubFr one = JubJubFr.r;

  static const JubJubFr r = JubJubFr.unsafe([
    Uint64.unsafe(637012915, 3113617369),
    Uint64.unsafe(4078294575, 1723262800),
    Uint64.unsafe(2468680942, 3951564020),
    Uint64.unsafe(161938543, 1200707014),
  ]);
  static const JubJubFr r3 = JubJubFr.unsafe([
    Uint64.unsafe(3772171862, 1031996740),
    Uint64.unsafe(842938499, 1502416773),
    Uint64.unsafe(4043219712, 1278094248),
    Uint64.unsafe(92753796, 2489792492),
  ]);
  static const JubJubFr twoInv = JubJubFr.unsafe([
    Uint64.unsafe(2068286729, 1212586568),
    Uint64.unsafe(3435068257, 2579463145),
    Uint64.unsafe(3435538423, 4133365754),
    Uint64.unsafe(202528940, 3596780215),
  ]);
  static const JubJubFr generator = JubJubFr.unsafe([
    Uint64.unsafe(1913330457, 3567167729),
    Uint64.unsafe(3209339745, 32586328),
    Uint64.unsafe(1604897942, 2173947067),
    Uint64.unsafe(242273244, 2110583724),
  ]);
  static const JubJubFr rootOfUnity = JubJubFr.unsafe([
    Uint64.unsafe(2862547627, 492905694),
    Uint64.unsafe(3008514660, 1712400690),
    Uint64.unsafe(1933714962, 363603467),
    Uint64.unsafe(81180795, 497179106),
  ]);
  static const JubJubFr rootOfUnityInv = JubJubFr.rootOfUnity;
  static const JubJubFr delta = JubJubFr.unsafe([
    Uint64.unsafe(2572114624, 3370391059),
    Uint64.unsafe(1001861475, 197069700),
    Uint64.unsafe(502310018, 57779555),
    Uint64.unsafe(238042774, 4174071741),
  ]);
  static const JubJubFr r2 = JubJubFr.unsafe([
    Uint64.unsafe(1735498404, 2514843441),
    Uint64.unsafe(1370541808, 2632186918),
    Uint64.unsafe(1775941626, 3223775653),
    Uint64.unsafe(83252347, 2366797448),
  ]);

  @override
  JubJubFr square() {
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

    // Double the cross products
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
    return JubJubFr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  JubJubFr sub(JubJubFr rhs) {
    final x0 = limbs[0], x1 = limbs[1], x2 = limbs[2], x3 = limbs[3];
    final y0 = rhs.limbs[0],
        y1 = rhs.limbs[1],
        y2 = rhs.limbs[2],
        y3 = rhs.limbs[3];

    var t = Uint64.sbb(x0, y0, Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 borrow = t.$2;

    t = Uint64.sbb(x1, y1, borrow);
    Uint64 d1 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(x2, y2, borrow);
    Uint64 d2 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(x3, y3, borrow);
    Uint64 d3 = t.$1;
    borrow = t.$2;

    t = Uint64.adc(d0, JubJubFrConst.modulus.limbs[0] & borrow, Uint64.zero);
    d0 = t.$1;
    Uint64 carry = t.$2;

    t = Uint64.adc(d1, JubJubFrConst.modulus.limbs[1] & borrow, carry);
    d1 = t.$1;
    carry = t.$2;

    t = Uint64.adc(d2, JubJubFrConst.modulus.limbs[2] & borrow, carry);
    d2 = t.$1;
    carry = t.$2;

    t = Uint64.adc(d3, JubJubFrConst.modulus.limbs[3] & borrow, carry);
    d3 = t.$1;

    return JubJubFr([d0, d1, d2, d3]);
  }

  JubJubFr mul(JubJubFr rhs) {
    final x0 = limbs[0], x1 = limbs[1], x2 = limbs[2], x3 = limbs[3];
    final y0 = rhs.limbs[0],
        y1 = rhs.limbs[1],
        y2 = rhs.limbs[2],
        y3 = rhs.limbs[3];

    var t = Uint64.mac(Uint64.zero, x0, y0, Uint64.zero);
    Uint64 r0 = t.$1;
    Uint64 carry = t.$2;

    t = Uint64.mac(Uint64.zero, x0, y1, carry);
    Uint64 r1 = t.$1;
    carry = t.$2;

    t = Uint64.mac(Uint64.zero, x0, y2, carry);
    Uint64 r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(Uint64.zero, x0, y3, carry);
    Uint64 r3 = t.$1;
    Uint64 r4 = t.$2;

    t = Uint64.mac(r1, x1, y0, Uint64.zero);
    r1 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r2, x1, y1, carry);
    r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r3, x1, y2, carry);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, x1, y3, carry);
    r4 = t.$1;
    Uint64 r5 = t.$2;

    t = Uint64.mac(r2, x2, y0, Uint64.zero);
    r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r3, x2, y1, carry);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, x2, y2, carry);
    r4 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r5, x2, y3, carry);
    r5 = t.$1;
    Uint64 r6 = t.$2;

    t = Uint64.mac(r3, x3, y0, Uint64.zero);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, x3, y1, carry);
    r4 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r5, x3, y2, carry);
    r5 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r6, x3, y3, carry);
    r6 = t.$1;
    Uint64 r7 = t.$2;
    return JubJubFr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  JubJubFr add(JubJubFr rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 carry = t.$2;

    t = Uint64.adc(limbs[1], rhs.limbs[1], carry);
    Uint64 d1 = t.$1;
    carry = t.$2;

    t = Uint64.adc(limbs[2], rhs.limbs[2], carry);
    Uint64 d2 = t.$1;
    carry = t.$2;

    t = Uint64.adc(limbs[3], rhs.limbs[3], carry);
    Uint64 d3 = t.$1;
    return JubJubFr([d0, d1, d2, d3]).sub(JubJubFrConst.modulus);
  }

  JubJubFr neg() {
    var t = Uint64.sbb(JubJubFrConst.modulus.limbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 borrow = t.$2;

    t = Uint64.sbb(JubJubFrConst.modulus.limbs[1], limbs[1], borrow);
    Uint64 d1 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(JubJubFrConst.modulus.limbs[2], limbs[2], borrow);
    Uint64 d2 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(JubJubFrConst.modulus.limbs[3], limbs[3], borrow);
    Uint64 d3 = t.$1;

    final oRed = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    final mask = oRed.isZero ? Uint64.zero : Uint64.max;
    return JubJubFr([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  @override
  JubJubFr? invert() {
    JubJubFr squareAssignMulti(JubJubFr n, int numTimes) {
      for (int i = 0; i < numTimes; i++) {
        n = n.square();
      }
      return n;
    }

    JubJubFr t1 = square();
    JubJubFr t0 = t1.square();
    JubJubFr t3 = t0 * t1;
    JubJubFr t6 = t3 * this;
    JubJubFr t7 = t6 * t1;
    JubJubFr t12 = t7 * t3;
    JubJubFr t13 = t12 * t0;
    JubJubFr t16 = t12 * t3;
    JubJubFr t2 = t13 * t3;
    JubJubFr t15 = t16 * t3;
    JubJubFr t19 = t2 * t0;
    JubJubFr t9 = t15 * t3;
    JubJubFr t18 = t9 * t3;
    JubJubFr t14 = t18 * t1;
    JubJubFr t4 = t18 * t0;
    JubJubFr t8 = t18 * t3;
    JubJubFr t17 = t14 * t3;
    JubJubFr t11 = t8 * t3;
    t1 = t17 * t3;
    JubJubFr t5 = t11 * t3;
    t3 = t5 * t0;
    t0 = t5.square();

    t0 = squareAssignMulti(t0, 5) * t3;
    t0 = squareAssignMulti(t0, 6) * t8;
    t0 = squareAssignMulti(t0, 7) * t19;
    t0 = squareAssignMulti(t0, 6) * t13;
    t0 = squareAssignMulti(t0, 8) * t14;
    t0 = squareAssignMulti(t0, 6) * t18;
    t0 = squareAssignMulti(t0, 7) * t17;
    t0 = squareAssignMulti(t0, 5) * t16;
    t0 = squareAssignMulti(t0, 3) * this;
    t0 = squareAssignMulti(t0, 11) * t11;
    t0 = squareAssignMulti(t0, 8) * t5;
    t0 = squareAssignMulti(t0, 5) * t15;
    t0 = squareAssignMulti(t0, 8) * this;
    t0 = squareAssignMulti(t0, 12) * t13;
    t0 = squareAssignMulti(t0, 7) * t9;
    t0 = squareAssignMulti(t0, 5) * t15;
    t0 = squareAssignMulti(t0, 14) * t14;
    t0 = squareAssignMulti(t0, 5) * t13;
    t0 = squareAssignMulti(t0, 2) * this;
    t0 = squareAssignMulti(t0, 6) * this;
    t0 = squareAssignMulti(t0, 9) * t7;
    t0 = squareAssignMulti(t0, 6) * t12;
    t0 = squareAssignMulti(t0, 8) * t11;
    t0 = squareAssignMulti(t0, 3) * this;
    t0 = squareAssignMulti(t0, 12) * t9;
    t0 = squareAssignMulti(t0, 11) * t8;
    t0 = squareAssignMulti(t0, 8) * t7;
    t0 = squareAssignMulti(t0, 4) * t6;
    t0 = squareAssignMulti(t0, 10) * t5;
    t0 = squareAssignMulti(t0, 7) * t3;
    t0 = squareAssignMulti(t0, 6) * t4;
    t0 = squareAssignMulti(t0, 7) * t3;
    t0 = squareAssignMulti(t0, 5) * t2;
    t0 = squareAssignMulti(t0, 6) * t2;
    t0 = squareAssignMulti(t0, 7) * t1;

    if (this == JubJubFr.zero) return null;
    return t0;
  }

  JubJubFr powVartime(List<Uint64> by) {
    JubJubFr res = JubJubFr.one;
    for (Uint64 e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) {
          res = res * this;
        }
      }
    }
    return res;
  }

  JubJubFr pow(List<Uint64> by) {
    JubJubFr res = JubJubFr.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        JubJubFr tmp = res * this;
        final bit = ((e >> i) & Uint64.one) == Uint64.one;
        res = bit ? tmp : res;
      }
    }
    return res;
  }

  @override
  FieldSqrtResult<JubJubFr> sqrt() {
    const m = [
      Uint64.unsafe(3022373783, 3049114414),
      Uint64.unsafe(697960484, 4080141344),
      Uint64.unsafe(1100598976, 1078791872),
      Uint64.unsafe(60779834, 2571955178),
    ];
    final sqrt = powVartime(m);
    return FieldSqrtResult(sqrt, (sqrt * sqrt) == this);
  }

  @override
  bool isZero() => this == JubJubFr.zero;

  FieldSqrtResult<JubJubFr> sqrtRatio(JubJubFr num, JubJubFr div) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: JubJubFr.zero,
      rootOfUnity: JubJubFr.rootOfUnity,
    );
  }

  @override
  JubJubFr double() => add(this);

  @override
  JubJubFr operator +(JubJubFr rhs) => add(rhs);
  @override
  JubJubFr operator -(JubJubFr rhs) => sub(rhs);
  @override
  JubJubFr operator *(JubJubFr rhs) => mul(rhs);
  @override
  JubJubFr operator -() => neg();

  @override
  List<int> toBytes() {
    final tmp = JubJubFr.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );
    final res = Uint8List(32);
    for (int i = 0; i < 4; i++) {
      res.setRange(i * 8, i * 8 + 8, tmp.limbs[i].toBytes(Endian.little));
    }
    return res;
  }

  @override
  bool operator ==(Object other) =>
      other is JubJubFr && Uint64.ctEquals(limbs, other.limbs);

  @override
  int get hashCode => Object.hashAll(limbs);
}

class JubJubFq extends JubJubField<JubJubFq> {
  final List<Uint64> limbs;
  const JubJubFq.unsafe(this.limbs);
  JubJubFq(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "JubJubFq").immutable;
  static const JubJubFq zero = JubJubFq.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static JubJubFq one = JubJubFq.r;

  factory JubJubFq.from(Uint64 val) {
    return JubJubFq([
      val,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    ]).mul(JubJubFq.r2);
  }

  static const JubJubFq edwardsD = JubJubFq.unsafe([
    Uint64.unsafe(710026325, 3111450288),
    Uint64.unsafe(4234988015, 228248243),
    Uint64.unsafe(2047409044, 3262523601),
    Uint64.unsafe(1475933864, 4262340142),
  ]);
  static const edwardsD2 = JubJubFq.unsafe([
    Uint64.unsafe(1420052652, 1927933279),
    Uint64.unsafe(2770071515, 456604007),
    Uint64.unsafe(3235389217, 2068478366),
    Uint64.unsafe(1006913022, 3531525908),
  ]);

  static const rootOfUnityInv = JubJubFq.unsafe([
    Uint64.unsafe(1112950810, 3706921370),
    Uint64.unsafe(1173584767, 2528561875),
    Uint64.unsafe(4190368215, 1601846055),
    Uint64.unsafe(758104137, 1703607619),
  ]);

  static const rootOfUnity = JubJubFq.unsafe([
    Uint64.unsafe(3115683212, 1594771050),
    Uint64.unsafe(1528515712, 404346860),
    Uint64.unsafe(183843555, 1386421860),
    Uint64.unsafe(1542696410, 434745979),
  ]);

  static const twoInv = JubJubFq.unsafe([
    Uint64.unsafe(0, 4294967295),
    Uint64.unsafe(2890030077, 107521),
    Uint64.unsafe(3435538423, 4133365754),
    Uint64.unsafe(202528940, 3596780215),
  ]);

  static const r3 = JubJubFq.unsafe([
    Uint64.unsafe(3324778503, 1134261167),
    Uint64.unsafe(457051416, 2364565904),
    Uint64.unsafe(1943092337, 3350590488),
    Uint64.unsafe(1848269753, 3369808873),
  ]);

  static const r2 = JubJubFq.unsafe([
    Uint64.unsafe(3382307216, 4092763245),
    Uint64.unsafe(728559051, 2274516003),
    Uint64.unsafe(97719446, 1918122383),
    Uint64.unsafe(122214873, 2673475345),
  ]);

  static const r = JubJubFq.unsafe([
    Uint64.unsafe(1, 4294967294),
    Uint64.unsafe(1485092858, 215042),
    Uint64.unsafe(2576109551, 3971764213),
    Uint64.unsafe(405057881, 2898593135),
  ]);

  factory JubJubFq.fromRaw(List<Uint64> val) {
    assert(val.length == 4);
    JubJubFq tmp = JubJubFq(val);
    return tmp.mul(JubJubFq.r2);
  }

  factory JubJubFq._fromU512(List<Uint64> limbs) {
    assert(limbs.length == 8);
    JubJubFq d0 = JubJubFq([limbs[0], limbs[1], limbs[2], limbs[3]]);
    JubJubFq d1 = JubJubFq([limbs[4], limbs[5], limbs[6], limbs[7]]);
    return d0 * JubJubFq.r2 + d1 * JubJubFq.r3;
  }

  factory JubJubFq.conditionalSelect(JubJubFq a, JubJubFq b, bool choice) {
    return JubJubFq([
      Uint64.ctSelect(a.limbs[0], b.limbs[0], choice),
      Uint64.ctSelect(a.limbs[1], b.limbs[1], choice),
      Uint64.ctSelect(a.limbs[2], b.limbs[2], choice),
      Uint64.ctSelect(a.limbs[3], b.limbs[3], choice),
    ]);
  }

  factory JubJubFq.fromBytes64(List<int> bytes) {
    if (bytes.length != 64) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid field encoding bytes length.",
      );
    }
    return JubJubFq._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8),
      ),
    );
  }

  factory JubJubFq.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field encoding bytes length.",
      );
    }
    final tmp = JubJubFq(
      List.generate(
        4,
        (i) => Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8),
      ),
    );

    Uint64 borrowMask = Uint64.zero;
    var temp = Uint64.sbb(
      tmp.limbs[0],
      JubJubFqConst.modulus.limbs[0],
      borrowMask,
    );
    borrowMask = temp.$2;
    temp = Uint64.sbb(tmp.limbs[1], JubJubFqConst.modulus.limbs[1], borrowMask);
    borrowMask = temp.$2;
    temp = Uint64.sbb(tmp.limbs[2], JubJubFqConst.modulus.limbs[2], borrowMask);
    borrowMask = temp.$2;
    temp = Uint64.sbb(tmp.limbs[3], JubJubFqConst.modulus.limbs[3], borrowMask);
    borrowMask = temp.$2;

    final result = tmp * JubJubFq.r2;
    if ((borrowMask & Uint64.one) != Uint64.one) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field encoding bytes.",
      );
    }
    return result;
  }

  factory JubJubFq.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    Uint64 k = r0 * JubJubFqConst.inv;
    var tmp = Uint64.mac(r0, k, JubJubFqConst.modulus.limbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, JubJubFqConst.modulus.limbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, JubJubFqConst.modulus.limbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, JubJubFqConst.modulus.limbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var r4New = Uint64.adc(r4, Uint64.zero, carry);
    r4 = r4New.$1;
    var carry2 = r4New.$2;

    k = r1 * JubJubFqConst.inv;
    tmp = Uint64.mac(r1, k, JubJubFqConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, JubJubFqConst.modulus.limbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, JubJubFqConst.modulus.limbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, JubJubFqConst.modulus.limbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var r5New = Uint64.adc(r5, carry2, carry);
    r5 = r5New.$1;
    carry2 = r5New.$2;

    k = r2 * JubJubFqConst.inv;
    tmp = Uint64.mac(r2, k, JubJubFqConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, JubJubFqConst.modulus.limbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, JubJubFqConst.modulus.limbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, JubJubFqConst.modulus.limbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var r6New = Uint64.adc(r6, carry2, carry);
    r6 = r6New.$1;
    carry2 = r6New.$2;

    k = r3 * JubJubFqConst.inv;
    tmp = Uint64.mac(r3, k, JubJubFqConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, JubJubFqConst.modulus.limbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, JubJubFqConst.modulus.limbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, JubJubFqConst.modulus.limbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var r7New = Uint64.adc(r7, carry2, carry);
    r7 = r7New.$1;

    return JubJubFq([r4, r5, r6, r7]).sub(JubJubFqConst.modulus);
  }

  @override
  JubJubFq operator +(JubJubFq rhs) => add(rhs);
  @override
  JubJubFq operator -(JubJubFq rhs) => sub(rhs);
  @override
  JubJubFq operator *(JubJubFq rhs) => mul(rhs);
  @override
  JubJubFq operator -() => neg();

  @override
  List<int> toBytes() {
    final tmp = JubJubFq.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );
    final res = Uint8List(32);
    for (int i = 0; i < 4; i++) {
      res.setRange(i * 8, i * 8 + 8, tmp.limbs[i].toBytes(Endian.little));
    }
    return res;
  }

  @override
  bool isZero() => this == JubJubFq.zero;

  JubJubFq sub(JubJubFq rhs) {
    var t = Uint64.sbb(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 borrow = t.$2;

    t = Uint64.sbb(limbs[1], rhs.limbs[1], borrow);
    Uint64 d1 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(limbs[2], rhs.limbs[2], borrow);
    Uint64 d2 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(limbs[3], rhs.limbs[3], borrow);
    Uint64 d3 = t.$1;
    borrow = t.$2;

    var a = Uint64.adc(
      d0,
      JubJubFqConst.modulus.limbs[0] & borrow,
      Uint64.zero,
    );
    d0 = a.$1;
    Uint64 carry = a.$2;

    a = Uint64.adc(d1, JubJubFqConst.modulus.limbs[1] & borrow, carry);
    d1 = a.$1;
    carry = a.$2;

    a = Uint64.adc(d2, JubJubFqConst.modulus.limbs[2] & borrow, carry);
    d2 = a.$1;
    carry = a.$2;

    a = Uint64.adc(d3, JubJubFqConst.modulus.limbs[3] & borrow, carry);
    d3 = a.$1;

    return JubJubFq([d0, d1, d2, d3]);
  }

  JubJubFq add(JubJubFq rhs) {
    var t = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 carry = t.$2;

    t = Uint64.adc(limbs[1], rhs.limbs[1], carry);
    Uint64 d1 = t.$1;
    carry = t.$2;

    t = Uint64.adc(limbs[2], rhs.limbs[2], carry);
    Uint64 d2 = t.$1;
    carry = t.$2;

    t = Uint64.adc(limbs[3], rhs.limbs[3], carry);
    Uint64 d3 = t.$1;

    return JubJubFq([d0, d1, d2, d3]).sub(JubJubFqConst.modulus);
  }

  JubJubFq neg() {
    var t = Uint64.sbb(JubJubFqConst.modulus.limbs[0], limbs[0], Uint64.zero);
    Uint64 d0 = t.$1;
    Uint64 borrow = t.$2;

    t = Uint64.sbb(JubJubFqConst.modulus.limbs[1], limbs[1], borrow);
    Uint64 d1 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(JubJubFqConst.modulus.limbs[2], limbs[2], borrow);
    Uint64 d2 = t.$1;
    borrow = t.$2;

    t = Uint64.sbb(JubJubFqConst.modulus.limbs[3], limbs[3], borrow);
    Uint64 d3 = t.$1;

    final zeroCheck = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    final mask = zeroCheck.isZero ? Uint64.zero : Uint64.max;

    return JubJubFq([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  JubJubFq mul(JubJubFq rhs) {
    var t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[0], Uint64.zero);
    Uint64 r0 = t.$1;
    Uint64 carry = t.$2;

    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[1], carry);
    Uint64 r1 = t.$1;
    carry = t.$2;

    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[2], carry);
    Uint64 r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[3], carry);
    Uint64 r3 = t.$1;
    Uint64 r4 = t.$2;

    t = Uint64.mac(r1, limbs[1], rhs.limbs[0], Uint64.zero);
    r1 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r2, limbs[1], rhs.limbs[1], carry);
    r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r3, limbs[1], rhs.limbs[2], carry);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, limbs[1], rhs.limbs[3], carry);
    r4 = t.$1;
    Uint64 r5 = t.$2;

    t = Uint64.mac(r2, limbs[2], rhs.limbs[0], Uint64.zero);
    r2 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r3, limbs[2], rhs.limbs[1], carry);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, limbs[2], rhs.limbs[2], carry);
    r4 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r5, limbs[2], rhs.limbs[3], carry);
    r5 = t.$1;
    Uint64 r6 = t.$2;

    t = Uint64.mac(r3, limbs[3], rhs.limbs[0], Uint64.zero);
    r3 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r4, limbs[3], rhs.limbs[1], carry);
    r4 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r5, limbs[3], rhs.limbs[2], carry);
    r5 = t.$1;
    carry = t.$2;

    t = Uint64.mac(r6, limbs[3], rhs.limbs[3], carry);
    r6 = t.$1;
    Uint64 r7 = t.$2;

    return JubJubFq.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  JubJubFq square() {
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

    return JubJubFq.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  JubJubFq? invert() {
    if (isZero()) return null;
    JubJubFq squareAssignMulti(JubJubFq n, int numTimes) {
      for (int i = 0; i < numTimes; i++) {
        n = n.square();
      }
      return n;
    }

    JubJubFq t0 = square();
    JubJubFq t1 = t0 * this;
    JubJubFq t16 = t0.square();
    JubJubFq t6 = t16.square();
    JubJubFq t5 = t6 * t0;
    t0 = t6 * t16;
    JubJubFq t12 = t5 * t16;
    JubJubFq t2 = t6.square();
    JubJubFq t7 = t5 * t6;
    JubJubFq t15 = t0 * t5;
    JubJubFq t17 = t12.square();
    t1 *= t17;
    JubJubFq t3 = t7 * t2;
    JubJubFq t8 = t1 * t17;
    JubJubFq t4 = t8 * t2;
    JubJubFq t9 = t8 * t7;
    t7 = t4 * t5;
    JubJubFq t11 = t4 * t17;
    t5 = t9 * t17;
    JubJubFq t14 = t7 * t15;
    JubJubFq t13 = t11 * t12;
    t12 = t11 * t17;
    t15 = t15 * t12;
    t16 = t16 * t15;
    t3 = t3 * t16;
    t17 = t17 * t3;
    t0 = t0 * t17;
    t6 = t6 * t0;
    t2 = t2 * t6;

    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t17;
    t0 = squareAssignMulti(t0, 9);
    t0 = t0 * t16;
    t0 = squareAssignMulti(t0, 9);
    t0 = t0 * t15;
    t0 = squareAssignMulti(t0, 9);
    t0 = t0 * t15;
    t0 = squareAssignMulti(t0, 7);
    t0 = t0 * t14;
    t0 = squareAssignMulti(t0, 7);
    t0 = t0 * t13;
    t0 = squareAssignMulti(t0, 10);
    t0 = t0 * t12;
    t0 = squareAssignMulti(t0, 9);
    t0 = t0 * t11;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t8;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * this;
    t0 = squareAssignMulti(t0, 14);
    t0 = t0 * t9;
    t0 = squareAssignMulti(t0, 10);
    t0 = t0 * t8;
    t0 = squareAssignMulti(t0, 15);
    t0 = t0 * t7;
    t0 = squareAssignMulti(t0, 10);
    t0 = t0 * t6;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t5;
    t0 = squareAssignMulti(t0, 16);
    t0 = t0 * t3;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t2;
    t0 = squareAssignMulti(t0, 7);
    t0 = t0 * t4;
    t0 = squareAssignMulti(t0, 9);
    t0 = t0 * t2;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t3;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t2;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t2;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t2;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t3;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t2;
    t0 = squareAssignMulti(t0, 8);
    t0 = t0 * t2;
    t0 = squareAssignMulti(t0, 5);
    t0 = t0 * t1;
    t0 = squareAssignMulti(t0, 5);
    t0 = t0 * t1;

    return t0;
  }

  JubJubFq powVartime(List<Uint64> by) {
    JubJubFq res = JubJubFq.one;
    for (Uint64 e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        if (((e >> i) & Uint64.one) == Uint64.one) {
          res = res * this;
        }
      }
    }
    return res;
  }

  @override
  FieldSqrtResult<JubJubFq> sqrt() {
    const List<Uint64> tm1d2 = [
      Uint64.unsafe(2147429887, 2147483647),
      Uint64.unsafe(80800770, 2849952257),
      Uint64.unsafe(2496577188, 429714436),
      Uint64.unsafe(0, 972477353),
    ];
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powVartime(tm1d2),
      rootOfUnity: JubJubFq.rootOfUnity,
      s: JubJubFqConst.S,
      one: JubJubFq.r,
      conditionalSelect:
          (a, b, choice) => JubJubFq.conditionalSelect(a, b, choice),
    );
  }

  @override
  JubJubFq double() => add(this);

  JubJubFq pow(List<Uint64> by) {
    JubJubFq res = JubJubFq.one;
    for (final e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();
        JubJubFq tmp = res * this;
        final bit = ((e >> i) & Uint64.one) == Uint64.one;
        res = bit ? tmp : res;
      }
    }
    return res;
  }

  @override
  bool operator ==(Object other) =>
      other is JubJubFq && Uint64.ctEquals(limbs, other.limbs);

  @override
  int get hashCode => Object.hashAll(limbs);
}

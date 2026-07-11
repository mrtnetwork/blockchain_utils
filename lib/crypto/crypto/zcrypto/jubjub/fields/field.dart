import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/constants/constants.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

abstract class JubJubPrimeField<F extends JubJubPrimeField<F>>
    extends CryptoField<F> {
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
  @override
  List<bool> charBits() {
    return BigintUtils.toBinaryBool(JubJubNativeConst.qJ, bitLength: 256);
  }
}

abstract class JubJubScalar<F extends JubJubScalar<F>>
    extends JubJubPrimeField<F> {
  @override
  List<bool> charBits() {
    return BigintUtils.toBinaryBool(JubJubNativeConst.rJ, bitLength: 256);
  }
}

/// Element of the JubJub scalar field Fr, internally represented as 4 64-bit limbs in Montgomery form.
class JubJubFr extends JubJubScalar<JubJubFr> with ConstantEquality<JubJubFr> {
  final List<BigInt> limbs;
  JubJubFr(List<BigInt> limbs)
    : limbs = limbs.exc(length: 4, operation: "JubJubFr").immutable;

  factory JubJubFr.montgomeryReduce(
    BigInt r0,
    BigInt r1,
    BigInt r2,
    BigInt r3,
    BigInt r4,
    BigInt r5,
    BigInt r6,
    BigInt r7,
  ) {
    BigInt k = (r0 * JubJubFrConst.inv).toU64;
    List<BigInt> t = BigintUtils.mac(
      r0,
      k,
      JubJubFrConst.modulus.limbs[0],
      BigInt.zero,
    );
    BigInt carry = t[1];
    t = BigintUtils.mac(r1, k, JubJubFrConst.modulus.limbs[1], carry);
    r1 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r2, k, JubJubFrConst.modulus.limbs[2], carry);
    r2 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r3, k, JubJubFrConst.modulus.limbs[3], carry);
    r3 = t[0];
    carry = t[1];

    t = BigintUtils.adc(r4, BigInt.zero, carry);
    r4 = t[0];
    BigInt carry2 = t[1];

    // --- 2nd iteration --------------------------------------------------------
    k = (r1 * JubJubFrConst.inv).toU64;

    t = BigintUtils.mac(r1, k, JubJubFrConst.modulus.limbs[0], BigInt.zero);
    carry = t[1];

    t = BigintUtils.mac(r2, k, JubJubFrConst.modulus.limbs[1], carry);
    r2 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r3, k, JubJubFrConst.modulus.limbs[2], carry);
    r3 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r4, k, JubJubFrConst.modulus.limbs[3], carry);
    r4 = t[0];
    carry = t[1];

    t = BigintUtils.adc(r5, carry2, carry);
    r5 = t[0];
    carry2 = t[1];

    // --- 3rd iteration --------------------------------------------------------
    k = (r2 * JubJubFrConst.inv).toU64;

    t = BigintUtils.mac(r2, k, JubJubFrConst.modulus.limbs[0], BigInt.zero);
    carry = t[1];

    t = BigintUtils.mac(r3, k, JubJubFrConst.modulus.limbs[1], carry);
    r3 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r4, k, JubJubFrConst.modulus.limbs[2], carry);
    r4 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r5, k, JubJubFrConst.modulus.limbs[3], carry);
    r5 = t[0];
    carry = t[1];

    t = BigintUtils.adc(r6, carry2, carry);
    r6 = t[0];
    carry2 = t[1];

    // --- 4th iteration --------------------------------------------------------
    k = (r3 * JubJubFrConst.inv).toU64;

    t = BigintUtils.mac(r3, k, JubJubFrConst.modulus.limbs[0], BigInt.zero);
    carry = t[1];

    t = BigintUtils.mac(r4, k, JubJubFrConst.modulus.limbs[1], carry);
    r4 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r5, k, JubJubFrConst.modulus.limbs[2], carry);
    r5 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r6, k, JubJubFrConst.modulus.limbs[3], carry);
    r6 = t[0];
    carry = t[1];

    t = BigintUtils.adc(r7, carry2, carry);
    r7 = t[0];
    return JubJubFr([r4, r5, r6, r7]).sub(JubJubFrConst.modulus);
  }
  factory JubJubFr.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      length: 32,
      operation: "fromBytes",
      reason: "Invalid field bytes length.",
    );
    final tmp = JubJubFr([
      BigintUtils.fromBytes(bytes.sublist(0, 8), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(8, 16), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(16, 24), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(24, 32), byteOrder: Endian.little),
    ]);
    BigInt borrow = BigInt.zero;
    List<BigInt> temp = BigintUtils.sbb(
      tmp.limbs[0],
      JubJubFrConst.modulus.limbs[0],
      borrow,
    );
    borrow = temp[1];
    temp = BigintUtils.sbb(
      tmp.limbs[1],
      JubJubFrConst.modulus.limbs[1],
      borrow,
    );
    borrow = temp[1];
    temp = BigintUtils.sbb(
      tmp.limbs[2],
      JubJubFrConst.modulus.limbs[2],
      borrow,
    );
    borrow = temp[1];
    temp = BigintUtils.sbb(
      tmp.limbs[3],
      JubJubFrConst.modulus.limbs[3],
      borrow,
    );
    borrow = temp[1];
    final result = tmp * JubJubFr.r2();
    if ((borrow & BigInt.one) != BigInt.one) {
      throw ArgumentException.invalidOperationArguments(
        "JubJubFr",
        reason: "Invalid point encoding bytes.",
      );
    }
    return result;
  }
  factory JubJubFr._fromU512(List<BigInt> limbs) {
    assert(limbs.length == 8);

    // Lower 256 bits
    JubJubFr d0 = JubJubFr([limbs[0], limbs[1], limbs[2], limbs[3]]);
    // Upper 256 bits
    JubJubFr d1 = JubJubFr([limbs[4], limbs[5], limbs[6], limbs[7]]);

    return d0 * JubJubFr.r2() + d1 * JubJubFr.r3();
  }
  factory JubJubFr.fromBytes64(List<int> bytes) {
    return JubJubFr._fromU512([
      BigintUtils.fromBytes(bytes.sublist(0, 8), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(8, 16), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(16, 24), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(24, 32), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(32, 40), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(40, 48), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(48, 56), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(56, 64), byteOrder: Endian.little),
    ]);
  }
  factory JubJubFr.from(BigInt val) {
    return JubJubFr([
      val,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]).mul(JubJubFr.r2());
  }
  factory JubJubFr.fromRaw(List<BigInt> val) {
    if (val.length != 4) {
      throw ArgumentException.invalidOperationArguments(
        "fromRaw",
        reason: "Invalid limbs length.",
      );
    }
    return JubJubFr(val).mul(JubJubFr.r2());
  }
  factory JubJubFr.zero() {
    return JubJubFr([BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]);
  }
  factory JubJubFr.one() {
    return JubJubFr.r();
  }
  factory JubJubFr.r() => JubJubFr([
    BigInt.parse("0x25f80bb3b99607d9"),
    BigInt.parse("0xf315d62f66b6e750"),
    BigInt.parse("0x932514eeeb8814f4"),
    BigInt.parse("0x09a6fc6f479155c6"),
  ]);
  factory JubJubFr.r3() => JubJubFr([
    BigInt.parse("0xe0d6c6563d830544"),
    BigInt.parse("0x323e3883598d0f85"),
    BigInt.parse("0xf0fea3004c2e2ba8"),
    BigInt.parse("0x05874f84946737ec"),
  ]);
  factory JubJubFr.twoInv() => JubJubFr([
    BigInt.parse("0x7b478d0948469a48"),
    BigInt.parse("0xccbefb6199bf7be9"),
    BigInt.parse("0xccc627f7f65e27fa"),
    BigInt.parse("0xc1258acd66282b7"), // note: kept your hex exactly
  ]);
  factory JubJubFr.generator() => JubJubFr([
    BigInt.parse("0x720b1b19d49ea8f1"),
    BigInt.parse("0xbf4aa36101f13a58"),
    BigInt.parse("0x5fa8cc968193ccbb"),
    BigInt.parse("0x0e70cbdc7dccf3ac"),
  ]);
  factory JubJubFr.rootOfUnity() => JubJubFr([
    BigInt.parse("0xaa9f02ab1d6124de"),
    BigInt.parse("0xb3524a6466112932"),
    BigInt.parse("0x7342261215ac260b"),
    BigInt.parse("0x04d6b87b1da259e2"),
  ]);
  factory JubJubFr.rootOfUnityInv() => JubJubFr.rootOfUnity();
  factory JubJubFr.delta() => JubJubFr([
    BigInt.parse("0x994f5ac0c8e41613"),
    BigInt.parse("0x3bb731630bbf0b84"),
    BigInt.parse("0x1df0a4820371a563"),
    BigInt.parse("0x0e303e96f8cb47bd"),
  ]);
  factory JubJubFr.r2() => JubJubFr([
    BigInt.parse("0x67719aa495e57731"),
    BigInt.parse("0x51b0cef09ce3fc26"),
    BigInt.parse("0x69dab7fac026e9a5"),
    BigInt.parse("0x04f6547b8d127688"),
  ]);
  @override
  JubJubFr square() {
    List<BigInt> tmp = BigintUtils.mac(
      BigInt.zero,
      limbs[0],
      limbs[1],
      BigInt.zero,
    );
    BigInt r1 = tmp[0];
    BigInt carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[2], carry);
    BigInt r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[3], carry);
    BigInt r3 = tmp[0];
    BigInt r4 = tmp[1];

    tmp = BigintUtils.mac(r3, limbs[1], limbs[2], BigInt.zero);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[1], limbs[3], carry);
    r4 = tmp[0];
    BigInt r5 = tmp[1];

    tmp = BigintUtils.mac(r5, limbs[2], limbs[3], BigInt.zero);
    r5 = tmp[0];
    BigInt r6 = tmp[1];

    // Double the cross products
    BigInt r7 = (r6 >> 63).toU64;
    r6 = ((r6 << 1) | (r5 >> 63)).toU64;
    r5 = ((r5 << 1) | (r4 >> 63)).toU64;
    r4 = ((r4 << 1) | (r3 >> 63)).toU64;
    r3 = ((r3 << 1) | (r2 >> 63)).toU64;
    r2 = ((r2 << 1) | (r1 >> 63)).toU64;
    r1 = (r1 << 1).toU64;

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[0], BigInt.zero);
    BigInt r0 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r1, carry);
    r1 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r2, limbs[1], limbs[1], carry);
    r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r3, carry);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[2], limbs[2], carry);
    r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r5, carry);
    r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, limbs[3], limbs[3], carry);
    r6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r7, carry);
    r7 = tmp[0];
    return JubJubFr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  JubJubFr sub(JubJubFr rhs) {
    final x0 = limbs[0];
    final x1 = limbs[1];
    final x2 = limbs[2];
    final x3 = limbs[3];

    final y0 = rhs.limbs[0];
    final y1 = rhs.limbs[1];
    final y2 = rhs.limbs[2];
    final y3 = rhs.limbs[3];

    // ----------- First SBB chain -----------
    List<BigInt> t = BigintUtils.sbb(x0, y0, BigInt.zero);
    BigInt d0 = t[0];
    BigInt borrow = t[1];

    t = BigintUtils.sbb(x1, y1, borrow);
    BigInt d1 = t[0];
    borrow = t[1];

    t = BigintUtils.sbb(x2, y2, borrow);
    BigInt d2 = t[0];
    borrow = t[1];

    t = BigintUtils.sbb(x3, y3, borrow);
    BigInt d3 = t[0];
    borrow = t[1];

    t = BigintUtils.adc(
      d0,
      JubJubFrConst.modulus.limbs[0] & borrow,
      BigInt.zero,
    );
    d0 = t[0];
    BigInt carry = t[1];

    t = BigintUtils.adc(d1, JubJubFrConst.modulus.limbs[1] & borrow, carry);
    d1 = t[0];
    carry = t[1];

    t = BigintUtils.adc(d2, JubJubFrConst.modulus.limbs[2] & borrow, carry);
    d2 = t[0];
    carry = t[1];

    t = BigintUtils.adc(d3, JubJubFrConst.modulus.limbs[3] & borrow, carry);
    d3 = t[0];

    return JubJubFr([d0, d1, d2, d3]);
  }

  JubJubFr mul(JubJubFr rhs) {
    final x0 = limbs[0];
    final x1 = limbs[1];
    final x2 = limbs[2];
    final x3 = limbs[3];

    final y0 = rhs.limbs[0];
    final y1 = rhs.limbs[1];
    final y2 = rhs.limbs[2];
    final y3 = rhs.limbs[3];

    // ---------------- SCHOOLBOOK MULTIPLICATION ----------------

    // row 0
    List<BigInt> t = BigintUtils.mac(BigInt.zero, x0, y0, BigInt.zero);
    BigInt r0 = t[0];
    BigInt carry = t[1];

    t = BigintUtils.mac(BigInt.zero, x0, y1, carry);
    BigInt r1 = t[0];
    carry = t[1];

    t = BigintUtils.mac(BigInt.zero, x0, y2, carry);
    BigInt r2 = t[0];
    carry = t[1];

    t = BigintUtils.mac(BigInt.zero, x0, y3, carry);
    BigInt r3 = t[0];
    BigInt r4 = t[1];

    // row 1
    t = BigintUtils.mac(r1, x1, y0, BigInt.zero);
    r1 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r2, x1, y1, carry);
    r2 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r3, x1, y2, carry);
    r3 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r4, x1, y3, carry);
    r4 = t[0];
    BigInt r5 = t[1];

    // row 2
    t = BigintUtils.mac(r2, x2, y0, BigInt.zero);
    r2 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r3, x2, y1, carry);
    r3 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r4, x2, y2, carry);
    r4 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r5, x2, y3, carry);
    r5 = t[0];
    BigInt r6 = t[1];

    // row 3
    t = BigintUtils.mac(r3, x3, y0, BigInt.zero);
    r3 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r4, x3, y1, carry);
    r4 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r5, x3, y2, carry);
    r5 = t[0];
    carry = t[1];

    t = BigintUtils.mac(r6, x3, y3, carry);
    r6 = t[0];
    BigInt r7 = t[1];
    return JubJubFr.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  JubJubFr add(JubJubFr rhs) {
    List<BigInt> t = BigintUtils.adc(limbs[0], rhs.limbs[0], BigInt.zero);
    BigInt d0 = t[0];
    BigInt carry = t[1];

    t = BigintUtils.adc(limbs[1], rhs.limbs[1], carry);
    BigInt d1 = t[0];
    carry = t[1];

    t = BigintUtils.adc(limbs[2], rhs.limbs[2], carry);
    BigInt d2 = t[0];
    carry = t[1];

    t = BigintUtils.adc(limbs[3], rhs.limbs[3], carry);
    BigInt d3 = t[0];
    return JubJubFr([d0, d1, d2, d3]).sub(JubJubFrConst.modulus);
  }

  JubJubFr neg() {
    // Compute modulus - self
    List<BigInt> t = BigintUtils.sbb(
      JubJubFrConst.modulus.limbs[0],
      limbs[0],
      BigInt.zero,
    );
    BigInt d0 = t[0];
    BigInt borrow = t[1];

    t = BigintUtils.sbb(JubJubFrConst.modulus.limbs[1], limbs[1], borrow);
    BigInt d1 = t[0];
    borrow = t[1];

    t = BigintUtils.sbb(JubJubFrConst.modulus.limbs[2], limbs[2], borrow);
    BigInt d2 = t[0];
    borrow = t[1];

    t = BigintUtils.sbb(JubJubFrConst.modulus.limbs[3], limbs[3], borrow);
    BigInt d3 = t[0];
    final oRed = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    final isZero = oRed == BigInt.zero;
    final mask = isZero ? BigInt.zero : BinaryOps.maskBig64;
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

    // Initial computations
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

    // Sequence of squarings and multiplications
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

    if (this == JubJubFr.zero()) return null;
    return t0;
  }

  JubJubFr powVartime(List<BigInt> by) {
    JubJubFr res = JubJubFr.one();
    for (BigInt e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();

        if (((e >> i) & BigInt.one) == BigInt.one) {
          res = res * this;
        }
      }
    }

    return res;
  }

  JubJubFr pow(List<BigInt> by) {
    JubJubFr res = JubJubFr.one();

    // Loop over exponent words, from high → low
    for (final e in by.reversed) {
      // Loop bits from highest to lowest
      for (int i = 63; i >= 0; i--) {
        res = res.square();

        JubJubFr tmp = res;
        tmp = tmp * this;

        // Extract bit: ((e >> i) & 1)
        final bit = ((e >> i) & BigInt.one) == BigInt.one;

        // Constant-time conditional assign
        res = bit ? tmp : res;
      }
    }

    return res;
  }

  @override
  FieldSqrtResult<JubJubFr> sqrt() {
    // (t - 1) // 2 as four u64s
    final sqrt = powVartime([
      BigInt.parse("0xb425c397b5bdcb2e"),
      BigInt.parse("0x299a0824f3320420"),
      BigInt.parse("0x4199cec0404d0ec0"),
      BigInt.parse("0x039f6d3a994cebea"),
    ]);
    return FieldSqrtResult(sqrt, (sqrt * sqrt) == this);
  }

  @override
  bool isZero() {
    return this == JubJubFr.zero();
  }

  FieldSqrtResult<JubJubFr> sqrtRatio(JubJubFr num, JubJubFr div) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: JubJubFr.zero(),
      rootOfUnity: JubJubFr.rootOfUnity(),
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
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    );
    final res = List<int>.filled(32, 0);
    for (int i = 0; i < 4; i++) {
      final limbBytes = tmp.limbs[i].toLeBytes(length: 8);
      res.setRange(i * 8, i * 8 + 8, limbBytes);
    }
    return res;
  }

  @override
  bool constantEquality(JubJubFr other) {
    return CompareUtils.constantTimeBigIntEquals(limbs, other.limbs);
  }
}

class JubJubFq extends JubJubField<JubJubFq> with ConstantEquality<JubJubFq> {
  final List<BigInt> limbs;
  JubJubFq(List<BigInt> limbs)
    : limbs = limbs.exc(length: 4, operation: "JubJubFq").immutable;
  factory JubJubFq.zero() {
    return JubJubFq([BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]);
  }
  factory JubJubFq.one() {
    return JubJubFq.r();
  }
  factory JubJubFq.from(BigInt val) {
    return JubJubFq([
      val,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]).mul(JubJubFq.r2());
  }

  factory JubJubFq.edwardsD() {
    return JubJubFq([
      BigInt.parse('3049539848285517488'),
      BigInt.parse('18189135023605205683'),
      BigInt.parse('8793554888777148625'),
      BigInt.parse('6339087681201251886'),
    ]);
  }
  factory JubJubFq.edwardsD2() {
    return JubJubFq([
      BigInt.parse('6099079700866002271'),
      BigInt.parse('11897366564962777447'),
      BigInt.parse('13895890878914525598'),
      BigInt.parse('4324658502938054420'),
    ]);
  }

  factory JubJubFq.rootOfUnityInv() {
    return JubJubFq([
      BigInt.parse('0x4256481adcf3219a'),
      BigInt.parse('0x45f37b7f96b6cad3'),
      BigInt.parse('0xf9c3f1d75f7a3b27'),
      BigInt.parse('0x2d2fc049658afd43'),
    ]);
  }
  factory JubJubFq.rootOfUnity() {
    return JubJubFq([
      BigInt.parse('0xb9b58d8c5f0e466a'),
      BigInt.parse('0x5b1b4c801819d7ec'),
      BigInt.parse('0x0af53ae352a31e64'),
      BigInt.parse('0x5bf3adda19e9b27b'),
    ]);
  }
  factory JubJubFq.twoInv() {
    return JubJubFq([
      BigInt.parse('0x00000000ffffffff'),
      BigInt.parse('0xac425bfd0001a401'),
      BigInt.parse('0xccc627f7f65e27fa'),
      BigInt.parse('0x0c1258acd66282b7'),
    ]);
  }
  factory JubJubFq.r3() {
    return JubJubFq([
      BigInt.parse('0xc62c1807439b73af'),
      BigInt.parse('0x1b3e0d188cf06990'),
      BigInt.parse('0x73d13c71c7b5f418'),
      BigInt.parse('0x6e2a5bb9c8db33e9'),
    ]);
  }
  factory JubJubFq.r2() {
    return JubJubFq([
      BigInt.parse('0xc999e990f3f29c6d'),
      BigInt.parse('0x2b6cedcb87925c23'),
      BigInt.parse('0x05d314967254398f'),
      BigInt.parse('0x0748d9d99f59ff11'),
    ]);
  }
  factory JubJubFq.r() {
    return JubJubFq([
      BigInt.parse('0x00000001fffffffe'),
      BigInt.parse('0x5884b7fa00034802'),
      BigInt.parse('0x998c4fefecbc4ff5'),
      BigInt.parse('0x1824b159acc5056f'),
    ]);
  }
  factory JubJubFq.fromRaw(List<BigInt> val) {
    assert(val.length == 4);
    // Create JubJubFq element from raw limbs
    JubJubFq tmp = JubJubFq(val);
    // Convert to Montgomery form
    return tmp.mul(JubJubFq.r2());
  }
  factory JubJubFq._fromU512(List<BigInt> limbs) {
    assert(limbs.length == 8);

    // Lower 256 bits
    JubJubFq d0 = JubJubFq([limbs[0], limbs[1], limbs[2], limbs[3]]);
    // Upper 256 bits
    JubJubFq d1 = JubJubFq([limbs[4], limbs[5], limbs[6], limbs[7]]);

    return d0 * JubJubFq.r2() + d1 * JubJubFq.r3();
  }

  factory JubJubFq.conditionalSelect(JubJubFq a, JubJubFq b, bool choice) {
    return JubJubFq([
      BigintUtils.ctSelectBigInt(a.limbs[0], b.limbs[0], choice),
      BigintUtils.ctSelectBigInt(a.limbs[1], b.limbs[1], choice),
      BigintUtils.ctSelectBigInt(a.limbs[2], b.limbs[2], choice),
      BigintUtils.ctSelectBigInt(a.limbs[3], b.limbs[3], choice),
    ]);
  }

  factory JubJubFq.fromBytes64(List<int> bytes) {
    if (bytes.length != 64) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid field encoding bytes length.",
      );
    }
    return JubJubFq._fromU512([
      BigintUtils.fromBytes(bytes.sublist(0, 8), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(8, 16), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(16, 24), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(24, 32), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(32, 40), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(40, 48), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(48, 56), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(56, 64), byteOrder: Endian.little),
    ]);
  }

  factory JubJubFq.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field encoding bytes length.",
      );
    }
    final tmp = JubJubFq([
      BigintUtils.fromBytes(bytes.sublist(0, 8), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(8, 16), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(16, 24), byteOrder: Endian.little),
      BigintUtils.fromBytes(bytes.sublist(24, 32), byteOrder: Endian.little),
    ]);

    BigInt borrow = BigInt.zero;
    var temp = BigintUtils.sbb(
      tmp.limbs[0],
      JubJubFqConst.modulus.limbs[0],
      borrow,
    );
    borrow = temp[1];
    temp = BigintUtils.sbb(
      tmp.limbs[1],
      JubJubFqConst.modulus.limbs[1],
      borrow,
    );
    borrow = temp[1];
    temp = BigintUtils.sbb(
      tmp.limbs[2],
      JubJubFqConst.modulus.limbs[2],
      borrow,
    );
    borrow = temp[1];
    temp = BigintUtils.sbb(
      tmp.limbs[3],
      JubJubFqConst.modulus.limbs[3],
      borrow,
    );
    borrow = temp[1];

    // Convert to Montgomery form: tmp = tmp * r2
    final result = tmp * JubJubFq.r2();
    if ((borrow & BigInt.one) != BigInt.one) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field encoding bytes.",
      );
    }

    return result;
  }
  factory JubJubFq.montgomeryReduce(
    BigInt r0,
    BigInt r1,
    BigInt r2,
    BigInt r3,
    BigInt r4,
    BigInt r5,
    BigInt r6,
    BigInt r7,
  ) {
    BigInt k = (r0 * JubJubFqConst.inv).toU64;
    var tmp = BigintUtils.mac(
      r0,
      k,
      JubJubFqConst.modulus.limbs[0],
      BigInt.zero,
    );
    var carry = tmp[1];
    tmp = BigintUtils.mac(r1, k, JubJubFqConst.modulus.limbs[1], carry);
    r1 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r2, k, JubJubFqConst.modulus.limbs[2], carry);
    r2 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, JubJubFqConst.modulus.limbs[3], carry);
    r3 = tmp[0];
    carry = tmp[1];
    var r4New = BigintUtils.adc(r4, BigInt.zero, carry);
    r4 = r4New[0];
    var carry2 = r4New[1];

    // Step 2
    k = (r1 * JubJubFqConst.inv).toU64;
    tmp = BigintUtils.mac(r1, k, JubJubFqConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r2, k, JubJubFqConst.modulus.limbs[1], carry);
    r2 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, JubJubFqConst.modulus.limbs[2], carry);
    r3 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, JubJubFqConst.modulus.limbs[3], carry);
    r4 = tmp[0];
    carry = tmp[1];
    var r5New = BigintUtils.adc(r5, carry2, carry);
    r5 = r5New[0];
    carry2 = r5New[1];

    // Step 3
    k = (r2 * JubJubFqConst.inv).toU64;
    tmp = BigintUtils.mac(r2, k, JubJubFqConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, JubJubFqConst.modulus.limbs[1], carry);
    r3 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, JubJubFqConst.modulus.limbs[2], carry);
    r4 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r5, k, JubJubFqConst.modulus.limbs[3], carry);
    r5 = tmp[0];
    carry = tmp[1];
    var r6New = BigintUtils.adc(r6, carry2, carry);
    r6 = r6New[0];
    carry2 = r6New[1];

    // Step 4
    k = (r3 * JubJubFqConst.inv).toU64;
    tmp = BigintUtils.mac(r3, k, JubJubFqConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, JubJubFqConst.modulus.limbs[1], carry);
    r4 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r5, k, JubJubFqConst.modulus.limbs[2], carry);
    r5 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r6, k, JubJubFqConst.modulus.limbs[3], carry);
    r6 = tmp[0];
    carry = tmp[1];
    var r7New = BigintUtils.adc(r7, carry2, carry);
    r7 = r7New[0];

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
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    );
    final res = List<int>.filled(32, 0);
    for (int i = 0; i < 4; i++) {
      final limbBytes = tmp.limbs[i].toLeBytes(length: 8);
      res.setRange(i * 8, i * 8 + 8, limbBytes);
    }
    return res;
  }

  @override
  bool isZero() {
    return this == JubJubFq.zero();
  }

  JubJubFq sub(JubJubFq rhs) {
    // Step 1: Subtract limbs with borrow
    var sbbRes = BigintUtils.sbb(limbs[0], rhs.limbs[0], BigInt.zero);
    BigInt d0 = sbbRes[0];
    BigInt borrow = sbbRes[1];

    sbbRes = BigintUtils.sbb(limbs[1], rhs.limbs[1], borrow);
    BigInt d1 = sbbRes[0];
    borrow = sbbRes[1];

    sbbRes = BigintUtils.sbb(limbs[2], rhs.limbs[2], borrow);
    BigInt d2 = sbbRes[0];
    borrow = sbbRes[1];

    sbbRes = BigintUtils.sbb(limbs[3], rhs.limbs[3], borrow);
    BigInt d3 = sbbRes[0];
    borrow = sbbRes[1];

    // Step 2: Conditionally add modulus if underflow occurred
    var adcRes = BigintUtils.adc(
      d0,
      JubJubFqConst.modulus.limbs[0] & borrow,
      BigInt.zero,
    );
    d0 = adcRes[0];
    BigInt carry = adcRes[1];

    adcRes = BigintUtils.adc(
      d1,
      JubJubFqConst.modulus.limbs[1] & borrow,
      carry,
    );
    d1 = adcRes[0];
    carry = adcRes[1];

    adcRes = BigintUtils.adc(
      d2,
      JubJubFqConst.modulus.limbs[2] & borrow,
      carry,
    );
    d2 = adcRes[0];
    carry = adcRes[1];

    adcRes = BigintUtils.adc(
      d3,
      JubJubFqConst.modulus.limbs[3] & borrow,
      carry,
    );
    d3 = adcRes[0];
    // final carry ignored

    return JubJubFq([d0, d1, d2, d3]);
  }

  JubJubFq add(JubJubFq rhs) {
    // Step 1: Add limbs with carry
    var adcRes = BigintUtils.adc(limbs[0], rhs.limbs[0], BigInt.zero);
    BigInt d0 = adcRes[0];
    BigInt carry = adcRes[1];

    adcRes = BigintUtils.adc(limbs[1], rhs.limbs[1], carry);
    BigInt d1 = adcRes[0];
    carry = adcRes[1];

    adcRes = BigintUtils.adc(limbs[2], rhs.limbs[2], carry);
    BigInt d2 = adcRes[0];
    carry = adcRes[1];

    adcRes = BigintUtils.adc(limbs[3], rhs.limbs[3], carry);
    BigInt d3 = adcRes[0];
    // final carry ignored

    // Step 2: Reduce modulo modulus
    return JubJubFq([d0, d1, d2, d3]).sub(JubJubFqConst.modulus);
  }

  JubJubFq neg() {
    // Step 1: Subtract this from modulus
    var sbbRes = BigintUtils.sbb(
      JubJubFqConst.modulus.limbs[0],
      limbs[0],
      BigInt.zero,
    );
    BigInt d0 = sbbRes[0];
    BigInt borrow = sbbRes[1];

    sbbRes = BigintUtils.sbb(JubJubFqConst.modulus.limbs[1], limbs[1], borrow);
    BigInt d1 = sbbRes[0];
    borrow = sbbRes[1];

    sbbRes = BigintUtils.sbb(JubJubFqConst.modulus.limbs[2], limbs[2], borrow);
    BigInt d2 = sbbRes[0];
    borrow = sbbRes[1];

    sbbRes = BigintUtils.sbb(JubJubFqConst.modulus.limbs[3], limbs[3], borrow);
    BigInt d3 = sbbRes[0];
    // final borrow ignored

    // Step 2: Compute mask
    BigInt zeroCheck = limbs[0] | limbs[1] | limbs[2] | limbs[3];
    // If zeroCheck == 0, mask = 0; else mask = 0xffff... (64-bit max)
    BigInt mask = zeroCheck == BigInt.zero ? BigInt.zero : BinaryOps.maskBig64;

    // Step 3: Apply mask
    return JubJubFq([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  JubJubFq mul(JubJubFq rhs) {
    // Schoolbook multiplication
    var tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[0], BigInt.zero);
    BigInt r0 = tmp[0];
    BigInt carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[1], carry);
    BigInt r1 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[2], carry);
    BigInt r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[3], carry);
    BigInt r3 = tmp[0];
    BigInt r4 = tmp[1];

    tmp = BigintUtils.mac(r1, limbs[1], rhs.limbs[0], BigInt.zero);
    r1 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r2, limbs[1], rhs.limbs[1], carry);
    r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r3, limbs[1], rhs.limbs[2], carry);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[1], rhs.limbs[3], carry);
    r4 = tmp[0];
    BigInt r5 = tmp[1];

    tmp = BigintUtils.mac(r2, limbs[2], rhs.limbs[0], BigInt.zero);
    r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r3, limbs[2], rhs.limbs[1], carry);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[2], rhs.limbs[2], carry);
    r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r5, limbs[2], rhs.limbs[3], carry);
    r5 = tmp[0];
    BigInt r6 = tmp[1];

    tmp = BigintUtils.mac(r3, limbs[3], rhs.limbs[0], BigInt.zero);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[3], rhs.limbs[1], carry);
    r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r5, limbs[3], rhs.limbs[2], carry);
    r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, limbs[3], rhs.limbs[3], carry);
    r6 = tmp[0];
    BigInt r7 = tmp[1];

    return JubJubFq.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  JubJubFq square() {
    var tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[1], BigInt.zero);
    BigInt r1 = tmp[0];
    BigInt carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[2], carry);
    BigInt r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[3], carry);
    BigInt r3 = tmp[0];
    BigInt r4 = tmp[1];

    tmp = BigintUtils.mac(r3, limbs[1], limbs[2], BigInt.zero);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[1], limbs[3], carry);
    r4 = tmp[0];
    BigInt r5 = tmp[1];

    tmp = BigintUtils.mac(r5, limbs[2], limbs[3], BigInt.zero);
    r5 = tmp[0];
    BigInt r6 = tmp[1];

    // Double the cross products
    BigInt r7 = (r6 >> 63).toU64;
    r6 = ((r6 << 1) | (r5 >> 63)).toU64;
    r5 = ((r5 << 1) | (r4 >> 63)).toU64;
    r4 = ((r4 << 1) | (r3 >> 63)).toU64;
    r3 = ((r3 << 1) | (r2 >> 63)).toU64;
    r2 = ((r2 << 1) | (r1 >> 63)).toU64;
    r1 = (r1 << 1).toU64;

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[0], BigInt.zero);
    BigInt r0 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r1, carry);
    r1 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r2, limbs[1], limbs[1], carry);
    r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r3, carry);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[2], limbs[2], carry);
    r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r5, carry);
    r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, limbs[3], limbs[3], carry);
    r6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(BigInt.zero, r7, carry);
    r7 = tmp[0];
    // final carry ignored
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

  JubJubFq powVartime(List<BigInt> by) {
    JubJubFq res = JubJubFq.one();
    for (BigInt e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();

        if (((e >> i) & BigInt.one) == BigInt.one) {
          res = res * this;
        }
      }
    }

    return res;
  }

  @override
  FieldSqrtResult<JubJubFq> sqrt() {
    final List<BigInt> tm1d2 = [
      BigInt.parse("0x7fff2dff7fffffff"),
      BigInt.parse("0x04d0ec02a9ded201"),
      BigInt.parse("0x94cebea4199cec04"),
      BigInt.parse("0x0000000039f6d3a9"),
    ];

    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powVartime(tm1d2),
      rootOfUnity: JubJubFq.rootOfUnity(),
      s: JubJubFqConst.S,
      one: JubJubFq.r(),
      conditionalSelect:
          (a, b, choice) => JubJubFq.conditionalSelect(a, b, choice),
    );
  }

  @override
  JubJubFq double() => add(this);

  JubJubFq pow(List<BigInt> by) {
    JubJubFq res = JubJubFq.one();

    // Loop over exponent words, from high → low
    for (final e in by.reversed) {
      // Loop bits from highest to lowest
      for (int i = 63; i >= 0; i--) {
        res = res.square();

        JubJubFq tmp = res;
        tmp = tmp * this;

        // Extract bit: ((e >> i) & 1)
        final bit = ((e >> i) & BigInt.one) == BigInt.one;

        // Constant-time conditional assign
        res = bit ? tmp : res;
      }
    }

    return res;
  }

  @override
  bool constantEquality(JubJubFq other) {
    return CompareUtils.constantTimeBigIntEquals(limbs, other.limbs);
  }
}

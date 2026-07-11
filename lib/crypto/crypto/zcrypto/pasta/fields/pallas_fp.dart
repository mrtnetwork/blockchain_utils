import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class PallasFp extends PastaFieldElement<PallasFp>
    with ConstantEquality<PallasFp> {
  final List<BigInt> limbs;
  PallasFp(List<BigInt> limbs)
    : limbs = limbs.exc(length: 4, operation: "PallasFp").immutable;
  factory PallasFp.zero() =>
      PallasFp([BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]);
  factory PallasFp.one() => PallasFp.r();
  factory PallasFp.from(BigInt val) =>
      PallasFp([val, BigInt.zero, BigInt.zero, BigInt.zero]).mul(PallasFp.r2());
  factory PallasFp.conditionalSelect(PallasFp a, PallasFp b, bool choice) {
    return PallasFp([
      BigintUtils.ctSelectBigInt(a.limbs[0], b.limbs[0], choice),
      BigintUtils.ctSelectBigInt(a.limbs[1], b.limbs[1], choice),
      BigintUtils.ctSelectBigInt(a.limbs[2], b.limbs[2], choice),
      BigintUtils.ctSelectBigInt(a.limbs[3], b.limbs[3], choice),
    ]);
  }
  factory PallasFp.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "PallasFp",
        name: "bytes",
        reason: "Invalid field bytes length.",
      );
    }
    // Parse 4 limbs
    final tmpLimbs = List<BigInt>.generate(4, (i) {
      return BigintUtils.fromBytes(
        bytes.sublist(i * 8, (i * 8) + 8),
        byteOrder: Endian.little,
      );
    });

    final tmp = PallasFp(tmpLimbs);

    // Constant-time check: tmp < modulus
    BigInt borrow = BigInt.zero;
    for (int i = 0; i < 4; i++) {
      borrow = tmp.limbs[i] - PallasFPConst.modulus.limbs[i] - borrow;
      borrow = borrow.isNegative ? BigInt.one : BigInt.zero;
    }
    bool isValid = borrow != BigInt.zero;
    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "PallasFp",
        name: "bytes",
        reason: "Invalid field bytes.",
      );
    }

    // Convert to Montgomery form
    return tmp.mul(PallasFp.r2());
  }
  factory PallasFp.random() {
    return PallasFp._fromU512(List.generate(8, (i) => QuickCrypto.nextU64()));
  }
  factory PallasFp.twoInv() => PallasFp.fromRaw([
    BigInt.parse("0xcc96987680000001"),
    BigInt.parse("0x11234c7e04a67c8d"),
    BigInt.parse("0x0000000000000000"),
    BigInt.parse("0x2000000000000000"),
  ]);

  factory PallasFp.delta() => PallasFp.fromRaw([
    BigInt.parse("0x6a6ccd20dd7b9ba2"),
    BigInt.parse("0xf5e4f3f13eee5636"),
    BigInt.parse("0xbd455b7112a5049d"),
    BigInt.parse("0x0a757d0f0006ab6c"),
  ]);
  factory PallasFp.zeta() => PallasFp.fromRaw([
    BigInt.parse("0x1dad5ebdfdfe4ab9"),
    BigInt.parse("0x1d1f8bd237ad3149"),
    BigInt.parse("0x2caad5dc57aab1b0"),
    BigInt.parse("0x12ccca834acdba71"),
  ]);
  factory PallasFp.rootOfUnityInv() => PallasFp.fromRaw([
    BigInt.parse("0xf0b87c7db2ce91f6"),
    BigInt.parse("0x84a0a1d8859f066f"),
    BigInt.parse("0xb4ed8e647196dad1"),
    BigInt.parse("0x2cd5282c53116b5c"),
  ]);
  factory PallasFp.rootOfUnity() => PallasFp.fromRaw([
    BigInt.parse("0xbdad6fabd87ea32f"),
    BigInt.parse("0xea322bf2b7bb7584"),
    BigInt.parse("0x362120830561f81a"),
    BigInt.parse("0x2bce74deac30ebda"),
  ]);
  factory PallasFp.generator() => PallasFp.fromRaw([
    BigInt.parse("0x0000000000000005"),
    BigInt.parse("0x0000000000000000"),
    BigInt.parse("0x0000000000000000"),
    BigInt.parse("0x0000000000000000"),
  ]);
  factory PallasFp.theta() => PallasFp.fromRaw([
    BigInt.parse("0xca330bcc09ac318e"),
    BigInt.parse("0x51f64fc4dc888857"),
    BigInt.parse("0x4647aef782d5cdc8"),
    BigInt.parse("0x0f7bdb65814179b4"),
  ]);
  factory PallasFp.z() => PallasFp.fromRaw([
    BigInt.parse("0x992d30ecfffffff4"),
    BigInt.parse("0x224698fc094cf91b"),
    BigInt.parse("0x0000000000000000"),
    BigInt.parse("0x4000000000000000"),
  ]);
  factory PallasFp.r3() => PallasFp([
    BigInt.parse("0xf185a5993a9e10f9"),
    BigInt.parse("0xf6a68f3b6ac5b1d1"),
    BigInt.parse("0xdf8d1014353fd42c"),
    BigInt.parse("0x2ae309222d2d9910"),
  ]);
  factory PallasFp.r2() => PallasFp([
    BigInt.parse("0x8c78ecb30000000f"),
    BigInt.parse("0xd7d30dbd8b0de0e7"),
    BigInt.parse("0x7797a99bc3c95d18"),
    BigInt.parse("0x096d41af7b9cb714"),
  ]);
  factory PallasFp.r() => PallasFp([
    BigInt.parse("0x34786d38fffffffd"),
    BigInt.parse("0x992c350be41914ad"),
    BigInt.parse("0xffffffffffffffff"),
    BigInt.parse("0x3fffffffffffffff"),
  ]);
  factory PallasFp.montgomeryReduce(
    BigInt r0,
    BigInt r1,
    BigInt r2,
    BigInt r3,
    BigInt r4,
    BigInt r5,
    BigInt r6,
    BigInt r7,
  ) {
    // Step 1
    BigInt k = (r0 * PallasFPConst.inv).toU64;
    var tmp = BigintUtils.mac(
      r0,
      k,
      PallasFPConst.modulus.limbs[0],
      BigInt.zero,
    );
    var carry = tmp[1];
    tmp = BigintUtils.mac(r1, k, PallasFPConst.modulus.limbs[1], carry);
    r1 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r2, k, PallasFPConst.modulus.limbs[2], carry);
    r2 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, PallasFPConst.modulus.limbs[3], carry);
    r3 = tmp[0];
    carry = tmp[1];
    var r4New = BigintUtils.adc(r4, BigInt.zero, carry);
    r4 = r4New[0];
    var carry2 = r4New[1];

    // Step 2
    k = (r1 * PallasFPConst.inv).toU64;
    tmp = BigintUtils.mac(r1, k, PallasFPConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r2, k, PallasFPConst.modulus.limbs[1], carry);
    r2 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, PallasFPConst.modulus.limbs[2], carry);
    r3 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, PallasFPConst.modulus.limbs[3], carry);
    r4 = tmp[0];
    carry = tmp[1];
    var r5New = BigintUtils.adc(r5, carry2, carry);
    r5 = r5New[0];
    carry2 = r5New[1];

    // Step 3
    k = (r2 * PallasFPConst.inv).toU64;
    tmp = BigintUtils.mac(r2, k, PallasFPConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, PallasFPConst.modulus.limbs[1], carry);
    r3 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, PallasFPConst.modulus.limbs[2], carry);
    r4 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r5, k, PallasFPConst.modulus.limbs[3], carry);
    r5 = tmp[0];
    carry = tmp[1];
    var r6New = BigintUtils.adc(r6, carry2, carry);
    r6 = r6New[0];
    carry2 = r6New[1];

    // Step 4
    k = (r3 * PallasFPConst.inv).toU64;
    tmp = BigintUtils.mac(r3, k, PallasFPConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, PallasFPConst.modulus.limbs[1], carry);
    r4 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r5, k, PallasFPConst.modulus.limbs[2], carry);
    r5 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r6, k, PallasFPConst.modulus.limbs[3], carry);
    r6 = tmp[0];
    carry = tmp[1];
    var r7New = BigintUtils.adc(r7, carry2, carry);
    r7 = r7New[0];
    // final carry ignored

    // Result may be within modulus of the correct value
    return PallasFp([r4, r5, r6, r7]).sub(PallasFPConst.modulus);
  }

  PallasFp clone() {
    return PallasFp(limbs.clone());
  }

  PallasFp sub(PallasFp rhs) {
    // 4-limb subtraction with borrow
    var r0 = BigintUtils.sbb(limbs[0], rhs.limbs[0], BigInt.zero);
    var d0 = r0[0];
    var borrow = r0[1];

    var r1 = BigintUtils.sbb(limbs[1], rhs.limbs[1], borrow);
    var d1 = r1[0];
    borrow = r1[1];

    var r2 = BigintUtils.sbb(limbs[2], rhs.limbs[2], borrow);
    var d2 = r2[0];
    borrow = r2[1];

    var r3 = BigintUtils.sbb(limbs[3], rhs.limbs[3], borrow);
    var d3 = r3[0];
    borrow = r3[1];

    // If underflow happened:
    //   borrow = 0xFFFFFFFFFFFFFFFF (as BigInt)
    // Otherwise:
    //   borrow = 0x0
    //
    // So we AND each modulus limb with borrow to conditionally add modulus.

    // Add modulus if borrow mask is nonzero
    var a0 = BigintUtils.adc(
      d0,
      PallasFPConst.modulus.limbs[0] & borrow,
      BigInt.zero,
    );
    d0 = a0[0];
    var carry = a0[1];

    var a1 = BigintUtils.adc(
      d1,
      PallasFPConst.modulus.limbs[1] & borrow,
      carry,
    );
    d1 = a1[0];
    carry = a1[1];

    var a2 = BigintUtils.adc(
      d2,
      PallasFPConst.modulus.limbs[2] & borrow,
      carry,
    );
    d2 = a2[0];
    carry = a2[1];

    var a3 = BigintUtils.adc(
      d3,
      PallasFPConst.modulus.limbs[3] & borrow,
      carry,
    );
    d3 = a3[0];

    return PallasFp([d0, d1, d2, d3]);
  }

  PallasFp add(PallasFp rhs) {
    // Limbwise addition
    var r0 = BigintUtils.adc(limbs[0], rhs.limbs[0], BigInt.zero);
    var d0 = r0[0];
    var carry = r0[1];

    var r1 = BigintUtils.adc(limbs[1], rhs.limbs[1], carry);
    var d1 = r1[0];
    carry = r1[1];

    var r2 = BigintUtils.adc(limbs[2], rhs.limbs[2], carry);
    var d2 = r2[0];
    carry = r2[1];

    var r3 = BigintUtils.adc(limbs[3], rhs.limbs[3], carry);
    var d3 = r3[0];
    // ignore final carry — reduction handles it

    // Reduce by subtracting modulus
    return PallasFp([d0, d1, d2, d3]).sub(PallasFPConst.modulus.clone());
  }

  PallasFp neg() {
    // Compute modulus - self
    var r0 = BigintUtils.sbb(
      PallasFPConst.modulus.limbs[0],
      limbs[0],
      BigInt.zero,
    );
    var d0 = r0[0];
    var borrow = r0[1];

    var r1 = BigintUtils.sbb(PallasFPConst.modulus.limbs[1], limbs[1], borrow);
    var d1 = r1[0];
    borrow = r1[1];

    var r2 = BigintUtils.sbb(PallasFPConst.modulus.limbs[2], limbs[2], borrow);
    var d2 = r2[0];
    borrow = r2[1];

    var r3 = BigintUtils.sbb(PallasFPConst.modulus.limbs[3], limbs[3], borrow);
    var d3 = r3[0];
    // final borrow ignored (same as Rust)

    // mask = 0xffff...ffff if self != 0
    // mask = 0x0000...0000 if self == 0
    final BigInt orAll = limbs[0] | limbs[1] | limbs[2] | limbs[3];

    // ((orAll == 0) ? 1 : 0) - 1  →  0 or -1
    BigInt mask =
        ((orAll == BigInt.zero ? BigInt.one : BigInt.zero) - BigInt.one).toU64;

    return PallasFp([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  PallasFp mul(PallasFp rhs) {
    // Schoolbook multiplication

    var tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[0], BigInt.zero);
    var r0 = tmp[0];
    var carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[1], carry);
    var r1 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[2], carry);
    var r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[3], carry);
    var r3 = tmp[0];
    var r4 = tmp[1];

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
    var r5 = tmp[1];

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
    var r6 = tmp[1];

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
    var r7 = tmp[1];

    // Perform Montgomery reduction
    return PallasFp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  PallasFp double() {
    return add(this);
  }

  factory PallasFp._fromU512(List<BigInt> limbs) {
    assert(limbs.length == 8);

    // Lower 256 bits
    PallasFp d0 = PallasFp([limbs[0], limbs[1], limbs[2], limbs[3]]);
    // Upper 256 bits
    PallasFp d1 = PallasFp([limbs[4], limbs[5], limbs[6], limbs[7]]);

    // Convert to Montgomery form: d0*R^2 + d1*R^3
    PallasFp lower = d0.mul(PallasFp.r2());
    PallasFp upper = d1.mul(PallasFp.r3());

    return lower.add(upper);
  }

  factory PallasFp.fromU128(BigInt v) {
    final lower = v.toU64;
    final upper = (v >> 64).toU64;
    PallasFp tmp = PallasFp.from(upper);
    for (int i = 0; i < 64; i++) {
      tmp = tmp.double();
    }
    return tmp + PallasFp.from(lower);
  }

  @override
  PallasFp square() {
    // Compute cross terms
    var tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[1], BigInt.zero);
    var r1 = tmp[0];
    var carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[2], carry);
    var r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[3], carry);
    var r3 = tmp[0];
    var r4 = tmp[1];

    tmp = BigintUtils.mac(r3, limbs[1], limbs[2], BigInt.zero);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, limbs[1], limbs[3], carry);
    r4 = tmp[0];
    var r5 = tmp[1];

    tmp = BigintUtils.mac(r5, limbs[2], limbs[3], BigInt.zero);
    r5 = tmp[0];
    var r6 = tmp[1];

    // Step 2: double the cross terms
    var r7 = (r6 >> 63).toU64;
    r6 = ((r6 << 1) | (r5 >> 63)).toU64;
    r5 = ((r5 << 1) | (r4 >> 63)).toU64;
    r4 = ((r4 << 1) | (r3 >> 63)).toU64;
    r3 = ((r3 << 1) | (r2 >> 63)).toU64;
    r2 = ((r2 << 1) | (r1 >> 63)).toU64;
    r1 = (r1 << 1).toU64;

    // Add squares of individual limbs
    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[0], BigInt.zero);
    var r0 = tmp[0];
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

    // Perform Montgomery reduction
    return PallasFp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  factory PallasFp.fromRaw(List<BigInt> val) {
    assert(val.length == 4);
    // Create PallasFp element from raw limbs
    PallasFp tmp = PallasFp(val);
    // Convert to Montgomery form
    return tmp.mul(PallasFp.r2());
  }

  factory PallasFp.fromBytes64(List<int> bytes) {
    bytes = bytes.exc(
      length: 64,
      operation: "fromBytes64",
      reason: "Invalid bytes length.",
    );
    return PallasFp._fromU512([
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

  @override
  PallasFp operator +(PallasFp rhs) => add(rhs);
  @override
  PallasFp operator -(PallasFp rhs) => sub(rhs);
  @override
  PallasFp operator *(PallasFp rhs) => mul(rhs);
  @override
  PallasFp operator -() => neg();

  @override
  int getLower32() {
    final tmp = PallasFp.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    );
    return tmp.limbs[0].toU32;
  }

  @override
  bool isZero() {
    return this == PallasFp.zero();
  }

  @override
  PallasFp powByTMinus1Over2() {
    PallasFp sqr(PallasFp x, int i) {
      PallasFp res = x;
      for (int j = 0; j < i; j++) {
        res = res.square();
      }
      return res;
    }

    final r10 = square();
    final r11 = r10 * this;
    final r110 = r11.square();
    final r111 = r110 * this;
    final r1001 = r111 * r10;
    final r1101 = r111 * r110;
    final ra = sqr(this, 129) * this;
    final rb = sqr(ra, 7) * r1001;
    final rc = sqr(rb, 7) * r1101;
    final rd = sqr(rc, 4) * r11;
    final re = sqr(rd, 6) * r111;
    final rf = sqr(re, 3) * r111;
    final rg = sqr(rf, 10) * r1001;
    final rh = sqr(rg, 5) * r1001;
    final ri = sqr(rh, 4) * r1001;
    final rj = sqr(ri, 3) * r111;
    final rk = sqr(rj, 4) * r1001;
    final rl = sqr(rk, 5) * r11;
    final rm = sqr(rl, 4) * r111;
    final rn = sqr(rm, 4) * r11;
    final ro = sqr(rn, 6) * r1001;
    final rp = sqr(ro, 5) * r1101;
    final rq = sqr(rp, 4) * r11;
    final rr = sqr(rq, 7) * r111;
    final rs = sqr(rr, 3) * r11;
    return rs.square();
  }

  @override
  FieldSqrtResult<PallasFp> sqrt() {
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powByTMinus1Over2(),
      rootOfUnity: PallasFp.rootOfUnity(),
      one: PallasFp.one(),
      conditionalSelect: PallasFp.conditionalSelect,
    );
  }

  static FieldSqrtResult<PallasFp> sqrtRatio(PallasFp num, PallasFp div) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: PallasFp.zero(),
      rootOfUnity: PallasFp.rootOfUnity(),
    );
  }

  static FieldSqrtResult<PallasFp> sqrtAlt(PallasFp r) {
    return PastaUtils.sqrtTonelliShanks(
      f: r,
      fPowTm1d2: r.powByTMinus1Over2(),
      rootOfUnity: PallasFp.rootOfUnity(),
      one: PallasFp.one(),
      conditionalSelect: PallasFp.conditionalSelect,
    );
  }

  @override
  List<int> toBytes() {
    final tmp = PallasFp.montgomeryReduce(
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

  PallasFp pow(List<BigInt> expWords) {
    var res = PallasFp.one();
    var foundOne = false;

    // Process exponent words from most-significant to least
    for (var e in expWords.reversed) {
      // Each word is 64 bits, iterate from MSB to LSB
      for (var i = 63; i >= 0; i--) {
        if (foundOne) {
          res = res.square();
        }

        if (((e >> i).toU64 & BigInt.one) == BigInt.one) {
          foundOne = true;
          res = res * this; // or res = res.mul(this);
        }
      }
    }

    return res;
  }

  @override
  PallasFp? invert() {
    if (isZero()) return null;
    final tmp = pow([
      BigInt.parse("0x992d30ecffffffff"),
      BigInt.parse("0x224698fc094cf91b"),
      BigInt.zero,
      BigInt.parse("0x4000000000000000"),
    ]);
    return tmp;
  }

  @override
  bool constantEquality(PallasFp other) {
    return CompareUtils.constantTimeBigIntEquals(limbs, other.limbs);
  }

  @override
  PallasFp conditionalSelect(PallasFp a, PallasFp b, bool choice) {
    return PallasFp.conditionalSelect(a, b, choice);
  }

  @override
  FieldSqrtResult<PallasFp> sRatio(PallasFp a, PallasFp b) {
    return sqrtRatio(a, b);
  }
}

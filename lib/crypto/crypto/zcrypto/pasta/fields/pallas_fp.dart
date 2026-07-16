import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class PallasFp extends PastaFieldElement<PallasFp>
    with ConstantEquality<PallasFp> {
  final List<Uint64> limbs;
  const PallasFp.unsafe(this.limbs);
  PallasFp(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "PallasFp").immutable;
  static const zero = PallasFp.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);

  static const PallasFp one = r;
  factory PallasFp.from(Uint64 val) =>
      PallasFp([val, Uint64.zero, Uint64.zero, Uint64.zero]).mul(PallasFp.r2);
  factory PallasFp.conditionalSelect(PallasFp a, PallasFp b, bool choice) {
    return PallasFp([
      Uint64.ctSelect(a.limbs[0], b.limbs[0], choice),
      Uint64.ctSelect(a.limbs[1], b.limbs[1], choice),
      Uint64.ctSelect(a.limbs[2], b.limbs[2], choice),
      Uint64.ctSelect(a.limbs[3], b.limbs[3], choice),
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
    final tmpLimbs = List<Uint64>.generate(4, (i) {
      return Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8);
    });

    final tmp = PallasFp(tmpLimbs);
    Uint64 borrow = Uint64.zero;
    (_, borrow) = Uint64.sbb(
      tmp.limbs[0],
      PallasFPConst.modulus.limbs[0],
      Uint64.zero,
    );
    (_, borrow) = Uint64.sbb(
      tmp.limbs[1],
      PallasFPConst.modulus.limbs[1],
      borrow,
    );
    (_, borrow) = Uint64.sbb(
      tmp.limbs[2],
      PallasFPConst.modulus.limbs[2],
      borrow,
    );
    (_, borrow) = Uint64.sbb(
      tmp.limbs[3],
      PallasFPConst.modulus.limbs[3],
      borrow,
    );
    bool isValid = borrow != Uint64.zero;
    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "PallasFp",
        name: "bytes",
        reason: "Invalid field bytes.",
      );
    }

    // Convert to Montgomery form
    return tmp.mul(PallasFp.r2);
  }
  factory PallasFp.random() {
    return PallasFp._fromU512(
      List.generate(8, (i) => Uint64.fromBigInt(QuickCrypto.nextU64())),
    );
  }
  static const PallasFp r = PallasFp.unsafe([
    Uint64.unsafe(880307512, 4294967293),
    Uint64.unsafe(2569811211, 3826848941),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(1073741823, 4294967295),
  ]);
  static const PallasFp twoInv = PallasFp.unsafe([
    Uint64.unsafe(1725091602, 4294967295),
    Uint64.unsafe(3719915267, 4138927844),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(1073741823, 4294967295),
  ]);
  static const PallasFp delta = PallasFp.unsafe([
    Uint64.unsafe(1499851183, 2640646513),
    Uint64.unsafe(3351616539, 2988632374),
    Uint64.unsafe(657115884, 1505142668),
    Uint64.unsafe(149618766, 2030286673),
  ]);
  static const PallasFp r2 = PallasFp.unsafe([
    Uint64.unsafe(2356735155, 15),
    Uint64.unsafe(3620933053, 2332942567),
    Uint64.unsafe(2006428059, 3284753688),
    Uint64.unsafe(158155183, 2073868052),
  ]);
  static const PallasFp r3 = PallasFp.unsafe([
    Uint64.unsafe(4052067737, 983437561),
    Uint64.unsafe(4138110779, 1791341009),
    Uint64.unsafe(3750563860, 893375532),
    Uint64.unsafe(719522082, 757963024),
  ]);
  static const PallasFp rootOfUnity = PallasFp.unsafe([
    Uint64.unsafe(2727196745, 3134643184),
    Uint64.unsafe(2424556803, 3551869407),
    Uint64.unsafe(4222007754, 2647147662),
    Uint64.unsafe(1053370484, 2072626906),
  ]);
  static const PallasFp rootOfUnityInv = PallasFp.unsafe([
    Uint64.unsafe(1560174439, 3407172674),
    Uint64.unsafe(392454338, 1934378529),
    Uint64.unsafe(3749773334, 1159807248),
    Uint64.unsafe(402948025, 4178602172),
  ]);
  static const PallasFp zeta = PallasFp.unsafe([
    Uint64.unsafe(33692918, 1637487933),
    Uint64.unsafe(2659985047, 1233172366),
    Uint64.unsafe(711421276, 3363456614),
    Uint64.unsafe(366478493, 2812377206),
  ]);
  static const PallasFp generator = PallasFp.unsafe([
    Uint64.unsafe(2711969384, 4294967277),
    Uint64.unsafe(1958913355, 1330217715),
    Uint64.unsafe(4294967295, 4294967293),
    Uint64.unsafe(1073741823, 4294967295),
  ]);
  static const PallasFp z = PallasFp.unsafe([
    Uint64.unsafe(489549860, 52),
    Uint64.unsafe(4132901681, 3819084187),
    Uint64.unsafe(0, 6),
    Uint64.zero,
  ]);
  static const PallasFp theta = PallasFp.unsafe([
    Uint64.unsafe(2547692973, 1678643153),
    Uint64.unsafe(2582586898, 3497062826),
    Uint64.unsafe(1061503000, 2575344300),
    Uint64.unsafe(695866171, 2338936367),
  ]);
  factory PallasFp.montgomeryReduce(
    Uint64 r0,
    Uint64 r1,
    Uint64 r2,
    Uint64 r3,
    Uint64 r4,
    Uint64 r5,
    Uint64 r6,
    Uint64 r7,
  ) {
    // Step 1
    Uint64 k = (r0 * PallasFPConst.inv);
    var tmp = Uint64.mac(r0, k, PallasFPConst.modulus.limbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, PallasFPConst.modulus.limbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, PallasFPConst.modulus.limbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, PallasFPConst.modulus.limbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var r4New = Uint64.adc(r4, Uint64.zero, carry);
    r4 = r4New.$1;
    var carry2 = r4New.$2;

    // Step 2
    k = (r1 * PallasFPConst.inv);
    tmp = Uint64.mac(r1, k, PallasFPConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, PallasFPConst.modulus.limbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, PallasFPConst.modulus.limbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, PallasFPConst.modulus.limbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var r5New = Uint64.adc(r5, carry2, carry);
    r5 = r5New.$1;
    carry2 = r5New.$2;

    // Step 3
    k = (r2 * PallasFPConst.inv);
    tmp = Uint64.mac(r2, k, PallasFPConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, PallasFPConst.modulus.limbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, PallasFPConst.modulus.limbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, PallasFPConst.modulus.limbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var r6New = Uint64.adc(r6, carry2, carry);
    r6 = r6New.$1;
    carry2 = r6New.$2;

    // Step 4
    k = (r3 * PallasFPConst.inv);
    tmp = Uint64.mac(r3, k, PallasFPConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, PallasFPConst.modulus.limbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, PallasFPConst.modulus.limbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, PallasFPConst.modulus.limbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var r7New = Uint64.adc(r7, carry2, carry);
    r7 = r7New.$1;
    // final carry ignored

    // Result may be within modulus of the correct value
    return PallasFp([r4, r5, r6, r7]).sub(PallasFPConst.modulus);
  }

  PallasFp clone() {
    return PallasFp(limbs.clone());
  }

  PallasFp sub(PallasFp rhs) {
    // 4-limb subtraction with borrow
    var r0 = Uint64.sbb(limbs[0], rhs.limbs[0], Uint64.zero);
    var d0 = r0.$1;
    var borrow = r0.$2;

    var r1 = Uint64.sbb(limbs[1], rhs.limbs[1], borrow);
    var d1 = r1.$1;
    borrow = r1.$2;

    var r2 = Uint64.sbb(limbs[2], rhs.limbs[2], borrow);
    var d2 = r2.$1;
    borrow = r2.$2;

    var r3 = Uint64.sbb(limbs[3], rhs.limbs[3], borrow);
    var d3 = r3.$1;
    borrow = r3.$2;

    // If underflow happened:
    //   borrow = 0xFFFFFFFFFFFFFFFF (as Uint64)
    // Otherwise:
    //   borrow = 0x0
    //
    // So we AND each modulus limb with borrow to conditionally add modulus.

    // Add modulus if borrow mask is nonzero
    var a0 = Uint64.adc(
      d0,
      PallasFPConst.modulus.limbs[0] & borrow,
      Uint64.zero,
    );
    d0 = a0.$1;
    var carry = a0.$2;

    var a1 = Uint64.adc(d1, PallasFPConst.modulus.limbs[1] & borrow, carry);
    d1 = a1.$1;
    carry = a1.$2;

    var a2 = Uint64.adc(d2, PallasFPConst.modulus.limbs[2] & borrow, carry);
    d2 = a2.$1;
    carry = a2.$2;

    var a3 = Uint64.adc(d3, PallasFPConst.modulus.limbs[3] & borrow, carry);
    d3 = a3.$1;

    return PallasFp([d0, d1, d2, d3]);
  }

  PallasFp add(PallasFp rhs) {
    // Limbwise addition
    var r0 = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    var d0 = r0.$1;
    var carry = r0.$2;

    var r1 = Uint64.adc(limbs[1], rhs.limbs[1], carry);
    var d1 = r1.$1;
    carry = r1.$2;

    var r2 = Uint64.adc(limbs[2], rhs.limbs[2], carry);
    var d2 = r2.$1;
    carry = r2.$2;

    var r3 = Uint64.adc(limbs[3], rhs.limbs[3], carry);
    var d3 = r3.$1;
    // ignore final carry — reduction handles it

    // Reduce by subtracting modulus
    return PallasFp([d0, d1, d2, d3]).sub(PallasFPConst.modulus);
  }

  PallasFp neg() {
    // Compute modulus - self
    var r0 = Uint64.sbb(PallasFPConst.modulus.limbs[0], limbs[0], Uint64.zero);
    var d0 = r0.$1;
    var borrow = r0.$2;

    var r1 = Uint64.sbb(PallasFPConst.modulus.limbs[1], limbs[1], borrow);
    var d1 = r1.$1;
    borrow = r1.$2;

    var r2 = Uint64.sbb(PallasFPConst.modulus.limbs[2], limbs[2], borrow);
    var d2 = r2.$1;
    borrow = r2.$2;

    var r3 = Uint64.sbb(PallasFPConst.modulus.limbs[3], limbs[3], borrow);
    var d3 = r3.$1;
    // final borrow ignored (same as Rust)

    // mask = 0xffff...ffff if self != 0
    // mask = 0x0000...0000 if self == 0
    final Uint64 orAll = limbs[0] | limbs[1] | limbs[2] | limbs[3];

    // ((orAll == 0) ? 1 : 0) - 1  →  0 or -1
    Uint64 mask =
        ((orAll == Uint64.zero ? Uint64.one : Uint64.zero) - Uint64.one);

    return PallasFp([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  PallasFp mul(PallasFp rhs) {
    // Schoolbook multiplication

    var tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[0], Uint64.zero);
    var r0 = tmp.$1;
    var carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[1], carry);
    var r1 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[2], carry);
    var r2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[3], carry);
    var r3 = tmp.$1;
    var r4 = tmp.$2;

    tmp = Uint64.mac(r1, limbs[1], rhs.limbs[0], Uint64.zero);
    r1 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r2, limbs[1], rhs.limbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r3, limbs[1], rhs.limbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r4, limbs[1], rhs.limbs[3], carry);
    r4 = tmp.$1;
    var r5 = tmp.$2;

    tmp = Uint64.mac(r2, limbs[2], rhs.limbs[0], Uint64.zero);
    r2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r3, limbs[2], rhs.limbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r4, limbs[2], rhs.limbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r5, limbs[2], rhs.limbs[3], carry);
    r5 = tmp.$1;
    var r6 = tmp.$2;

    tmp = Uint64.mac(r3, limbs[3], rhs.limbs[0], Uint64.zero);
    r3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r4, limbs[3], rhs.limbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r5, limbs[3], rhs.limbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r6, limbs[3], rhs.limbs[3], carry);
    r6 = tmp.$1;
    var r7 = tmp.$2;

    // Perform Montgomery reduction
    return PallasFp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  @override
  PallasFp double() {
    return add(this);
  }

  factory PallasFp._fromU512(List<Uint64> limbs) {
    assert(limbs.length == 8);

    // Lower 256 bits
    PallasFp d0 = PallasFp([limbs[0], limbs[1], limbs[2], limbs[3]]);
    // Upper 256 bits
    PallasFp d1 = PallasFp([limbs[4], limbs[5], limbs[6], limbs[7]]);

    // Convert to Montgomery form: d0*R^2 + d1*R^3
    PallasFp lower = d0.mul(PallasFp.r2);
    PallasFp upper = d1.mul(PallasFp.r3);

    return lower.add(upper);
  }

  factory PallasFp.fromU128(BigInt v) {
    final lower = v;
    final upper = (v >> 64);
    PallasFp tmp = PallasFp.from(Uint64.fromBigInt(upper));
    for (int i = 0; i < 64; i++) {
      tmp = tmp.double();
    }
    return tmp + PallasFp.from(Uint64.fromBigInt(lower));
  }

  @override
  PallasFp square() {
    // Compute cross terms
    var tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[1], Uint64.zero);
    var r1 = tmp.$1;
    var carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[2], carry);
    var r2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[3], carry);
    var r3 = tmp.$1;
    var r4 = tmp.$2;

    tmp = Uint64.mac(r3, limbs[1], limbs[2], Uint64.zero);
    r3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r4, limbs[1], limbs[3], carry);
    r4 = tmp.$1;
    var r5 = tmp.$2;

    tmp = Uint64.mac(r5, limbs[2], limbs[3], Uint64.zero);
    r5 = tmp.$1;
    var r6 = tmp.$2;

    // Step 2: double the cross terms
    var r7 = (r6 >> 63);
    r6 = ((r6 << 1) | (r5 >> 63));
    r5 = ((r5 << 1) | (r4 >> 63));
    r4 = ((r4 << 1) | (r3 >> 63));
    r3 = ((r3 << 1) | (r2 >> 63));
    r2 = ((r2 << 1) | (r1 >> 63));
    r1 = (r1 << 1);

    // Add squares of individual limbs
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[0], Uint64.zero);
    var r0 = tmp.$1;
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
    // final carry ignored

    // Perform Montgomery reduction
    return PallasFp.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  factory PallasFp.fromRaw(List<Uint64> limbs) {
    limbs = limbs.exc(
      length: 4,
      operation: "fromRaw",
      reason: "Invalid limbs length.",
    );
    // Create PallasFp element from raw limbs
    PallasFp tmp = PallasFp(limbs);
    // Convert to Montgomery form
    return tmp.mul(PallasFp.r2);
  }

  factory PallasFp.fromBytes64(List<int> bytes) {
    bytes = bytes.exc(
      length: 64,
      operation: "fromBytes64",
      reason: "Invalid bytes length.",
    );
    return PallasFp._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8),
      ),
    );
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
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );
    return (tmp.limbs[0] & Uint64.maxU32).toInt();
  }

  @override
  bool isZero() {
    return this == PallasFp.zero;
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
    return sqrtAlt(this);
  }

  static FieldSqrtResult<PallasFp> sqrtRatio(PallasFp num, PallasFp div) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: PallasFp.zero,
      rootOfUnity: PallasFp.rootOfUnity,
    );
  }

  static FieldSqrtResult<PallasFp> sqrtAlt(PallasFp r) {
    return PastaUtils.sqrtTonelliShanks(
      f: r,
      fPowTm1d2: r.powByTMinus1Over2(),
      rootOfUnity: PallasFp.rootOfUnity,
      one: PallasFp.one,
      conditionalSelect: PallasFp.conditionalSelect,
      s: PallasFPConst.S,
    );
  }

  @override
  List<int> toBytes() {
    final tmp = PallasFp.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );
    final res = List<int>.filled(32, 0);
    for (int i = 0; i < 4; i++) {
      final limbBytes = tmp.limbs[i].toBytesLE();
      res.setRange(i * 8, i * 8 + 8, limbBytes);
    }

    return res;
  }

  PallasFp pow(List<Uint64> expWords) {
    var res = PallasFp.one;
    var foundOne = false;

    // Process exponent words from most-significant to least
    for (var e in expWords.reversed) {
      // Each word is 64 bits, iterate from MSB to LSB
      for (var i = 63; i >= 0; i--) {
        if (foundOne) {
          res = res.square();
        }

        if (((e >> i) & Uint64.one) == Uint64.one) {
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
    const m = [
      Uint64.unsafe(2569875692, 4294967295),
      Uint64.unsafe(575052028, 156039451),
      Uint64.zero,
      Uint64.unsafe(1073741824, 0),
    ];
    final tmp = pow(m);
    return tmp;
  }

  @override
  bool constantEquality(PallasFp other) {
    return Uint64.ctEquals(limbs, other.limbs);
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

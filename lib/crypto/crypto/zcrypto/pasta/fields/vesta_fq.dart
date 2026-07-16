import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/vesta.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class VestaFq extends PastaFieldElement<VestaFq>
    with ConstantEquality<VestaFq> {
  final List<Uint64> limbs;
  const VestaFq.unsafe(this.limbs);
  VestaFq(List<Uint64> limbs)
    : limbs = limbs.exc(length: 4, operation: "VestaFq").immutable;

  static const VestaFq zero = VestaFq.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  factory VestaFq.fromRaw(List<Uint64> limbs) {
    return VestaFq(limbs).mul(VestaFq.r2);
  }

  factory VestaFq.from(Uint64 val) =>
      VestaFq([val, Uint64.zero, Uint64.zero, Uint64.zero]).mul(VestaFq.r2);
  factory VestaFq.conditionalSelect(VestaFq a, VestaFq b, bool choice) {
    return VestaFq([
      Uint64.ctSelect(a.limbs[0], b.limbs[0], choice),
      Uint64.ctSelect(a.limbs[1], b.limbs[1], choice),
      Uint64.ctSelect(a.limbs[2], b.limbs[2], choice),
      Uint64.ctSelect(a.limbs[3], b.limbs[3], choice),
    ]);
  }
  factory VestaFq.fromBytes64(List<int> bytes) {
    bytes = bytes.exc(
      length: 64,
      operation: "fromBytes64",
      reason: "Invalid bytes length.",
    );
    return VestaFq._fromU512(
      List.generate(
        8,
        (i) => Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8),
      ),
    );
  }
  factory VestaFq.random() {
    return VestaFq._fromU512(
      List.generate(8, (i) => Uint64.fromBigInt(QuickCrypto.nextU64())),
    );
  }
  factory VestaFq._fromU512(List<Uint64> limbs) {
    assert(limbs.length == 8);

    // Split the 512-bit number into lower and upper 256-bit halves
    final d0 = VestaFq([limbs[0], limbs[1], limbs[2], limbs[3]]);
    final d1 = VestaFq([limbs[4], limbs[5], limbs[6], limbs[7]]);
    // Convert to Montgomery form
    return d0 * VestaFq.r2 + d1 * VestaFq.r3;
  }
  factory VestaFq.fromU128(BigInt v) {
    final lower = v.toU64;
    final upper = (v >> 64).toU64;
    VestaFq tmp = VestaFq.from(Uint64.fromBigInt(upper));
    for (int i = 0; i < 64; i++) {
      tmp = tmp.double();
    }
    return tmp + VestaFq.from(Uint64.fromBigInt(lower));
  }

  factory VestaFq.montgomeryReduce(
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
    Uint64 k = r0 * VestaFQConst.inv & Uint64.max;
    var tmp = Uint64.mac(r0, k, VestaFQConst.modulus.limbs[0], Uint64.zero);
    var carry = tmp.$2;
    tmp = Uint64.mac(r1, k, VestaFQConst.modulus.limbs[1], carry);
    r1 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, VestaFQConst.modulus.limbs[2], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, VestaFQConst.modulus.limbs[3], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    var r4New = Uint64.adc(r4, Uint64.zero, carry);
    r4 = r4New.$1;
    var carry2 = r4New.$2;

    // Step 2
    k = r1 * VestaFQConst.inv & Uint64.max;
    tmp = Uint64.mac(r1, k, VestaFQConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r2, k, VestaFQConst.modulus.limbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, VestaFQConst.modulus.limbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, VestaFQConst.modulus.limbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    var r5New = Uint64.adc(r5, carry2, carry);
    r5 = r5New.$1;
    carry2 = r5New.$2;

    // Step 3
    k = r2 * VestaFQConst.inv & Uint64.max;
    tmp = Uint64.mac(r2, k, VestaFQConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r3, k, VestaFQConst.modulus.limbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, VestaFQConst.modulus.limbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, VestaFQConst.modulus.limbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    var r6New = Uint64.adc(r6, carry2, carry);
    r6 = r6New.$1;
    carry2 = r6New.$2;

    // Step 4
    k = r3 * VestaFQConst.inv & Uint64.max;
    tmp = Uint64.mac(r3, k, VestaFQConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;
    tmp = Uint64.mac(r4, k, VestaFQConst.modulus.limbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r5, k, VestaFQConst.modulus.limbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;
    tmp = Uint64.mac(r6, k, VestaFQConst.modulus.limbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;
    var r7New = Uint64.adc(r7, carry2, carry);
    r7 = r7New.$1;
    // final carry ignored

    // Result may be within modulus of the correct value
    return VestaFq([r4, r5, r6, r7]).sub(VestaFQConst.modulus);
  }
  static const VestaFq one = VestaFq.r;
  static const VestaFq r = VestaFq.unsafe([
    Uint64.unsafe(1529560732, 4294967293),
    Uint64.unsafe(2569811211, 3812754791),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(1073741823, 4294967295),
  ]);
  static const VestaFq twoInv = VestaFq.unsafe([
    Uint64.unsafe(1941509342, 4294967295),
    Uint64.unsafe(3719915267, 4134229794),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(1073741823, 4294967295),
  ]);
  static const VestaFq delta = VestaFq.unsafe([
    Uint64.unsafe(4272119796, 2129915527),
    Uint64.unsafe(3380792285, 1904204230),
    Uint64.unsafe(220579790, 1354279769),
    Uint64.unsafe(398458188, 3349944257),
  ]);
  static const VestaFq r2 = VestaFq.unsafe([
    Uint64.unsafe(4237719807, 15),
    Uint64.unsafe(1740325693, 2300188387),
    Uint64.unsafe(2142118672, 80541072),
    Uint64.unsafe(158155183, 2093996713),
  ]);
  static const VestaFq r3 = VestaFq.unsafe([
    Uint64.unsafe(9126428, 614313548),
    Uint64.unsafe(3778796112, 3684963110),
    Uint64.unsafe(2298400459, 2383792995),
    Uint64.unsafe(131962784, 1852281544),
  ]);
  static const VestaFq rootOfUnity = VestaFq.unsafe([
    Uint64.unsafe(562067266, 2358854366),
    Uint64.unsafe(3427358601, 565576852),
    Uint64.unsafe(2888719655, 3002056418),
    Uint64.unsafe(192543369, 2133700694),
  ]);
  static const VestaFq rootOfUnityInv = VestaFq.unsafe([
    Uint64.unsafe(3113252669, 600977029),
    Uint64.unsafe(1322160538, 66306066),
    Uint64.unsafe(748341433, 2856035595),
    Uint64.unsafe(911039994, 1129160442),
  ]);
  static const VestaFq zeta = VestaFq.unsafe([
    Uint64.unsafe(2085886596, 2148602146),
    Uint64.unsafe(1080232860, 1458383322),
    Uint64.unsafe(46298619, 324741929),
    Uint64.unsafe(303901176, 2284083984),
  ]);
  static const VestaFq generator = VestaFq.unsafe([
    Uint64.unsafe(2528939148, 4294967277),
    Uint64.unsafe(1958913355, 1240954766),
    Uint64.unsafe(4294967295, 4294967293),
    Uint64.unsafe(1073741823, 4294967295),
  ]);
  static const VestaFq z = VestaFq.unsafe([
    Uint64.unsafe(2120729268, 52),
    Uint64.unsafe(4132901681, 4063382784),
    Uint64.unsafe(0, 6),
    Uint64.zero,
  ]);
  static const VestaFq theta = VestaFq.unsafe([
    Uint64.unsafe(2395716726, 2810631126),
    Uint64.unsafe(3748437398, 1893465761),
    Uint64.unsafe(3997664184, 774091649),
    Uint64.unsafe(697945704, 2140159066),
  ]);
  factory VestaFq.multiplicativeGenerator() => VestaFq.generator;
  @override
  List<int> toBytes() {
    // Reduce from Montgomery form to canonical form
    final tmp = VestaFq.montgomeryReduce(
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

  factory VestaFq.fromBytes(List<int> bytes) {
    if (bytes.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "VestaFq",
        name: "bytes",
        reason: "Invalid field bytes length.",
      );
    }
    // Parse 4 limbs
    final tmpLimbs = List<Uint64>.generate(4, (i) {
      return Uint64.fromBytes(bytes, endian: Endian.little, offset: i * 8);
    });

    final tmp = VestaFq(tmpLimbs);

    // Constant-time check: tmp < modulus
    Uint64 borrow = Uint64.zero;
    (_, borrow) = Uint64.sbb(
      tmp.limbs[0],
      VestaFQConst.modulus.limbs[0],
      Uint64.zero,
    );
    (_, borrow) = Uint64.sbb(
      tmp.limbs[1],
      VestaFQConst.modulus.limbs[1],
      borrow,
    );
    (_, borrow) = Uint64.sbb(
      tmp.limbs[2],
      VestaFQConst.modulus.limbs[2],
      borrow,
    );
    (_, borrow) = Uint64.sbb(
      tmp.limbs[3],
      VestaFQConst.modulus.limbs[3],
      borrow,
    );
    bool isValid = borrow != Uint64.zero;
    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "VestaFq",
        name: "bytes",
        reason: "Invalid field bytes.",
      );
    }
    // Convert to Montgomery form
    return tmp.mul(VestaFq.r2);
  }

  VestaFq mul(VestaFq rhs) {
    // Schoolbook multiplication
    var r0Carry = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[0], Uint64.zero);
    var r0 = r0Carry.$1;
    var carry = r0Carry.$2;

    var r1Carry = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[1], carry);
    var r1 = r1Carry.$1;
    carry = r1Carry.$2;

    var r2Carry = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[2], carry);
    var r2 = r2Carry.$1;
    carry = r2Carry.$2;

    var r3Carry = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[3], carry);
    var r3 = r3Carry.$1;
    var r4 = r3Carry.$2;

    // Second row
    r1Carry = Uint64.mac(r1, limbs[1], rhs.limbs[0], Uint64.zero);
    r1 = r1Carry.$1;
    carry = r1Carry.$2;

    r2Carry = Uint64.mac(r2, limbs[1], rhs.limbs[1], carry);
    r2 = r2Carry.$1;
    carry = r2Carry.$2;

    r3Carry = Uint64.mac(r3, limbs[1], rhs.limbs[2], carry);
    r3 = r3Carry.$1;
    carry = r3Carry.$2;

    var r4Carry = Uint64.mac(r4, limbs[1], rhs.limbs[3], carry);
    r4 = r4Carry.$1;
    var r5 = r4Carry.$2;

    // Third row
    r2Carry = Uint64.mac(r2, limbs[2], rhs.limbs[0], Uint64.zero);
    r2 = r2Carry.$1;
    carry = r2Carry.$2;

    r3Carry = Uint64.mac(r3, limbs[2], rhs.limbs[1], carry);
    r3 = r3Carry.$1;
    carry = r3Carry.$2;

    r4Carry = Uint64.mac(r4, limbs[2], rhs.limbs[2], carry);
    r4 = r4Carry.$1;
    carry = r4Carry.$2;

    var r5Carry = Uint64.mac(r5, limbs[2], rhs.limbs[3], carry);
    r5 = r5Carry.$1;
    var r6 = r5Carry.$2;

    // Fourth row
    r3Carry = Uint64.mac(r3, limbs[3], rhs.limbs[0], Uint64.zero);
    r3 = r3Carry.$1;
    carry = r3Carry.$2;

    r4Carry = Uint64.mac(r4, limbs[3], rhs.limbs[1], carry);
    r4 = r4Carry.$1;
    carry = r4Carry.$2;

    r5Carry = Uint64.mac(r5, limbs[3], rhs.limbs[2], carry);
    r5 = r5Carry.$1;
    carry = r5Carry.$2;

    var r6Carry = Uint64.mac(r6, limbs[3], rhs.limbs[3], carry);
    r6 = r6Carry.$1;
    var r7 = r6Carry.$2;

    return VestaFq.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  VestaFq sub(VestaFq rhs) {
    // Step 1: subtract each limb with borrow
    var s0 = Uint64.sbb(limbs[0], rhs.limbs[0], Uint64.zero);
    var d0 = s0.$1;
    var borrow = s0.$2;

    var s1 = Uint64.sbb(limbs[1], rhs.limbs[1], borrow);
    var d1 = s1.$1;
    borrow = s1.$2;

    var s2 = Uint64.sbb(limbs[2], rhs.limbs[2], borrow);
    var d2 = s2.$1;
    borrow = s2.$2;

    var s3 = Uint64.sbb(limbs[3], rhs.limbs[3], borrow);
    var d3 = s3.$1;
    borrow = s3.$2;

    // Step 2: if underflow occurred, add modulus
    var a0 = Uint64.adc(
      d0,
      VestaFQConst.modulus.limbs[0] & borrow,
      Uint64.zero,
    );
    d0 = a0.$1;
    var carry = a0.$2;

    var a1 = Uint64.adc(d1, VestaFQConst.modulus.limbs[1] & borrow, carry);
    d1 = a1.$1;
    carry = a1.$2;

    var a2 = Uint64.adc(d2, VestaFQConst.modulus.limbs[2] & borrow, carry);
    d2 = a2.$1;
    carry = a2.$2;

    var a3 = Uint64.adc(d3, VestaFQConst.modulus.limbs[3] & borrow, carry);
    d3 = a3.$1;
    // final carry ignored

    return VestaFq([d0, d1, d2, d3]);
  }

  VestaFq add(VestaFq rhs) {
    // Step 1: add limbs with carry
    var a0 = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    var d0 = a0.$1;
    var carry = a0.$2;

    var a1 = Uint64.adc(limbs[1], rhs.limbs[1], carry);
    var d1 = a1.$1;
    carry = a1.$2;

    var a2 = Uint64.adc(limbs[2], rhs.limbs[2], carry);
    var d2 = a2.$1;
    carry = a2.$2;

    var a3 = Uint64.adc(limbs[3], rhs.limbs[3], carry);
    var d3 = a3.$1;
    // final carry ignored

    // Step 2: reduce modulo modulus if necessary
    return VestaFq([d0, d1, d2, d3]).sub(VestaFQConst.modulus);
  }

  VestaFq neg() {
    // Step 1: subtract self from modulus
    var s0 = Uint64.sbb(VestaFQConst.modulus.limbs[0], limbs[0], Uint64.zero);
    var d0 = s0.$1;
    var borrow = s0.$2;

    var s1 = Uint64.sbb(VestaFQConst.modulus.limbs[1], limbs[1], borrow);
    var d1 = s1.$1;
    borrow = s1.$2;

    var s2 = Uint64.sbb(VestaFQConst.modulus.limbs[2], limbs[2], borrow);
    var d2 = s2.$1;
    borrow = s2.$2;

    var s3 = Uint64.sbb(VestaFQConst.modulus.limbs[3], limbs[3], borrow);
    var d3 = s3.$1;
    // final borrow ignored

    // Step 2: create mask: 0 if self == 0, all ones if self != 0
    bool isZero = limbs.every((x) => x == Uint64.zero);
    Uint64 mask = isZero ? Uint64.zero : Uint64.max;

    // Step 3: apply mask to each limb
    return VestaFq([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  @override
  VestaFq square() {
    // Step 1: cross products
    var r1Carry = Uint64.mac(Uint64.zero, limbs[0], limbs[1], Uint64.zero);
    var r1 = r1Carry.$1;
    var carry = r1Carry.$2;

    var r2Carry = Uint64.mac(Uint64.zero, limbs[0], limbs[2], carry);
    var r2 = r2Carry.$1;
    carry = r2Carry.$2;

    var r3Carry = Uint64.mac(Uint64.zero, limbs[0], limbs[3], carry);
    var r3 = r3Carry.$1;
    var r4 = r3Carry.$2;

    var r3Carry2 = Uint64.mac(r3, limbs[1], limbs[2], Uint64.zero);
    r3 = r3Carry2.$1;
    var r4Carry = Uint64.mac(r4, limbs[1], limbs[3], r3Carry2.$2);
    r4 = r4Carry.$1;
    var r5 = r4Carry.$2;

    var r5Carry = Uint64.mac(r5, limbs[2], limbs[3], Uint64.zero);
    r5 = r5Carry.$1;
    var r6 = r5Carry.$2;

    // Step 2: double the cross terms
    var r7 = (r6 >> 63);
    r6 = ((r6 << 1) | (r5 >> 63));
    r5 = ((r5 << 1) | (r4 >> 63));
    r4 = ((r4 << 1) | (r3 >> 63));
    r3 = ((r3 << 1) | (r2 >> 63));
    r2 = ((r2 << 1) | (r1 >> 63));
    r1 = (r1 << 1);
    // Step 3: add squares of limbs
    var r0Carry = Uint64.mac(Uint64.zero, limbs[0], limbs[0], Uint64.zero);
    var r0 = r0Carry.$1;
    carry = r0Carry.$2;

    var r1Adc = Uint64.adc(Uint64.zero, r1, carry);
    r1 = r1Adc.$1;
    carry = r1Adc.$2;

    r2Carry = Uint64.mac(r2, limbs[1], limbs[1], carry);
    r2 = r2Carry.$1;
    carry = r2Carry.$2;

    var r3Adc = Uint64.adc(Uint64.zero, r3, carry);
    r3 = r3Adc.$1;
    carry = r3Adc.$2;

    r4Carry = Uint64.mac(r4, limbs[2], limbs[2], carry);
    r4 = r4Carry.$1;
    carry = r4Carry.$2;

    var r5Adc = Uint64.adc(Uint64.zero, r5, carry);
    r5 = r5Adc.$1;
    carry = r5Adc.$2;

    var r6Carry = Uint64.mac(r6, limbs[3], limbs[3], carry);
    r6 = r6Carry.$1;
    carry = r6Carry.$2;

    var r7Adc = Uint64.adc(Uint64.zero, r7, carry);
    r7 = r7Adc.$1;
    // final carry ignored
    return VestaFq.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  VestaFq pow(List<Uint64> exp) {
    var res = VestaFq.one; // equivalent of Self::ONE
    for (var e in exp.reversed) {
      for (var i = 63; i >= 0; i--) {
        res = res.square();
        // Conditional multiply: if bit i is 1, multiply by base
        var bit = (e >> i) & Uint64.one;
        var tmp = res * this;
        if (bit == Uint64.one) {
          res = tmp;
        }
      }
    }

    return res;
  }

  VestaFq powVarTime(List<Uint64> expWords) {
    var res = VestaFq.one;
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
  VestaFq operator +(VestaFq rhs) => add(rhs);
  @override
  VestaFq operator -(VestaFq rhs) => sub(rhs);
  @override
  VestaFq operator *(VestaFq rhs) => mul(rhs);
  @override
  VestaFq operator -() => neg();

  @override
  int getLower32() {
    final tmp = VestaFq.montgomeryReduce(
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
  VestaFq powByTMinus1Over2() {
    VestaFq sqr(VestaFq x, int i) {
      VestaFq result = x;
      for (int j = 0; j < i; j++) {
        result = result.square();
      }
      return result;
    }

    final s10 = square();

    final s11 = s10 * this;
    final s111 = s11.square() * this;
    final s1001 = s111 * s10;
    final s1011 = s1001 * s10;
    final s1101 = s1011 * s10;
    final sa = sqr(this, 129) * this;
    final sb = sqr(sa, 7) * s1001;
    final sc = sqr(sb, 7) * s1101;
    final sd = sqr(sc, 4) * s11;
    final se = sqr(sd, 6) * s111;
    final sf = sqr(se, 3) * s111;
    final sg = sqr(sf, 10) * s1001;
    final sh = sqr(sg, 4) * s1001;
    final si = sqr(sh, 5) * s1001;
    final sj = sqr(si, 5) * s1001;
    final sk = sqr(sj, 3) * s1001;
    final sl = sqr(sk, 4) * s1011;
    final sm = sqr(sl, 4) * s1011;
    final sn = sqr(sm, 5) * s11;
    final so = sqr(sn, 4) * this;
    final sp = sqr(so, 5) * s11;
    final sq = sqr(sp, 4) * s111;
    final sr = sqr(sq, 5) * s1011;
    final ss = sqr(sr, 3) * this;
    return sqr(ss, 4); // final result
  }

  @override
  bool isZero() {
    return this == VestaFq.zero;
  }

  static FieldSqrtResult<VestaFq> sqrtRatio(VestaFq num, VestaFq div) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: VestaFq.zero,
      rootOfUnity: VestaFq.rootOfUnity,
    );
  }

  static FieldSqrtResult<VestaFq> sqrtAlt(VestaFq r) {
    return PastaUtils.sqrtTonelliShanks(
      f: r,
      fPowTm1d2: r.powByTMinus1Over2(),
      rootOfUnity: VestaFq.rootOfUnity,
      one: VestaFq.one,
      conditionalSelect: VestaFq.conditionalSelect,
      s: VestaFQConst.S,
    );
  }

  @override
  FieldSqrtResult<VestaFq> sqrt() {
    return sqrtAlt(this);
  }

  @override
  VestaFq? invert() {
    if (isZero()) return null;
    const m = [
      Uint64.unsafe(2353457952, 4294967295),
      Uint64.unsafe(575052028, 160737501),
      Uint64.zero,
      Uint64.unsafe(1073741824, 0),
    ];
    final tmp = powVarTime(m);
    return tmp;
  }

  @override
  VestaFq double() {
    return add(this);
  }

  @override
  bool constantEquality(VestaFq other) {
    return Uint64.ctEquals(limbs, other.limbs);
  }

  @override
  VestaFq conditionalSelect(VestaFq a, VestaFq b, bool choice) {
    return VestaFq.conditionalSelect(a, b, choice);
  }

  @override
  FieldSqrtResult<VestaFq> sRatio(VestaFq a, VestaFq b) {
    return sqrtRatio(a, b);
  }
}

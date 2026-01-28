import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/vesta.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class VestaFq extends PastaFieldElement<VestaFq>
    with ConstantEquality<VestaFq> {
  final List<BigInt> limbs;
  VestaFq(List<BigInt> limbs)
    : limbs = limbs.exc(length: 4, operation: "VestaFq").immutable;
  factory VestaFq.zero() =>
      VestaFq([BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]);
  factory VestaFq.fromRaw(List<BigInt> limbs) =>
      VestaFq(limbs).mul(VestaFq.r2());
  factory VestaFq.one() => VestaFq.r();
  factory VestaFq.from(BigInt val) =>
      VestaFq([val, BigInt.zero, BigInt.zero, BigInt.zero]).mul(VestaFq.r2());
  factory VestaFq.conditionalSelect(VestaFq a, VestaFq b, bool choice) {
    return VestaFq([
      BigintUtils.ctSelectBigInt(a.limbs[0], b.limbs[0], choice),
      BigintUtils.ctSelectBigInt(a.limbs[1], b.limbs[1], choice),
      BigintUtils.ctSelectBigInt(a.limbs[2], b.limbs[2], choice),
      BigintUtils.ctSelectBigInt(a.limbs[3], b.limbs[3], choice),
    ]);
  }
  factory VestaFq.fromBytes64(List<int> bytes) {
    bytes = bytes.exc(
      length: 64,
      operation: "fromBytes64",
      reason: "Invalid bytes length.",
    );
    return VestaFq._fromU512([
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
  factory VestaFq.random() {
    return VestaFq._fromU512(List.generate(8, (i) => QuickCrypto.nextU64()));
  }
  factory VestaFq._fromU512(List<BigInt> limbs) {
    assert(limbs.length == 8);

    // Split the 512-bit number into lower and upper 256-bit halves
    final d0 = VestaFq([limbs[0], limbs[1], limbs[2], limbs[3]]);
    final d1 = VestaFq([limbs[4], limbs[5], limbs[6], limbs[7]]);
    // Convert to Montgomery form
    return d0 * VestaFq.r2() + d1 * VestaFq.r3();
  }
  factory VestaFq.fromU128(BigInt v) {
    final lower = v.toU64;
    final upper = (v >> 64).toU64;
    VestaFq tmp = VestaFq.from(upper);
    for (int i = 0; i < 64; i++) {
      tmp = tmp.double();
    }
    return tmp + VestaFq.from(lower);
  }

  factory VestaFq.montgomeryReduce(
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
    BigInt k = r0 * VestaFQConst.inv & BinaryOps.maskBig64;
    var tmp = BigintUtils.mac(
      r0,
      k,
      VestaFQConst.modulus.limbs[0],
      BigInt.zero,
    );
    var carry = tmp[1];
    tmp = BigintUtils.mac(r1, k, VestaFQConst.modulus.limbs[1], carry);
    r1 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r2, k, VestaFQConst.modulus.limbs[2], carry);
    r2 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, VestaFQConst.modulus.limbs[3], carry);
    r3 = tmp[0];
    carry = tmp[1];
    var r4New = BigintUtils.adc(r4, BigInt.zero, carry);
    r4 = r4New[0];
    var carry2 = r4New[1];

    // Step 2
    k = r1 * VestaFQConst.inv & BinaryOps.maskBig64;
    tmp = BigintUtils.mac(r1, k, VestaFQConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r2, k, VestaFQConst.modulus.limbs[1], carry);
    r2 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, VestaFQConst.modulus.limbs[2], carry);
    r3 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, VestaFQConst.modulus.limbs[3], carry);
    r4 = tmp[0];
    carry = tmp[1];
    var r5New = BigintUtils.adc(r5, carry2, carry);
    r5 = r5New[0];
    carry2 = r5New[1];

    // Step 3
    k = r2 * VestaFQConst.inv & BinaryOps.maskBig64;
    tmp = BigintUtils.mac(r2, k, VestaFQConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r3, k, VestaFQConst.modulus.limbs[1], carry);
    r3 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, VestaFQConst.modulus.limbs[2], carry);
    r4 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r5, k, VestaFQConst.modulus.limbs[3], carry);
    r5 = tmp[0];
    carry = tmp[1];
    var r6New = BigintUtils.adc(r6, carry2, carry);
    r6 = r6New[0];
    carry2 = r6New[1];

    // Step 4
    k = r3 * VestaFQConst.inv & BinaryOps.maskBig64;
    tmp = BigintUtils.mac(r3, k, VestaFQConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];
    tmp = BigintUtils.mac(r4, k, VestaFQConst.modulus.limbs[1], carry);
    r4 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r5, k, VestaFQConst.modulus.limbs[2], carry);
    r5 = tmp[0];
    carry = tmp[1];
    tmp = BigintUtils.mac(r6, k, VestaFQConst.modulus.limbs[3], carry);
    r6 = tmp[0];
    carry = tmp[1];
    var r7New = BigintUtils.adc(r7, carry2, carry);
    r7 = r7New[0];
    // final carry ignored

    // Result may be within modulus of the correct value
    return VestaFq([r4, r5, r6, r7]).sub(VestaFQConst.modulus);
  }

  factory VestaFq.rootOfUnityInv() => VestaFq.fromRaw([
    BigInt.parse("0x57eecda0a84b6836"),
    BigInt.parse("0x4ad38b9084b8a80c"),
    BigInt.parse("0xf4c8f353124086c1"),
    BigInt.parse("0x2235e1a7415bf936"),
  ]);
  factory VestaFq.twoInv() => VestaFq.fromRaw([
    BigInt.parse("0xc623759080000001"),
    BigInt.parse("0x11234c7e04ca546e"),
    BigInt.zero,
    BigInt.parse("0x2000000000000000"),
  ]);
  factory VestaFq.delta() => VestaFq.fromRaw([
    BigInt.parse("0x8494392472d1683c"),
    BigInt.parse("0xe3ac3376541d1140"),
    BigInt.parse("0x06f0a88e7f7949f8"),
    BigInt.parse("0x2237d54423724166"),
  ]);
  factory VestaFq.rootOfUnity() => VestaFq.fromRaw([
    BigInt.parse("0xa70e2c1102b6d05f"),
    BigInt.parse("0x9bb97ea3c106f049"),
    BigInt.parse("0x9e5c4dfd492ae26e"),
    BigInt.parse("0x2de6a9b8746d3f58"),
  ]);
  factory VestaFq.generator() => VestaFq.fromRaw([
    BigInt.parse('0x0000000000000005'),
    BigInt.zero,
    BigInt.zero,
    BigInt.zero,
  ]);
  factory VestaFq.zeta() => VestaFq.fromRaw([
    BigInt.parse("0x2aa9d2e050aa0e4f"),
    BigInt.parse("0x0fed467d47c033af"),
    BigInt.parse("0x511db4d81cf70f5a"),
    BigInt.parse("0x06819a58283e528e"),
  ]);
  factory VestaFq.r3() => VestaFq([
    BigInt.parse('0x008b421c249dae4c'),
    BigInt.parse('0xe13bda50dba41326'),
    BigInt.parse('0x88fececb8e15cb63'),
    BigInt.parse('0x07dd97a06e6792c8'),
  ]);
  factory VestaFq.r2() => VestaFq([
    BigInt.parse('0xfc9678ff0000000f'),
    BigInt.parse('0x67bb433d891a16e3'),
    BigInt.parse('0x7fae231004ccf590'),
    BigInt.parse('0x096d41af7ccfdaa9'),
  ]);
  factory VestaFq.r() => VestaFq([
    BigInt.parse('0x5b2b3e9cfffffffd'),
    BigInt.parse('0x992c350be3420567'),
    BigInt.parse('0xffffffffffffffff'),
    BigInt.parse('0x3fffffffffffffff'),
  ]);
  factory VestaFq.theta() => VestaFq.fromRaw([
    BigInt.parse("0x632cae9872df1b5d"),
    BigInt.parse("0x38578ccadf03ac27"),
    BigInt.parse("0x53c3808d9e2f2357"),
    BigInt.parse("0x2b3483a1ee9a382f"),
  ]);
  factory VestaFq.z() => VestaFq.fromRaw([
    BigInt.parse("0x8c46eb20fffffff4"),
    BigInt.parse("0x224698fc0994a8dd"),
    BigInt.parse("0x0000000000000000"),
    BigInt.parse("0x4000000000000000"),
  ]);
  factory VestaFq.multiplicativeGenerator() => VestaFq.generator();
  @override
  List<int> toBytes() {
    // Reduce from Montgomery form to canonical form
    final tmp = VestaFq.montgomeryReduce(
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
      final limbBytes = BigintUtils.toBytes(
        tmp.limbs[i],
        length: 8,
        order: Endian.little,
      );
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
        expecteLen: 32,
      );
    }
    // Parse 4 limbs
    final tmpLimbs = List<BigInt>.generate(4, (i) {
      return BigintUtils.fromBytes(
        bytes.sublist(i * 8, (i * 8) + 8),
        byteOrder: Endian.little,
      );
    });

    final tmp = VestaFq(tmpLimbs);

    // Constant-time check: tmp < modulus
    BigInt borrow = BigInt.zero;
    for (int i = 0; i < 4; i++) {
      borrow = tmp.limbs[i] - VestaFQConst.modulus.limbs[i] - borrow;
      borrow = borrow.isNegative ? BigInt.one : BigInt.zero;
    }
    bool isValid = borrow != BigInt.zero;
    if (!isValid) {
      throw ArgumentException.invalidOperationArguments(
        "VestaFq",
        name: "bytes",
        reason: "Invalid field bytes.",
      );
    }

    // Convert to Montgomery form
    return tmp.mul(VestaFq.r2());
  }

  VestaFq mul(VestaFq rhs) {
    // Schoolbook multiplication
    var r0Carry = BigintUtils.mac(
      BigInt.zero,
      limbs[0],
      rhs.limbs[0],
      BigInt.zero,
    );
    var r0 = r0Carry[0];
    var carry = r0Carry[1];

    var r1Carry = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[1], carry);
    var r1 = r1Carry[0];
    carry = r1Carry[1];

    var r2Carry = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[2], carry);
    var r2 = r2Carry[0];
    carry = r2Carry[1];

    var r3Carry = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[3], carry);
    var r3 = r3Carry[0];
    var r4 = r3Carry[1];

    // Second row
    r1Carry = BigintUtils.mac(r1, limbs[1], rhs.limbs[0], BigInt.zero);
    r1 = r1Carry[0];
    carry = r1Carry[1];

    r2Carry = BigintUtils.mac(r2, limbs[1], rhs.limbs[1], carry);
    r2 = r2Carry[0];
    carry = r2Carry[1];

    r3Carry = BigintUtils.mac(r3, limbs[1], rhs.limbs[2], carry);
    r3 = r3Carry[0];
    carry = r3Carry[1];

    var r4Carry = BigintUtils.mac(r4, limbs[1], rhs.limbs[3], carry);
    r4 = r4Carry[0];
    var r5 = r4Carry[1];

    // Third row
    r2Carry = BigintUtils.mac(r2, limbs[2], rhs.limbs[0], BigInt.zero);
    r2 = r2Carry[0];
    carry = r2Carry[1];

    r3Carry = BigintUtils.mac(r3, limbs[2], rhs.limbs[1], carry);
    r3 = r3Carry[0];
    carry = r3Carry[1];

    r4Carry = BigintUtils.mac(r4, limbs[2], rhs.limbs[2], carry);
    r4 = r4Carry[0];
    carry = r4Carry[1];

    var r5Carry = BigintUtils.mac(r5, limbs[2], rhs.limbs[3], carry);
    r5 = r5Carry[0];
    var r6 = r5Carry[1];

    // Fourth row
    r3Carry = BigintUtils.mac(r3, limbs[3], rhs.limbs[0], BigInt.zero);
    r3 = r3Carry[0];
    carry = r3Carry[1];

    r4Carry = BigintUtils.mac(r4, limbs[3], rhs.limbs[1], carry);
    r4 = r4Carry[0];
    carry = r4Carry[1];

    r5Carry = BigintUtils.mac(r5, limbs[3], rhs.limbs[2], carry);
    r5 = r5Carry[0];
    carry = r5Carry[1];

    var r6Carry = BigintUtils.mac(r6, limbs[3], rhs.limbs[3], carry);
    r6 = r6Carry[0];
    var r7 = r6Carry[1];

    return VestaFq.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  VestaFq sub(VestaFq rhs) {
    // Step 1: subtract each limb with borrow
    var s0 = BigintUtils.sbb(limbs[0], rhs.limbs[0], BigInt.zero);
    var d0 = s0[0];
    var borrow = s0[1];

    var s1 = BigintUtils.sbb(limbs[1], rhs.limbs[1], borrow);
    var d1 = s1[0];
    borrow = s1[1];

    var s2 = BigintUtils.sbb(limbs[2], rhs.limbs[2], borrow);
    var d2 = s2[0];
    borrow = s2[1];

    var s3 = BigintUtils.sbb(limbs[3], rhs.limbs[3], borrow);
    var d3 = s3[0];
    borrow = s3[1];

    // Step 2: if underflow occurred, add modulus
    var a0 = BigintUtils.adc(
      d0,
      VestaFQConst.modulus.limbs[0] & borrow,
      BigInt.zero,
    );
    d0 = a0[0];
    var carry = a0[1];

    var a1 = BigintUtils.adc(d1, VestaFQConst.modulus.limbs[1] & borrow, carry);
    d1 = a1[0];
    carry = a1[1];

    var a2 = BigintUtils.adc(d2, VestaFQConst.modulus.limbs[2] & borrow, carry);
    d2 = a2[0];
    carry = a2[1];

    var a3 = BigintUtils.adc(d3, VestaFQConst.modulus.limbs[3] & borrow, carry);
    d3 = a3[0];
    // final carry ignored

    return VestaFq([d0, d1, d2, d3]);
  }

  VestaFq add(VestaFq rhs) {
    // Step 1: add limbs with carry
    var a0 = BigintUtils.adc(limbs[0], rhs.limbs[0], BigInt.zero);
    var d0 = a0[0];
    var carry = a0[1];

    var a1 = BigintUtils.adc(limbs[1], rhs.limbs[1], carry);
    var d1 = a1[0];
    carry = a1[1];

    var a2 = BigintUtils.adc(limbs[2], rhs.limbs[2], carry);
    var d2 = a2[0];
    carry = a2[1];

    var a3 = BigintUtils.adc(limbs[3], rhs.limbs[3], carry);
    var d3 = a3[0];
    // final carry ignored

    // Step 2: reduce modulo modulus if necessary
    return VestaFq([d0, d1, d2, d3]).sub(VestaFQConst.modulus);
  }

  VestaFq neg() {
    // Step 1: subtract self from modulus
    var s0 = BigintUtils.sbb(
      VestaFQConst.modulus.limbs[0],
      limbs[0],
      BigInt.zero,
    );
    var d0 = s0[0];
    var borrow = s0[1];

    var s1 = BigintUtils.sbb(VestaFQConst.modulus.limbs[1], limbs[1], borrow);
    var d1 = s1[0];
    borrow = s1[1];

    var s2 = BigintUtils.sbb(VestaFQConst.modulus.limbs[2], limbs[2], borrow);
    var d2 = s2[0];
    borrow = s2[1];

    var s3 = BigintUtils.sbb(VestaFQConst.modulus.limbs[3], limbs[3], borrow);
    var d3 = s3[0];
    // final borrow ignored

    // Step 2: create mask: 0 if self == 0, all ones if self != 0
    bool isZero = limbs.every((x) => x == BigInt.zero);
    BigInt mask = isZero ? BigInt.zero : BigInt.parse('0xFFFFFFFFFFFFFFFF');

    // Step 3: apply mask to each limb
    return VestaFq([d0 & mask, d1 & mask, d2 & mask, d3 & mask]);
  }

  @override
  VestaFq square() {
    // Step 1: cross products
    var r1Carry = BigintUtils.mac(BigInt.zero, limbs[0], limbs[1], BigInt.zero);
    var r1 = r1Carry[0];
    var carry = r1Carry[1];

    var r2Carry = BigintUtils.mac(BigInt.zero, limbs[0], limbs[2], carry);
    var r2 = r2Carry[0];
    carry = r2Carry[1];

    var r3Carry = BigintUtils.mac(BigInt.zero, limbs[0], limbs[3], carry);
    var r3 = r3Carry[0];
    var r4 = r3Carry[1];

    var r3Carry2 = BigintUtils.mac(r3, limbs[1], limbs[2], BigInt.zero);
    r3 = r3Carry2[0];
    var r4Carry = BigintUtils.mac(r4, limbs[1], limbs[3], r3Carry2[1]);
    r4 = r4Carry[0];
    var r5 = r4Carry[1];

    var r5Carry = BigintUtils.mac(r5, limbs[2], limbs[3], BigInt.zero);
    r5 = r5Carry[0];
    var r6 = r5Carry[1];

    // Step 2: double the cross terms
    var r7 = (r6 >> 63).toU64;
    r6 = ((r6 << 1) | (r5 >> 63)).toU64;
    r5 = ((r5 << 1) | (r4 >> 63)).toU64;
    r4 = ((r4 << 1) | (r3 >> 63)).toU64;
    r3 = ((r3 << 1) | (r2 >> 63)).toU64;
    r2 = ((r2 << 1) | (r1 >> 63)).toU64;
    r1 = (r1 << 1).toU64;
    // Step 3: add squares of limbs
    var r0Carry = BigintUtils.mac(BigInt.zero, limbs[0], limbs[0], BigInt.zero);
    var r0 = r0Carry[0];
    carry = r0Carry[1];

    var r1Adc = BigintUtils.adc(BigInt.zero, r1, carry);
    r1 = r1Adc[0];
    carry = r1Adc[1];

    r2Carry = BigintUtils.mac(r2, limbs[1], limbs[1], carry);
    r2 = r2Carry[0];
    carry = r2Carry[1];

    var r3Adc = BigintUtils.adc(BigInt.zero, r3, carry);
    r3 = r3Adc[0];
    carry = r3Adc[1];

    r4Carry = BigintUtils.mac(r4, limbs[2], limbs[2], carry);
    r4 = r4Carry[0];
    carry = r4Carry[1];

    var r5Adc = BigintUtils.adc(BigInt.zero, r5, carry);
    r5 = r5Adc[0];
    carry = r5Adc[1];

    var r6Carry = BigintUtils.mac(r6, limbs[3], limbs[3], carry);
    r6 = r6Carry[0];
    carry = r6Carry[1];

    var r7Adc = BigintUtils.adc(BigInt.zero, r7, carry);
    r7 = r7Adc[0];
    // final carry ignored
    return VestaFq.montgomeryReduce(r0, r1, r2, r3, r4, r5, r6, r7);
  }

  VestaFq pow(List<BigInt> exp) {
    var res = VestaFq.one(); // equivalent of Self::ONE
    for (var e in exp.reversed) {
      for (var i = 63; i >= 0; i--) {
        res = res.square();
        // Conditional multiply: if bit i is 1, multiply by base
        var bit = (e >> i) & BigInt.one;
        var tmp = res * this;
        if (bit == BigInt.one) {
          res = tmp;
        }
      }
    }

    return res;
  }

  VestaFq powVarTime(List<BigInt> expWords) {
    var res = VestaFq.one();
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
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    );
    return tmp.limbs[0].toU32;
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
    return this == VestaFq.zero();
  }

  static FieldSqrtResult<VestaFq> sqrtRatio(VestaFq num, VestaFq div) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: VestaFq.zero(),
      rootOfUnity: VestaFq.rootOfUnity(),
    );
  }

  static FieldSqrtResult<VestaFq> sqrtAlt(VestaFq r) {
    return PastaUtils.sqrtTonelliShanks(
      f: r,
      fPowTm1d2: r.powByTMinus1Over2(),
      rootOfUnity: VestaFq.rootOfUnity(),
      one: VestaFq.one(),
      conditionalSelect: VestaFq.conditionalSelect,
    );
  }

  @override
  FieldSqrtResult<VestaFq> sqrt() {
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powByTMinus1Over2(),
      rootOfUnity: VestaFq.rootOfUnity(),
      one: VestaFq.one(),
      conditionalSelect: conditionalSelect,
    );
  }

  @override
  VestaFq? invert() {
    if (isZero()) return null;
    final tmp = powVarTime([
      BigInt.parse("0x8c46eb20ffffffff"),
      BigInt.parse("0x224698fc0994a8dd"),
      BigInt.parse("0x0"),
      BigInt.parse("0x4000000000000000"),
    ]);
    return tmp;
  }

  @override
  VestaFq double() {
    return add(this);
  }

  @override
  bool constantEquality(VestaFq other) {
    return CompareUtils.constantTimeBigIntEquals(limbs, other.limbs);
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

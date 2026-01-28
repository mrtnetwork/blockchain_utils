import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class Bls12FpConst {
  static BigInt get inv => BigInt.parse("0x89f3fffcfffcfffd");
  static final modulus = Bls12Fp([
    BigInt.parse('0xb9feffffffffaaab'),
    BigInt.parse('0x1eabfffeb153ffff'),
    BigInt.parse('0x6730d2a0f6b0f624'),
    BigInt.parse('0x64774b84f38512bf'),
    BigInt.parse('0x4b1ba7b6434bacd7'),
    BigInt.parse('0x1a0111ea397fe69a'),
  ]);
  static final p = BigInt.parse(
    "4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787",
  );
}

class Bls12Fp extends BlsField<Bls12Fp> with ConstantEquality<Bls12Fp> {
  final List<BigInt> limbs;
  Bls12Fp(List<BigInt> limbs)
    : limbs = limbs.exc(length: 6, operation: "Bls12Fp").immutable;

  factory Bls12Fp.montgomeryReduce(
    BigInt t0,
    BigInt t1,
    BigInt t2,
    BigInt t3,
    BigInt t4,
    BigInt t5,
    BigInt t6,
    BigInt t7,
    BigInt t8,
    BigInt t9,
    BigInt t10,
    BigInt t11,
  ) {
    final inv = Bls12FpConst.inv;
    // --- 1st iteration --------------------------------------------------------
    BigInt k = (t0 * inv).toU64;
    List<BigInt> tmp = BigintUtils.mac(
      t0,
      k,
      Bls12FpConst.modulus.limbs[0],
      BigInt.zero,
    );
    BigInt carry = tmp[1];

    tmp = BigintUtils.mac(t1, k, Bls12FpConst.modulus.limbs[1], carry);
    BigInt r1 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t2, k, Bls12FpConst.modulus.limbs[2], carry);
    BigInt r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t3, k, Bls12FpConst.modulus.limbs[3], carry);
    BigInt r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t4, k, Bls12FpConst.modulus.limbs[4], carry);
    BigInt r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t5, k, Bls12FpConst.modulus.limbs[5], carry);
    BigInt r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t6, BigInt.zero, carry);
    BigInt r6 = tmp[0];
    BigInt r7 = tmp[1];

    // --- 2nd iteration --------------------------------------------------------
    k = (r1 * inv).toU64;

    tmp = BigintUtils.mac(r1, k, Bls12FpConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];

    tmp = BigintUtils.mac(r2, k, Bls12FpConst.modulus.limbs[1], carry);
    r2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r3, k, Bls12FpConst.modulus.limbs[2], carry);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, k, Bls12FpConst.modulus.limbs[3], carry);
    r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r5, k, Bls12FpConst.modulus.limbs[4], carry);
    r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, k, Bls12FpConst.modulus.limbs[5], carry);
    r6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t7, r7, carry);
    r7 = tmp[0];
    BigInt r8 = tmp[1];

    // --- 3rd iteration --------------------------------------------------------
    k = (r2 * inv).toU64;

    tmp = BigintUtils.mac(r2, k, Bls12FpConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];

    tmp = BigintUtils.mac(r3, k, Bls12FpConst.modulus.limbs[1], carry);
    r3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, k, Bls12FpConst.modulus.limbs[2], carry);
    r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r5, k, Bls12FpConst.modulus.limbs[3], carry);
    r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, k, Bls12FpConst.modulus.limbs[4], carry);
    r6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r7, k, Bls12FpConst.modulus.limbs[5], carry);
    r7 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t8, r8, carry);
    r8 = tmp[0];
    BigInt r9 = tmp[1];

    // --- 4th iteration --------------------------------------------------------
    k = (r3 * inv).toU64;

    tmp = BigintUtils.mac(r3, k, Bls12FpConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];

    tmp = BigintUtils.mac(r4, k, Bls12FpConst.modulus.limbs[1], carry);
    r4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r5, k, Bls12FpConst.modulus.limbs[2], carry);
    r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, k, Bls12FpConst.modulus.limbs[3], carry);
    r6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r7, k, Bls12FpConst.modulus.limbs[4], carry);
    r7 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r8, k, Bls12FpConst.modulus.limbs[5], carry);
    r8 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t9, r9, carry);
    r9 = tmp[0];
    BigInt r10 = tmp[1];

    // --- 5th iteration --------------------------------------------------------
    k = (r4 * inv).toU64;

    tmp = BigintUtils.mac(r4, k, Bls12FpConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];

    tmp = BigintUtils.mac(r5, k, Bls12FpConst.modulus.limbs[1], carry);
    r5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, k, Bls12FpConst.modulus.limbs[2], carry);
    r6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r7, k, Bls12FpConst.modulus.limbs[3], carry);
    r7 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r8, k, Bls12FpConst.modulus.limbs[4], carry);
    r8 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r9, k, Bls12FpConst.modulus.limbs[5], carry);
    r9 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t10, r10, carry);
    r10 = tmp[0];
    BigInt r11 = tmp[1];

    // --- 6th iteration --------------------------------------------------------
    k = (r5 * inv).toU64;

    tmp = BigintUtils.mac(r5, k, Bls12FpConst.modulus.limbs[0], BigInt.zero);
    carry = tmp[1];

    tmp = BigintUtils.mac(r6, k, Bls12FpConst.modulus.limbs[1], carry);
    r6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r7, k, Bls12FpConst.modulus.limbs[2], carry);
    r7 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r8, k, Bls12FpConst.modulus.limbs[3], carry);
    r8 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r9, k, Bls12FpConst.modulus.limbs[4], carry);
    r9 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(r10, k, Bls12FpConst.modulus.limbs[5], carry);
    r10 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t11, r11, carry);
    r11 = tmp[0];

    // Final reduce: subtract modulus
    return Bls12Fp([r6, r7, r8, r9, r10, r11]).subtractP();
  }
  factory Bls12Fp.zero() => Bls12Fp(List.filled(6, BigInt.zero));
  factory Bls12Fp.r2() {
    return Bls12Fp([
      BigInt.parse('0xf4df1f341c341746'),
      BigInt.parse('0x0a76e6a609d104f1'),
      BigInt.parse('0x8de5476c4c95b6d5'),
      BigInt.parse('0x67eb88a9939d83c0'),
      BigInt.parse('0x9a793e85b519952d'),
      BigInt.parse('0x11988fe592cae3aa'),
    ]);
  }
  factory Bls12Fp.one() {
    return Bls12Fp([
      BigInt.parse('0x760900000002fffd'),
      BigInt.parse('0xebf4000bc40c0002'),
      BigInt.parse('0x5f48985753c758ba'),
      BigInt.parse('0x77ce585370525745'),
      BigInt.parse('0x5c071a97a256ec6d'),
      BigInt.parse('0x15f65ec3fa80e493'),
    ]);
  }
  factory Bls12Fp.b() {
    return Bls12Fp([
      BigInt.parse('0xaa270000000cfff3'),
      BigInt.parse('0x53cc0032fc34000a'),
      BigInt.parse('0x478fe97a6b0a807f'),
      BigInt.parse('0xb1d37ebee6ba24d7'),
      BigInt.parse('0x8ec9733bbf78ab2f'),
      BigInt.parse('0x09d645513d83de7e'),
    ]);
  }
  factory Bls12Fp.beta() {
    return Bls12Fp([
      BigInt.parse('0x30f1361b798a64e8'),
      BigInt.parse('0xf3b8ddab7ece5a2a'),
      BigInt.parse('0x16a8ca3ac61577f7'),
      BigInt.parse('0xc26a2ff874fd029b'),
      BigInt.parse('0x3636b76660701c6e'),
      BigInt.parse('0x051ba4ab241b6160'),
    ]);
  }
  factory Bls12Fp.fromBytes(List<int> bytes) {
    if (bytes.length != 48) {
      throw ArgumentException.invalidOperationArguments(
        "Bls12Fp",
        reason: "Invalid field bytes length.",
      );
    }
    final tmp = Bls12Fp([
      BigintUtils.fromBytes(bytes.sublist(40), byteOrder: Endian.big),
      BigintUtils.fromBytes(bytes.sublist(32, 40), byteOrder: Endian.big),
      BigintUtils.fromBytes(bytes.sublist(24, 32), byteOrder: Endian.big),
      BigintUtils.fromBytes(bytes.sublist(16, 24), byteOrder: Endian.big),
      BigintUtils.fromBytes(bytes.sublist(8, 16), byteOrder: Endian.big),
      BigintUtils.fromBytes(bytes.sublist(0, 8), byteOrder: Endian.big),
    ]);
    BigInt borrow = BigInt.zero;
    List<BigInt> temp = BigintUtils.sbb(
      tmp.limbs[0],
      Bls12FpConst.modulus.limbs[0],
      borrow,
    );
    borrow = temp[1];
    temp = BigintUtils.sbb(tmp.limbs[1], Bls12FpConst.modulus.limbs[1], borrow);
    borrow = temp[1];
    temp = BigintUtils.sbb(tmp.limbs[2], Bls12FpConst.modulus.limbs[2], borrow);
    borrow = temp[1];
    temp = BigintUtils.sbb(tmp.limbs[3], Bls12FpConst.modulus.limbs[3], borrow);
    borrow = temp[1];
    temp = BigintUtils.sbb(tmp.limbs[4], Bls12FpConst.modulus.limbs[4], borrow);
    borrow = temp[1];
    temp = BigintUtils.sbb(tmp.limbs[5], Bls12FpConst.modulus.limbs[5], borrow);
    borrow = temp[1];
    // final result = tmp * Bls12FpConst.r2;
    if ((borrow & BigInt.one) != BigInt.one) {
      throw ArgumentException.invalidOperationArguments(
        "Bls12Fp",
        reason: "Invalid field encoding bytes.",
      );
    }
    return tmp * Bls12Fp.r2();
  }
  factory Bls12Fp.sumOfProducts(List<Bls12Fp> a, List<Bls12Fp> b) {
    final int length = a.length;
    List<BigInt> u = List.filled(6, BigInt.zero);

    for (int j = 0; j < 6; j++) {
      // Accumulate products for limb j
      List<BigInt> t = [...u, BigInt.zero]; // t0..t5 + t6
      for (int i = 0; i < length; i++) {
        var res = BigintUtils.mac(
          t[0],
          a[i].limbs[j],
          b[i].limbs[0],
          BigInt.zero,
        );
        t[0] = res[0];
        BigInt carry = res[1];

        res = BigintUtils.mac(t[1], a[i].limbs[j], b[i].limbs[1], carry);
        t[1] = res[0];
        carry = res[1];

        res = BigintUtils.mac(t[2], a[i].limbs[j], b[i].limbs[2], carry);
        t[2] = res[0];
        carry = res[1];

        res = BigintUtils.mac(t[3], a[i].limbs[j], b[i].limbs[3], carry);
        t[3] = res[0];
        carry = res[1];

        res = BigintUtils.mac(t[4], a[i].limbs[j], b[i].limbs[4], carry);
        t[4] = res[0];
        carry = res[1];

        res = BigintUtils.mac(t[5], a[i].limbs[j], b[i].limbs[5], carry);
        t[5] = res[0];
        carry = res[1];

        res = BigintUtils.adc(t[6], BigInt.zero, carry);
        t[6] = res[0];
      }

      // Montgomery reduction step
      final k = (t[0] * Bls12FpConst.inv).toU64;
      var carry = BigInt.zero;
      var r = List<BigInt>.filled(6, BigInt.zero);

      var res = BigintUtils.mac(
        t[0],
        k,
        Bls12FpConst.modulus.limbs[0],
        BigInt.zero,
      );
      carry = res[1];

      res = BigintUtils.mac(t[1], k, Bls12FpConst.modulus.limbs[1], carry);
      r[0] = res[0];
      carry = res[1];

      res = BigintUtils.mac(t[2], k, Bls12FpConst.modulus.limbs[2], carry);
      r[1] = res[0];
      carry = res[1];

      res = BigintUtils.mac(t[3], k, Bls12FpConst.modulus.limbs[3], carry);
      r[2] = res[0];
      carry = res[1];

      res = BigintUtils.mac(t[4], k, Bls12FpConst.modulus.limbs[4], carry);
      r[3] = res[0];
      carry = res[1];

      res = BigintUtils.mac(t[5], k, Bls12FpConst.modulus.limbs[5], carry);
      r[4] = res[0];
      carry = res[1];

      res = BigintUtils.adc(t[6], BigInt.zero, carry);
      r[5] = res[0];

      u = r;
    }

    return Bls12Fp(u).subtractP();
  }

  factory Bls12Fp.conditionalSelect(Bls12Fp a, Bls12Fp b, bool choice) {
    return Bls12Fp([
      BigintUtils.ctSelectBigInt(a.limbs[0], b.limbs[0], choice),
      BigintUtils.ctSelectBigInt(a.limbs[1], b.limbs[1], choice),
      BigintUtils.ctSelectBigInt(a.limbs[2], b.limbs[2], choice),
      BigintUtils.ctSelectBigInt(a.limbs[3], b.limbs[3], choice),
      BigintUtils.ctSelectBigInt(a.limbs[4], b.limbs[4], choice),
      BigintUtils.ctSelectBigInt(a.limbs[5], b.limbs[5], choice),
    ]);
  }

  Bls12Fp subtractP() {
    var tmp = BigintUtils.sbb(
      limbs[0],
      Bls12FpConst.modulus.limbs[0],
      BigInt.zero,
    );
    BigInt r0 = tmp[0];
    BigInt borrow = tmp[1];

    tmp = BigintUtils.sbb(limbs[1], Bls12FpConst.modulus.limbs[1], borrow);
    BigInt r1 = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(limbs[2], Bls12FpConst.modulus.limbs[2], borrow);
    BigInt r2 = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(limbs[3], Bls12FpConst.modulus.limbs[3], borrow);
    BigInt r3 = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(limbs[4], Bls12FpConst.modulus.limbs[4], borrow);
    BigInt r4 = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(limbs[5], Bls12FpConst.modulus.limbs[5], borrow);
    BigInt r5 = tmp[0];
    borrow = tmp[1];

    r0 = ((limbs[0] & borrow) | (r0 & ~borrow)).toU64;
    r1 = ((limbs[1] & borrow) | (r1 & ~borrow)).toU64;
    r2 = ((limbs[2] & borrow) | (r2 & ~borrow)).toU64;
    r3 = ((limbs[3] & borrow) | (r3 & ~borrow)).toU64;
    r4 = ((limbs[4] & borrow) | (r4 & ~borrow)).toU64;
    r5 = ((limbs[5] & borrow) | (r5 & ~borrow)).toU64;

    return Bls12Fp([r0, r1, r2, r3, r4, r5]);
  }

  @override
  Bls12Fp square() {
    var tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[1], BigInt.zero);
    BigInt t1 = tmp[0];
    BigInt carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[2], carry);
    BigInt t2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[3], carry);
    BigInt t3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[4], carry);
    BigInt t4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[5], carry);
    BigInt t5 = tmp[0];
    BigInt t6 = tmp[1];

    tmp = BigintUtils.mac(t3, limbs[1], limbs[2], BigInt.zero);
    t3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t4, limbs[1], limbs[3], carry);
    t4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t5, limbs[1], limbs[4], carry);
    t5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t6, limbs[1], limbs[5], carry);
    t6 = tmp[0];
    BigInt t7 = tmp[1];

    ///
    tmp = BigintUtils.mac(t5, limbs[2], limbs[3], BigInt.zero);
    t5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t6, limbs[2], limbs[4], carry);
    t6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t7, limbs[2], limbs[5], carry);
    t7 = tmp[0];
    BigInt t8 = tmp[1];
    //
    tmp = BigintUtils.mac(t7, limbs[3], limbs[4], BigInt.zero);
    t7 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t8, limbs[3], limbs[5], carry);
    t8 = tmp[0];
    BigInt t9 = tmp[1];

    tmp = BigintUtils.mac(t9, limbs[4], limbs[5], BigInt.zero);
    t9 = tmp[0];
    BigInt t10 = tmp[1];

    // Double the cross products
    BigInt t11 = (t10 >> 63).toU64;
    t10 = ((t10 << 1) | (t9 >> 63)).toU64;
    t9 = ((t9 << 1) | (t8 >> 63)).toU64;
    t8 = ((t8 << 1) | (t7 >> 63)).toU64;
    t7 = ((t7 << 1) | (t6 >> 63)).toU64;
    t6 = ((t6 << 1) | (t5 >> 63)).toU64;
    t5 = ((t5 << 1) | (t4 >> 63)).toU64;
    t4 = ((t4 << 1) | (t3 >> 63)).toU64;
    t3 = ((t3 << 1) | (t2 >> 63)).toU64;
    t2 = ((t2 << 1) | (t1 >> 63)).toU64;
    t1 = (t1 << 1).toU64;

    // Square the limbs and accumulate
    tmp = BigintUtils.mac(BigInt.zero, limbs[0], limbs[0], BigInt.zero);
    BigInt t0 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t1, BigInt.zero, carry);
    t1 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t2, limbs[1], limbs[1], carry);
    t2 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t3, BigInt.zero, carry);
    t3 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t4, limbs[2], limbs[2], carry);
    t4 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t5, BigInt.zero, carry);
    t5 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t6, limbs[3], limbs[3], carry);
    t6 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t7, BigInt.zero, carry);
    t7 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t8, limbs[4], limbs[4], carry);
    t8 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t9, BigInt.zero, carry);
    t9 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t10, limbs[5], limbs[5], carry);
    t10 = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(t11, BigInt.zero, carry);
    t11 = tmp[0];
    // final carry ignored
    // --- Montgomery reduction -------------------------------------------------
    return Bls12Fp.montgomeryReduce(
      t0,
      t1,
      t2,
      t3,
      t4,
      t5,
      t6,
      t7,
      t8,
      t9,
      t10,
      t11,
    );
  }

  Bls12Fp sub(Bls12Fp rhs) {
    return rhs.neg().add(this);
  }

  Bls12Fp mul(Bls12Fp rhs) {
    // --- initialize t0..t11 --------------------------------------------------
    List<BigInt> t = List.filled(12, BigInt.zero);

    // 1st row: self.limbs[0] * rhs.limbs[0..5]
    List<BigInt> tmp = BigintUtils.mac(
      BigInt.zero,
      limbs[0],
      rhs.limbs[0],
      BigInt.zero,
    );
    t[0] = tmp[0];
    BigInt carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[1], carry);
    t[1] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[2], carry);
    t[2] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[3], carry);
    t[3] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[4], carry);
    t[4] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(BigInt.zero, limbs[0], rhs.limbs[5], carry);
    t[5] = tmp[0];
    t[6] = tmp[1];

    // 2nd row: self.limbs[1] * rhs.limbs[0..5]
    tmp = BigintUtils.mac(t[1], limbs[1], rhs.limbs[0], BigInt.zero);
    t[1] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[2], limbs[1], rhs.limbs[1], carry);
    t[2] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[3], limbs[1], rhs.limbs[2], carry);
    t[3] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[4], limbs[1], rhs.limbs[3], carry);
    t[4] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[5], limbs[1], rhs.limbs[4], carry);
    t[5] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[6], limbs[1], rhs.limbs[5], carry);
    t[6] = tmp[0];
    t[7] = tmp[1];

    // 3rd row: self.limbs[2] * rhs.limbs[0..5]
    tmp = BigintUtils.mac(t[2], limbs[2], rhs.limbs[0], BigInt.zero);
    t[2] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[3], limbs[2], rhs.limbs[1], carry);
    t[3] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[4], limbs[2], rhs.limbs[2], carry);
    t[4] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[5], limbs[2], rhs.limbs[3], carry);
    t[5] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[6], limbs[2], rhs.limbs[4], carry);
    t[6] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[7], limbs[2], rhs.limbs[5], carry);
    t[7] = tmp[0];
    t[8] = tmp[1];

    // 4th row: self.limbs[3] * rhs.limbs[0..5]
    tmp = BigintUtils.mac(t[3], limbs[3], rhs.limbs[0], BigInt.zero);
    t[3] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[4], limbs[3], rhs.limbs[1], carry);
    t[4] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[5], limbs[3], rhs.limbs[2], carry);
    t[5] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[6], limbs[3], rhs.limbs[3], carry);
    t[6] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[7], limbs[3], rhs.limbs[4], carry);
    t[7] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[8], limbs[3], rhs.limbs[5], carry);
    t[8] = tmp[0];
    t[9] = tmp[1];

    // 5th row: self.limbs[4] * rhs.limbs[0..5]
    tmp = BigintUtils.mac(t[4], limbs[4], rhs.limbs[0], BigInt.zero);
    t[4] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[5], limbs[4], rhs.limbs[1], carry);
    t[5] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[6], limbs[4], rhs.limbs[2], carry);
    t[6] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[7], limbs[4], rhs.limbs[3], carry);
    t[7] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[8], limbs[4], rhs.limbs[4], carry);
    t[8] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[9], limbs[4], rhs.limbs[5], carry);
    t[9] = tmp[0];
    t[10] = tmp[1];

    // 6th row: self.limbs[5] * rhs.limbs[0..5]
    tmp = BigintUtils.mac(t[5], limbs[5], rhs.limbs[0], BigInt.zero);
    t[5] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[6], limbs[5], rhs.limbs[1], carry);
    t[6] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[7], limbs[5], rhs.limbs[2], carry);
    t[7] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[8], limbs[5], rhs.limbs[3], carry);
    t[8] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[9], limbs[5], rhs.limbs[4], carry);
    t[9] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.mac(t[10], limbs[5], rhs.limbs[5], carry);
    t[10] = tmp[0];
    t[11] = tmp[1];

    // --- Montgomery reduction -------------------------------------------------
    return Bls12Fp.montgomeryReduce(
      t[0],
      t[1],
      t[2],
      t[3],
      t[4],
      t[5],
      t[6],
      t[7],
      t[8],
      t[9],
      t[10],
      t[11],
    );
  }

  Bls12Fp add(Bls12Fp rhs) {
    List<BigInt> d = List.filled(6, BigInt.zero);
    BigInt carry;

    List<BigInt> tmp = BigintUtils.adc(limbs[0], rhs.limbs[0], BigInt.zero);
    d[0] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(limbs[1], rhs.limbs[1], carry);
    d[1] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(limbs[2], rhs.limbs[2], carry);
    d[2] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(limbs[3], rhs.limbs[3], carry);
    d[3] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(limbs[4], rhs.limbs[4], carry);
    d[4] = tmp[0];
    carry = tmp[1];

    tmp = BigintUtils.adc(limbs[5], rhs.limbs[5], carry);
    d[5] = tmp[0];
    // final carry ignored

    // Reduce modulo the field
    return Bls12Fp(d).subtractP();
  }

  Bls12Fp neg() {
    // --- subtract each limb from the modulus ---------------------------------
    List<BigInt> d = List.filled(6, BigInt.zero);
    BigInt borrow;

    List<BigInt> tmp = BigintUtils.sbb(
      Bls12FpConst.modulus.limbs[0],
      limbs[0],
      BigInt.zero,
    );
    d[0] = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(Bls12FpConst.modulus.limbs[1], limbs[1], borrow);
    d[1] = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(Bls12FpConst.modulus.limbs[2], limbs[2], borrow);
    d[2] = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(Bls12FpConst.modulus.limbs[3], limbs[3], borrow);
    d[3] = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(Bls12FpConst.modulus.limbs[4], limbs[4], borrow);
    d[4] = tmp[0];
    borrow = tmp[1];

    tmp = BigintUtils.sbb(Bls12FpConst.modulus.limbs[5], limbs[5], borrow);
    d[5] = tmp[0];

    // --- compute mask for zero ----------------------------------------------
    bool isZero = limbs.every((x) => x == BigInt.zero);
    BigInt mask = isZero ? BigInt.zero : BigInt.from(-1); // -1 = all bits set

    // --- apply mask to each limb ---------------------------------------------
    for (int i = 0; i < 6; i++) {
      d[i] = d[i] & mask;
    }

    return Bls12Fp(d);
  }

  @override
  Bls12Fp? invert() {
    final modulus = pow([
      BigInt.parse('0xb9feffffffffaaa9'),
      BigInt.parse('0x1eabfffeb153ffff'),
      BigInt.parse('0x6730d2a0f6b0f624'),
      BigInt.parse('0x64774b84f38512bf'),
      BigInt.parse('0x4b1ba7b6434bacd7'),
      BigInt.parse('0x1a0111ea397fe69a'),
    ]);
    if (isZero()) return null;
    return modulus;
  }

  Bls12Fp pow(List<BigInt> by) {
    Bls12Fp res = Bls12Fp.one();
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
  FieldSqrtResult<Bls12Fp> sqrt() {
    final sqrt = pow([
      BigInt.parse("0xee7fbfffffffeaab"),
      BigInt.parse("0x07aaffffac54ffff"),
      BigInt.parse("0xd9cc34a83dac3d89"),
      BigInt.parse("0xd91dd2e13ce144af"),
      BigInt.parse("0x92c6e9ed90d2eb35"),
      BigInt.parse("0x0680447a8e5ff9a6"),
    ]);

    return FieldSqrtResult(sqrt, sqrt.square() == this);
  }

  @override
  bool isZero() {
    return this == Bls12Fp.zero();
  }

  @override
  Bls12Fp double() => add(this);

  @override
  Bls12Fp operator +(Bls12Fp rhs) => add(rhs);
  @override
  Bls12Fp operator -(Bls12Fp rhs) => sub(rhs);
  @override
  Bls12Fp operator *(Bls12Fp rhs) => mul(rhs);
  @override
  Bls12Fp operator -() => neg();

  @override
  bool lexicographicallyLargest() {
    // Reduce Montgomery representation
    final tmp = Bls12Fp.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      limbs[4],
      limbs[5],
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    );

    BigInt borrow = BigInt.zero;

    // Subtract ((p - 1) / 2) + 1 using sbb
    final result0 = BigintUtils.sbb(
      tmp.limbs[0],
      BigInt.parse('0xdcff7fffffffd556'),
      borrow,
    );
    borrow = result0[1];

    final result1 = BigintUtils.sbb(
      tmp.limbs[1],
      BigInt.parse('0x0f55ffff58a9ffff'),
      borrow,
    );
    borrow = result1[1];

    final result2 = BigintUtils.sbb(
      tmp.limbs[2],
      BigInt.parse('0xb39869507b587b12'),
      borrow,
    );
    borrow = result2[1];

    final result3 = BigintUtils.sbb(
      tmp.limbs[3],
      BigInt.parse('0xb23ba5c279c2895f'),
      borrow,
    );
    borrow = result3[1];

    final result4 = BigintUtils.sbb(
      tmp.limbs[4],
      BigInt.parse('0x258dd3db21a5d66b'),
      borrow,
    );
    borrow = result4[1];

    final result5 = BigintUtils.sbb(
      tmp.limbs[5],
      BigInt.parse('0x0d0088f51cbff34d'),
      borrow,
    );
    borrow = result5[1];

    // If borrow = 0, element is lexicographically largest
    return borrow == BigInt.zero;
  }

  @override
  List<int> toBytes() {
    final tmp = Bls12Fp.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      limbs[4],
      limbs[5],
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    );
    return tmp.limbs.reversed.expand((e) => e.toU64BeBytes()).toList();
  }

  @override
  bool constantEquality(Bls12Fp other) {
    return CompareUtils.constantTimeBigIntEquals(limbs, other.limbs);
  }
}

class Bls12NativeFp extends BlsField<Bls12NativeFp> with Equality {
  final BigInt v;
  BigInt get p => Bls12FpConst.p;
  Bls12NativeFp(BigInt v) : v = v % Bls12FpConst.p;
  Bls12NativeFp.nP(this.v) : assert(!v.isNegative && v < Bls12FpConst.p);
  static final _one = Bls12NativeFp.nP(BigInt.one);
  static final _zero = Bls12NativeFp.nP(BigInt.zero);
  factory Bls12NativeFp.zero() => _zero;
  factory Bls12NativeFp.r2() {
    return Bls12NativeFp(
      BigInt.parse(
        "3380320199399472671518931668520476396067793891014375699959770179129436917079669831430077592723774664465579537268733",
      ),
    );
  }

  factory Bls12NativeFp.one() {
    return _one;
  }
  factory Bls12NativeFp.b() {
    return Bls12NativeFp.nP(BigInt.from(4));
  }
  factory Bls12NativeFp.beta() {
    return Bls12NativeFp.nP(
      BigInt.parse(
        "793479390729215512621379701633421447060886740281060493010456487427281649075476305620758731620350",
      ),
    );
  }
  factory Bls12NativeFp.fromBytes(List<int> bytes) {
    if (bytes.length != 48) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field bytes length.",
      );
    }
    final r = BigintUtils.fromBytes(bytes);
    if (r >= Bls12FpConst.p) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field encoding bytes.",
      );
    }
    return Bls12NativeFp.nP(r);
  }
  factory Bls12NativeFp.sumOfProducts(
    List<Bls12NativeFp> a,
    List<Bls12NativeFp> b,
  ) {
    assert(a.length == b.length);
    BigInt sum = BigInt.zero;
    for (int i = 0; i < a.length; i++) {
      sum += a[i].v * b[i].v;
    }
    return Bls12NativeFp(sum);
  }

  factory Bls12NativeFp.conditionalSelect(
    Bls12NativeFp a,
    Bls12NativeFp b,
    bool choice,
  ) {
    return Bls12NativeFp.nP(choice ? b.v : a.v);
  }

  Bls12NativeFp _exp(BigInt e) {
    var result = Bls12NativeFp.one();
    var base = this;
    var k = e;

    while (k > BigInt.zero) {
      if (k.isOdd) result = result * base;
      base = base * base;
      k >>= 1;
    }
    return result;
  }

  @override
  Bls12NativeFp square() {
    return Bls12NativeFp(v * v);
  }

  @override
  Bls12NativeFp? invert() {
    if (isZero()) return null;
    return _exp(p - BigInt.two);
  }

  Bls12NativeFp pow(BigInt r) => _exp(r);

  @override
  FieldSqrtResult<Bls12NativeFp> sqrt() {
    final sqrt = pow(
      BigInt.parse(
        "1000602388805416848354447456433976039139220704984751971333014534031007912622709466110671907282253916009473568139947",
      ),
    );
    return FieldSqrtResult(sqrt, sqrt.square() == this);
  }

  @override
  bool isZero() {
    return this == _zero;
  }

  @override
  Bls12NativeFp double() => this + this;

  @override
  Bls12NativeFp operator +(Bls12NativeFp rhs) {
    final BigInt sum = v + rhs.v;
    return Bls12NativeFp.nP(sum >= p ? sum - p : sum);
  }

  @override
  Bls12NativeFp operator -(Bls12NativeFp rhs) {
    final BigInt diff = v - rhs.v;
    return Bls12NativeFp.nP(diff.isNegative ? diff + p : diff);
  }

  @override
  Bls12NativeFp operator *(Bls12NativeFp rhs) => Bls12NativeFp(v * rhs.v);
  @override
  Bls12NativeFp operator -() => Bls12NativeFp(-v);

  @override
  bool lexicographicallyLargest() {
    final halfP = (p - BigInt.one) >> 1;

    return v > halfP;
  }

  @override
  List<int> toBytes() {
    return BigintUtils.toBytes(v, length: 48);
  }

  @override
  List<dynamic> get variables => [v];
}

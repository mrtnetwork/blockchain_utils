import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Constants for the BLS12-381 base field GF(p).
/// All values are expressed using `BigInt`.
class Bls12FpConst {
  static const Uint64 inv = Uint64.unsafe(2314469372, 4294770685);

  /// Modulus represented as fixed-size limb elements.
  static const modulus = Bls12Fp.unsafe([
    Uint64.unsafe(3120496639, 4294945451),
    Uint64.unsafe(514588670, 2975072255),
    Uint64.unsafe(1731252896, 4138792484),
    Uint64.unsafe(1685539716, 4085584575),
    Uint64.unsafe(1260103606, 1129032919),
    Uint64.unsafe(436277738, 964683418),
  ]);

  /// Prime modulus p of BLS12-381 as a single BigInt.
  static final p = BigInt.parse(
    "4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787",
  );
}

/// Implementation of the BLS12-381 base field GF(p).
class Bls12Fp extends BlsField<Bls12Fp> with ConstantEquality<Bls12Fp> {
  /// Fixed-size limb representation of the field element.
  final List<Uint64> limbs;
  const Bls12Fp.unsafe(this.limbs);
  Bls12Fp(List<Uint64> limbs)
    : limbs = limbs.exc(length: 6, operation: "Bls12Fp").immutable;

  /// Montgomery reduction of a 12-limb intermediate into a BLS12-381 field element.
  factory Bls12Fp.montgomeryReduce(
    Uint64 t0,
    Uint64 t1,
    Uint64 t2,
    Uint64 t3,
    Uint64 t4,
    Uint64 t5,
    Uint64 t6,
    Uint64 t7,
    Uint64 t8,
    Uint64 t9,
    Uint64 t10,
    Uint64 t11,
  ) {
    final inv = Bls12FpConst.inv;
    // --- 1st iteration --------------------------------------------------------
    Uint64 k = t0 * inv;
    var tmp = Uint64.mac(t0, k, Bls12FpConst.modulus.limbs[0], Uint64.zero);
    Uint64 carry = tmp.$2;

    tmp = Uint64.mac(t1, k, Bls12FpConst.modulus.limbs[1], carry);
    Uint64 r1 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t2, k, Bls12FpConst.modulus.limbs[2], carry);
    Uint64 r2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t3, k, Bls12FpConst.modulus.limbs[3], carry);
    Uint64 r3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t4, k, Bls12FpConst.modulus.limbs[4], carry);
    Uint64 r4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t5, k, Bls12FpConst.modulus.limbs[5], carry);
    Uint64 r5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t6, Uint64.zero, carry);
    Uint64 r6 = tmp.$1;
    Uint64 r7 = tmp.$2;

    // --- 2nd iteration --------------------------------------------------------
    k = (r1 * inv);

    tmp = Uint64.mac(r1, k, Bls12FpConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;

    tmp = Uint64.mac(r2, k, Bls12FpConst.modulus.limbs[1], carry);
    r2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r3, k, Bls12FpConst.modulus.limbs[2], carry);
    r3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r4, k, Bls12FpConst.modulus.limbs[3], carry);
    r4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r5, k, Bls12FpConst.modulus.limbs[4], carry);
    r5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r6, k, Bls12FpConst.modulus.limbs[5], carry);
    r6 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t7, r7, carry);
    r7 = tmp.$1;
    Uint64 r8 = tmp.$2;

    // --- 3rd iteration --------------------------------------------------------
    k = (r2 * inv);

    tmp = Uint64.mac(r2, k, Bls12FpConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;

    tmp = Uint64.mac(r3, k, Bls12FpConst.modulus.limbs[1], carry);
    r3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r4, k, Bls12FpConst.modulus.limbs[2], carry);
    r4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r5, k, Bls12FpConst.modulus.limbs[3], carry);
    r5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r6, k, Bls12FpConst.modulus.limbs[4], carry);
    r6 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r7, k, Bls12FpConst.modulus.limbs[5], carry);
    r7 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t8, r8, carry);
    r8 = tmp.$1;
    Uint64 r9 = tmp.$2;

    // --- 4th iteration --------------------------------------------------------
    k = (r3 * inv);

    tmp = Uint64.mac(r3, k, Bls12FpConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;

    tmp = Uint64.mac(r4, k, Bls12FpConst.modulus.limbs[1], carry);
    r4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r5, k, Bls12FpConst.modulus.limbs[2], carry);
    r5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r6, k, Bls12FpConst.modulus.limbs[3], carry);
    r6 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r7, k, Bls12FpConst.modulus.limbs[4], carry);
    r7 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r8, k, Bls12FpConst.modulus.limbs[5], carry);
    r8 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t9, r9, carry);
    r9 = tmp.$1;
    Uint64 r10 = tmp.$2;

    // --- 5th iteration --------------------------------------------------------
    k = (r4 * inv);

    tmp = Uint64.mac(r4, k, Bls12FpConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;

    tmp = Uint64.mac(r5, k, Bls12FpConst.modulus.limbs[1], carry);
    r5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r6, k, Bls12FpConst.modulus.limbs[2], carry);
    r6 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r7, k, Bls12FpConst.modulus.limbs[3], carry);
    r7 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r8, k, Bls12FpConst.modulus.limbs[4], carry);
    r8 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r9, k, Bls12FpConst.modulus.limbs[5], carry);
    r9 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t10, r10, carry);
    r10 = tmp.$1;
    Uint64 r11 = tmp.$2;

    // --- 6th iteration --------------------------------------------------------
    k = (r5 * inv);

    tmp = Uint64.mac(r5, k, Bls12FpConst.modulus.limbs[0], Uint64.zero);
    carry = tmp.$2;

    tmp = Uint64.mac(r6, k, Bls12FpConst.modulus.limbs[1], carry);
    r6 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r7, k, Bls12FpConst.modulus.limbs[2], carry);
    r7 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r8, k, Bls12FpConst.modulus.limbs[3], carry);
    r8 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r9, k, Bls12FpConst.modulus.limbs[4], carry);
    r9 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(r10, k, Bls12FpConst.modulus.limbs[5], carry);
    r10 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t11, r11, carry);
    r11 = tmp.$1;

    // Final reduce: subtract modulus
    return Bls12Fp([r6, r7, r8, r9, r10, r11])._subtractP();
  }

  static const zero = Bls12Fp.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const one = Bls12Fp.unsafe([
    Uint64.unsafe(1980301312, 196605),
    Uint64.unsafe(3958636555, 3289120770),
    Uint64.unsafe(1598593111, 1405573306),
    Uint64.unsafe(2010011731, 1884444485),
    Uint64.unsafe(1543969431, 2723605613),
    Uint64.unsafe(368467651, 4202751123),
  ]);
  static const r2 = Bls12Fp.unsafe([
    Uint64.unsafe(4108263220, 473175878),
    Uint64.unsafe(175564454, 164693233),
    Uint64.unsafe(2380613484, 1284880085),
    Uint64.unsafe(1743489193, 2476573632),
    Uint64.unsafe(2591637125, 3038352685),
    Uint64.unsafe(295210981, 2462770090),
  ]);
  static const b = Bls12Fp.unsafe([
    Uint64.unsafe(2854682624, 851955),
    Uint64.unsafe(1405878322, 4231266314),
    Uint64.unsafe(1200613754, 1795850367),
    Uint64.unsafe(2983427774, 3870958807),
    Uint64.unsafe(2395566907, 3212356399),
    Uint64.unsafe(165037393, 1032052350),
  ]);
  static const beta = Bls12Fp.unsafe([
    Uint64.unsafe(821114395, 2039112936),
    Uint64.unsafe(4088978859, 2127452714),
    Uint64.unsafe(380160570, 3323295735),
    Uint64.unsafe(3261739000, 1962738331),
    Uint64.unsafe(909555558, 1617960046),
    Uint64.unsafe(85697707, 605774176),
  ]);

  /// Creates a BLS12-381 field element from a byte array.
  factory Bls12Fp.fromBytes(List<int> bytes) {
    if (bytes.length != 48) {
      throw ArgumentException.invalidOperationArguments(
        "Bls12Fp",
        reason: "Invalid field bytes length.",
      );
    }
    final tmp = Bls12Fp([
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 40),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 32),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 24),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 16),
      Uint64.fromBytes(bytes, endian: Endian.big, offset: 8),
      Uint64.fromBytes(bytes, endian: Endian.big),
    ]);
    Uint64 borrow = Uint64.zero;
    var temp = Uint64.sbb(tmp.limbs[0], Bls12FpConst.modulus.limbs[0], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[1], Bls12FpConst.modulus.limbs[1], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[2], Bls12FpConst.modulus.limbs[2], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[3], Bls12FpConst.modulus.limbs[3], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[4], Bls12FpConst.modulus.limbs[4], borrow);
    borrow = temp.$2;
    temp = Uint64.sbb(tmp.limbs[5], Bls12FpConst.modulus.limbs[5], borrow);
    borrow = temp.$2;
    // final result = tmp * Bls12FpConst.r2;
    if ((borrow & Uint64.one) != Uint64.one) {
      throw ArgumentException.invalidOperationArguments(
        "Bls12Fp",
        reason: "Invalid field encoding bytes.",
      );
    }
    return tmp * Bls12Fp.r2;
  }

  factory Bls12Fp.sumOfProducts(List<Bls12Fp> a, List<Bls12Fp> b) {
    final int length = a.length;
    List<Uint64> u = List.filled(6, Uint64.zero);

    for (int j = 0; j < 6; j++) {
      // Accumulate products for limb j
      List<Uint64> t = [...u, Uint64.zero]; // t0..t5 + t6
      for (int i = 0; i < length; i++) {
        var res = Uint64.mac(t[0], a[i].limbs[j], b[i].limbs[0], Uint64.zero);
        t[0] = res.$1;
        Uint64 carry = res.$2;

        res = Uint64.mac(t[1], a[i].limbs[j], b[i].limbs[1], carry);
        t[1] = res.$1;
        carry = res.$2;

        res = Uint64.mac(t[2], a[i].limbs[j], b[i].limbs[2], carry);
        t[2] = res.$1;
        carry = res.$2;

        res = Uint64.mac(t[3], a[i].limbs[j], b[i].limbs[3], carry);
        t[3] = res.$1;
        carry = res.$2;

        res = Uint64.mac(t[4], a[i].limbs[j], b[i].limbs[4], carry);
        t[4] = res.$1;
        carry = res.$2;

        res = Uint64.mac(t[5], a[i].limbs[j], b[i].limbs[5], carry);
        t[5] = res.$1;
        carry = res.$2;

        res = Uint64.adc(t[6], Uint64.zero, carry);
        t[6] = res.$1;
      }

      // Montgomery reduction step
      final k = (t[0] * Bls12FpConst.inv);
      var carry = Uint64.zero;
      var r = List<Uint64>.filled(6, Uint64.zero);

      var res = Uint64.mac(t[0], k, Bls12FpConst.modulus.limbs[0], Uint64.zero);
      carry = res.$2;

      res = Uint64.mac(t[1], k, Bls12FpConst.modulus.limbs[1], carry);
      r[0] = res.$1;
      carry = res.$2;

      res = Uint64.mac(t[2], k, Bls12FpConst.modulus.limbs[2], carry);
      r[1] = res.$1;
      carry = res.$2;

      res = Uint64.mac(t[3], k, Bls12FpConst.modulus.limbs[3], carry);
      r[2] = res.$1;
      carry = res.$2;

      res = Uint64.mac(t[4], k, Bls12FpConst.modulus.limbs[4], carry);
      r[3] = res.$1;
      carry = res.$2;

      res = Uint64.mac(t[5], k, Bls12FpConst.modulus.limbs[5], carry);
      r[4] = res.$1;
      carry = res.$2;

      res = Uint64.adc(t[6], Uint64.zero, carry);
      r[5] = res.$1;

      u = r;
    }

    return Bls12Fp(u)._subtractP();
  }

  factory Bls12Fp.conditionalSelect(Bls12Fp a, Bls12Fp b, bool choice) {
    return Bls12Fp([
      Uint64.ctSelect(a.limbs[0], b.limbs[0], choice),
      Uint64.ctSelect(a.limbs[1], b.limbs[1], choice),
      Uint64.ctSelect(a.limbs[2], b.limbs[2], choice),
      Uint64.ctSelect(a.limbs[3], b.limbs[3], choice),
      Uint64.ctSelect(a.limbs[4], b.limbs[4], choice),
      Uint64.ctSelect(a.limbs[5], b.limbs[5], choice),
    ]);
  }

  Bls12Fp _subtractP() {
    var tmp = Uint64.sbb(limbs[0], Bls12FpConst.modulus.limbs[0], Uint64.zero);
    Uint64 r0 = tmp.$1;
    Uint64 borrow = tmp.$2;

    tmp = Uint64.sbb(limbs[1], Bls12FpConst.modulus.limbs[1], borrow);
    Uint64 r1 = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(limbs[2], Bls12FpConst.modulus.limbs[2], borrow);
    Uint64 r2 = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(limbs[3], Bls12FpConst.modulus.limbs[3], borrow);
    Uint64 r3 = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(limbs[4], Bls12FpConst.modulus.limbs[4], borrow);
    Uint64 r4 = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(limbs[5], Bls12FpConst.modulus.limbs[5], borrow);
    Uint64 r5 = tmp.$1;
    borrow = tmp.$2;

    r0 = ((limbs[0] & borrow) | (r0 & ~borrow));
    r1 = ((limbs[1] & borrow) | (r1 & ~borrow));
    r2 = ((limbs[2] & borrow) | (r2 & ~borrow));
    r3 = ((limbs[3] & borrow) | (r3 & ~borrow));
    r4 = ((limbs[4] & borrow) | (r4 & ~borrow));
    r5 = ((limbs[5] & borrow) | (r5 & ~borrow));

    return Bls12Fp([r0, r1, r2, r3, r4, r5]);
  }

  /// Square
  @override
  Bls12Fp square() {
    var tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[1], Uint64.zero);
    Uint64 t1 = tmp.$1;
    Uint64 carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[2], carry);
    Uint64 t2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[3], carry);
    Uint64 t3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[4], carry);
    Uint64 t4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[5], carry);
    Uint64 t5 = tmp.$1;
    Uint64 t6 = tmp.$2;

    tmp = Uint64.mac(t3, limbs[1], limbs[2], Uint64.zero);
    t3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t4, limbs[1], limbs[3], carry);
    t4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t5, limbs[1], limbs[4], carry);
    t5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t6, limbs[1], limbs[5], carry);
    t6 = tmp.$1;
    Uint64 t7 = tmp.$2;

    ///
    tmp = Uint64.mac(t5, limbs[2], limbs[3], Uint64.zero);
    t5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t6, limbs[2], limbs[4], carry);
    t6 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t7, limbs[2], limbs[5], carry);
    t7 = tmp.$1;
    Uint64 t8 = tmp.$2;
    //
    tmp = Uint64.mac(t7, limbs[3], limbs[4], Uint64.zero);
    t7 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t8, limbs[3], limbs[5], carry);
    t8 = tmp.$1;
    Uint64 t9 = tmp.$2;

    tmp = Uint64.mac(t9, limbs[4], limbs[5], Uint64.zero);
    t9 = tmp.$1;
    Uint64 t10 = tmp.$2;

    // Double the cross products
    Uint64 t11 = (t10 >> 63);
    t10 = ((t10 << 1) | (t9 >> 63));
    t9 = ((t9 << 1) | (t8 >> 63));
    t8 = ((t8 << 1) | (t7 >> 63));
    t7 = ((t7 << 1) | (t6 >> 63));
    t6 = ((t6 << 1) | (t5 >> 63));
    t5 = ((t5 << 1) | (t4 >> 63));
    t4 = ((t4 << 1) | (t3 >> 63));
    t3 = ((t3 << 1) | (t2 >> 63));
    t2 = ((t2 << 1) | (t1 >> 63));
    t1 = (t1 << 1);

    // Square the limbs and accumulate
    tmp = Uint64.mac(Uint64.zero, limbs[0], limbs[0], Uint64.zero);
    Uint64 t0 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t1, Uint64.zero, carry);
    t1 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t2, limbs[1], limbs[1], carry);
    t2 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t3, Uint64.zero, carry);
    t3 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t4, limbs[2], limbs[2], carry);
    t4 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t5, Uint64.zero, carry);
    t5 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t6, limbs[3], limbs[3], carry);
    t6 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t7, Uint64.zero, carry);
    t7 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t8, limbs[4], limbs[4], carry);
    t8 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t9, Uint64.zero, carry);
    t9 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t10, limbs[5], limbs[5], carry);
    t10 = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(t11, Uint64.zero, carry);
    t11 = tmp.$1;
    // final carry ignored
    // --- Montgomery reduction -------------------------------------------------
    return Bls12Fp.montgomeryReduce(t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11);
  }

  Bls12Fp _sub(Bls12Fp rhs) {
    return rhs._neg()._add(this);
  }

  Bls12Fp _mul(Bls12Fp rhs) {
    List<Uint64> t = List.filled(12, Uint64.zero);

    var tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[0], Uint64.zero);
    t[0] = tmp.$1;
    Uint64 carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[1], carry);
    t[1] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[2], carry);
    t[2] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[3], carry);
    t[3] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[4], carry);
    t[4] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(Uint64.zero, limbs[0], rhs.limbs[5], carry);
    t[5] = tmp.$1;
    t[6] = tmp.$2;

    // 2nd row: self.limbs[1] * rhs.limbs[0..5]
    tmp = Uint64.mac(t[1], limbs[1], rhs.limbs[0], Uint64.zero);
    t[1] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[2], limbs[1], rhs.limbs[1], carry);
    t[2] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[3], limbs[1], rhs.limbs[2], carry);
    t[3] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[4], limbs[1], rhs.limbs[3], carry);
    t[4] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[5], limbs[1], rhs.limbs[4], carry);
    t[5] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[6], limbs[1], rhs.limbs[5], carry);
    t[6] = tmp.$1;
    t[7] = tmp.$2;

    // 3rd row: self.limbs[2] * rhs.limbs[0..5]
    tmp = Uint64.mac(t[2], limbs[2], rhs.limbs[0], Uint64.zero);
    t[2] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[3], limbs[2], rhs.limbs[1], carry);
    t[3] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[4], limbs[2], rhs.limbs[2], carry);
    t[4] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[5], limbs[2], rhs.limbs[3], carry);
    t[5] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[6], limbs[2], rhs.limbs[4], carry);
    t[6] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[7], limbs[2], rhs.limbs[5], carry);
    t[7] = tmp.$1;
    t[8] = tmp.$2;

    // 4th row: self.limbs[3] * rhs.limbs[0..5]
    tmp = Uint64.mac(t[3], limbs[3], rhs.limbs[0], Uint64.zero);
    t[3] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[4], limbs[3], rhs.limbs[1], carry);
    t[4] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[5], limbs[3], rhs.limbs[2], carry);
    t[5] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[6], limbs[3], rhs.limbs[3], carry);
    t[6] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[7], limbs[3], rhs.limbs[4], carry);
    t[7] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[8], limbs[3], rhs.limbs[5], carry);
    t[8] = tmp.$1;
    t[9] = tmp.$2;

    // 5th row: self.limbs[4] * rhs.limbs[0..5]
    tmp = Uint64.mac(t[4], limbs[4], rhs.limbs[0], Uint64.zero);
    t[4] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[5], limbs[4], rhs.limbs[1], carry);
    t[5] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[6], limbs[4], rhs.limbs[2], carry);
    t[6] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[7], limbs[4], rhs.limbs[3], carry);
    t[7] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[8], limbs[4], rhs.limbs[4], carry);
    t[8] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[9], limbs[4], rhs.limbs[5], carry);
    t[9] = tmp.$1;
    t[10] = tmp.$2;

    // 6th row: self.limbs[5] * rhs.limbs[0..5]
    tmp = Uint64.mac(t[5], limbs[5], rhs.limbs[0], Uint64.zero);
    t[5] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[6], limbs[5], rhs.limbs[1], carry);
    t[6] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[7], limbs[5], rhs.limbs[2], carry);
    t[7] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[8], limbs[5], rhs.limbs[3], carry);
    t[8] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[9], limbs[5], rhs.limbs[4], carry);
    t[9] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.mac(t[10], limbs[5], rhs.limbs[5], carry);
    t[10] = tmp.$1;
    t[11] = tmp.$2;

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

  Bls12Fp _add(Bls12Fp rhs) {
    List<Uint64> d = List.filled(6, Uint64.zero);
    Uint64 carry;

    var tmp = Uint64.adc(limbs[0], rhs.limbs[0], Uint64.zero);
    d[0] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(limbs[1], rhs.limbs[1], carry);
    d[1] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(limbs[2], rhs.limbs[2], carry);
    d[2] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(limbs[3], rhs.limbs[3], carry);
    d[3] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(limbs[4], rhs.limbs[4], carry);
    d[4] = tmp.$1;
    carry = tmp.$2;

    tmp = Uint64.adc(limbs[5], rhs.limbs[5], carry);
    d[5] = tmp.$1;
    // final carry ignored

    // Reduce modulo the field
    return Bls12Fp(d)._subtractP();
  }

  Bls12Fp _neg() {
    List<Uint64> d = List.filled(6, Uint64.zero);
    Uint64 borrow;

    var tmp = Uint64.sbb(Bls12FpConst.modulus.limbs[0], limbs[0], Uint64.zero);
    d[0] = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(Bls12FpConst.modulus.limbs[1], limbs[1], borrow);
    d[1] = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(Bls12FpConst.modulus.limbs[2], limbs[2], borrow);
    d[2] = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(Bls12FpConst.modulus.limbs[3], limbs[3], borrow);
    d[3] = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(Bls12FpConst.modulus.limbs[4], limbs[4], borrow);
    d[4] = tmp.$1;
    borrow = tmp.$2;

    tmp = Uint64.sbb(Bls12FpConst.modulus.limbs[5], limbs[5], borrow);
    d[5] = tmp.$1;
    final x = limbs[0] | limbs[1] | limbs[2] | limbs[3] | limbs[4] | limbs[5];

    // --- compute mask for zero ----------------------------------------------
    final mask = (x == Uint64.zero) ? Uint64.zero : Uint64.max; // 0 // -1 = all bits set

    // --- apply mask to each limb ---------------------------------------------
    for (int i = 0; i < 6; i++) {
      d[i] = d[i] & mask;
    }

    return Bls12Fp(d);
  }

  /// Invert null of field is zero
  @override
  Bls12Fp? invert() {
    const m = [
      Uint64.unsafe(3120496639, 4294945449),
      Uint64.unsafe(514588670, 2975072255),
      Uint64.unsafe(1731252896, 4138792484),
      Uint64.unsafe(1685539716, 4085584575),
      Uint64.unsafe(1260103606, 1129032919),
      Uint64.unsafe(436277738, 964683418),
    ];
    final modulus = pow(m);
    if (isZero()) return null;
    return modulus;
  }

  /// pow
  Bls12Fp pow(List<Uint64> by) {
    Bls12Fp res = Bls12Fp.one;
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

  /// sqrt
  @override
  FieldSqrtResult<Bls12Fp> sqrt() {
    const m = [
      Uint64.unsafe(4001349631, 4294961835),
      Uint64.unsafe(128647167, 2891251711),
      Uint64.unsafe(3654038696, 1034698121),
      Uint64.unsafe(3642610401, 1021396143),
      Uint64.unsafe(2462509549, 2429741877),
      Uint64.unsafe(109069434, 2388654502),
    ];
    final sqrt = pow(m);
    return FieldSqrtResult(sqrt, sqrt.square() == this);
  }

  /// check zero
  @override
  bool isZero() {
    return this == Bls12Fp.zero;
  }

  /// double field
  @override
  Bls12Fp double() => _add(this);

  @override
  Bls12Fp operator +(Bls12Fp rhs) => _add(rhs);
  @override
  Bls12Fp operator -(Bls12Fp rhs) => _sub(rhs);
  @override
  Bls12Fp operator *(Bls12Fp rhs) => _mul(rhs);
  @override
  Bls12Fp operator -() => _neg();

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
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );

    Uint64 borrow = Uint64.zero;
    const d = [
      Uint64.unsafe(3707731967, 4294956374),
      Uint64.unsafe(257294335, 1487536127),
      Uint64.unsafe(3013110096, 2069396242),
      Uint64.unsafe(2990253506, 2042792287),
      Uint64.unsafe(630051803, 564516459),
      Uint64.unsafe(218138869, 482341709),
    ];

    // Subtract ((p - 1) / 2) + 1 using sbb
    final result0 = Uint64.sbb(tmp.limbs[0], d[0], borrow);
    borrow = result0.$2;

    final result1 = Uint64.sbb(tmp.limbs[1], d[1], borrow);
    borrow = result1.$2;

    final result2 = Uint64.sbb(tmp.limbs[2], d[2], borrow);
    borrow = result2.$2;

    final result3 = Uint64.sbb(tmp.limbs[3], d[3], borrow);
    borrow = result3.$2;

    final result4 = Uint64.sbb(tmp.limbs[4], d[4], borrow);
    borrow = result4.$2;

    final result5 = Uint64.sbb(tmp.limbs[5], d[5], borrow);
    borrow = result5.$2;

    // If borrow = 0, element is lexicographically largest
    return borrow == Uint64.zero;
  }

  /// Serializes the field element to a 48-byte big-endian representation.
  @override
  List<int> toBytes() {
    final tmp = Bls12Fp.montgomeryReduce(
      limbs[0],
      limbs[1],
      limbs[2],
      limbs[3],
      limbs[4],
      limbs[5],
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    );
    return tmp.limbs.reversed.expand((e) => e.toBytesBE()).toList();
  }

  /// check equality
  @override
  bool constantEquality(Bls12Fp other) {
    return Uint64.ctEquals(limbs, other.limbs);
  }
}

/// Native BLS12-381 base field element backed by a single BigInt.
class Bls12NativeFp extends BlsField<Bls12NativeFp> with Equality {
  /// Canonical field value in the range [0, p).
  final BigInt v;

  /// Prime modulus p of the field.
  BigInt get p => Bls12FpConst.p;

  /// Creates a field element reduced modulo p.
  Bls12NativeFp(BigInt v) : v = v % Bls12FpConst.p;

  /// Creates a field element assuming v is already in canonical form.
  Bls12NativeFp.nP(this.v) : assert(!v.isNegative && v < Bls12FpConst.p);

  /// Multiplicative identity.
  static final _one = Bls12NativeFp.nP(BigInt.one);

  /// Additive identity.
  static final _zero = Bls12NativeFp.nP(BigInt.zero);

  /// Returns the additive identity.
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
  factory Bls12NativeFp.sumOfProducts(List<Bls12NativeFp> a, List<Bls12NativeFp> b) {
    assert(a.length == b.length);
    BigInt sum = BigInt.zero;
    for (int i = 0; i < a.length; i++) {
      sum += a[i].v * b[i].v;
    }
    return Bls12NativeFp(sum);
  }

  factory Bls12NativeFp.conditionalSelect(Bls12NativeFp a, Bls12NativeFp b, bool choice) {
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

  /// Serializes the field element to a 48-byte big-endian representation.
  @override
  List<int> toBytes() {
    return v.toBeBytes(length: 48);
  }

  @override
  List<dynamic> get variables => [v];
}

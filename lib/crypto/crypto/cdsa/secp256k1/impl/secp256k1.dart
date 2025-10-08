// *******************************************************************************
// Copyright (c) 2013, 2014, 2015, 2021 Thomas Daede, Cory Fields, Pieter Wuille *
// Distributed under the MIT software license, see the accompanying              *
// file COPYING or https://www.opensource.org/licenses/mit-license.php.          *
// *******************************************************************************

import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/constants/constants.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/constants/tables.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

/// A Dart port of [Bitcoin Core's secp256k1 library](https://github.com/bitcoin-core/secp256k1/tree/master),
/// focused on safety during scalar multiplication (`ecmult`) to mitigate timing and side-channel attacks.
///
/// ⚠️ This is a beta version — some methods may be untested.
///
/// Note: The developer welcomes feedback, especially regarding timing and side-channel attack resistance
/// in the context of Dart.
class Secp256k1 {
  static final Secp256k1Scalar _secp256k1ScalarOne =
      Secp256k1Const.secp256k1ScalarOne;

  static void _cond(bool cond, String? op) {
    if (cond) return;
    throw CryptoException('Crypto operation "$op" failed');
  }

  static int secp256k1CtzVar(BigInt x) {
    if (x == BigInt.zero) throw CryptoException('x must not be zero.');

    int count = 0;
    while ((x & BigInt.one) == BigInt.zero) {
      x >>= 1;
      count++;
    }
    return count;
  }

  static int secp256k1FeCmpVar(Secp256k1Fe a, Secp256k1Fe b) {
    int i;
    for (i = 4; i >= 0; i--) {
      if (a[i] > b[i]) {
        return 1;
      }
      if (a[i] < b[i]) {
        return -1;
      }
    }
    return 0;
  }

  static void secp256k1ECmultTableGetGe(
      Secp256k1Ge r, List<Secp256k1Ge> pre, int n, int w) {
    secp256k1EcmultTableVerify(n, w);
    if (n > 0) {
      r.set(pre[(n - 1) ~/ 2]);
    } else {
      r.set(pre[(-n - 1) ~/ 2]);
      secp256k1FeNegate((r.y), (r.y), 1);
    }
  }

  static void secp256k1ECmultTableGetGeLambda(
      Secp256k1Ge r, List<Secp256k1Ge> pre, List<Secp256k1Fe> x, int n, int w) {
    secp256k1EcmultTableVerify(n, w);
    if (n > 0) {
      secp256k1GeSetXy(r, x[(n - 1) ~/ 2], pre[(n - 1) ~/ 2].y);
    } else {
      secp256k1GeSetXy(r, x[(-n - 1) ~/ 2], pre[(-n - 1) ~/ 2].y);
      secp256k1FeNegate((r.y), (r.y), 1);
    }
  }

  static void secp256k1EcmultTableVerify(int n, int w) {
    _cond(((n) & 1) == 1, "secp256k1EcmultTableVerify");
    _cond((n) >= -((1 << ((w) - 1)) - 1), "secp256k1EcmultTableVerify");
    _cond((n) <= ((1 << ((w) - 1)) - 1), "secp256k1EcmultTableVerify");
  }

  static void secp256k1GeNeg(Secp256k1Ge r, Secp256k1Ge a) {
    r.set(a);
    secp256k1FeNormalizeWeak(r.y);
    secp256k1FeNegate(r.y, r.y, 1);
  }

  static BigInt secp256k1U128ToU64(Secp256k1Uint128 a) {
    return a.r.toUnsigned64;
  }

  static void secp256k1U128Mul(Secp256k1Uint128 r, BigInt a, BigInt b) {
    // r.r = (a * b).toUnsigned128;
    r.set(a * b);
  }

  static void secp256k1U128FromU64(Secp256k1Uint128 r, BigInt a) {
    // r.r = a.toUnsigned64;
    r.setU64(a);
  }

  static BigInt secp256k1U128HiU64(Secp256k1Uint128 a) {
    return (a.r >> 64).toUnsigned64;
  }

  static void secp256k1U128AccumU64(Secp256k1Uint128 r, BigInt a) {
    // r.r = (r.r + a.toUnsigned64).toUnsigned128;
    r.set(r.r + a.toUnsigned64);
  }

  static void secp256k1U128AccumMul(Secp256k1Uint128 r, BigInt a, BigInt b) {
    // r.r = (r.r + a * b).toUnsigned128;
    r.set(r.r + a * b);
  }

  static void secp256k1U128Rshift(Secp256k1Uint128 r, int n) {
    // Ensure the shift value is valid
    if (n >= 128) {
      throw CryptoException("Shift value n must be less than 128.");
    }
    // r.r = (r.r >>= n);
    r.set(r.r >> n);
  }

  static void secp256k1FeSetB32Mod(Secp256k1Fe r, List<int> a) {
    a.asMin32("secp256k1FeSetB32Mod");
    r[0] = a[31].toUnsignedBigInt64 |
        (a[30].toUnsignedBigInt64 << 8) |
        (a[29].toUnsignedBigInt64 << 16) |
        (a[28].toUnsignedBigInt64 << 24) |
        (a[27].toUnsignedBigInt64 << 32) |
        (a[26].toUnsignedBigInt64 << 40) |
        ((a[25] & 0xF).toUnsignedBigInt64 << 48);
    r[1] = ((a[25] >> 4) & 0xF).toUnsignedBigInt64 |
        (a[24].toUnsignedBigInt64 << 4) |
        (a[23].toUnsignedBigInt64 << 12) |
        (a[22].toUnsignedBigInt64 << 20) |
        (a[21].toUnsignedBigInt64 << 28) |
        (a[20].toUnsignedBigInt64 << 36) |
        (a[19].toUnsignedBigInt64 << 44);
    r[2] = a[18].toUnsignedBigInt64 |
        (a[17].toUnsignedBigInt64 << 8) |
        (a[16].toUnsignedBigInt64 << 16) |
        (a[15].toUnsignedBigInt64 << 24) |
        (a[14].toUnsignedBigInt64 << 32) |
        (a[13].toUnsignedBigInt64 << 40) |
        ((a[12] & 0xF).toUnsignedBigInt64 << 48);
    r[3] = ((a[12] >> 4) & 0xF).toUnsignedBigInt64 |
        (a[11].toUnsignedBigInt64 << 4) |
        (a[10].toUnsignedBigInt64 << 12) |
        (a[9].toUnsignedBigInt64 << 20) |
        (a[8].toUnsignedBigInt64 << 28) |
        (a[7].toUnsignedBigInt64 << 36) |
        (a[6].toUnsignedBigInt64 << 44);
    r[4] = a[5].toUnsignedBigInt64 |
        (a[4].toUnsignedBigInt64 << 8) |
        (a[3].toUnsignedBigInt64 << 16) |
        (a[2].toUnsignedBigInt64 << 24) |
        (a[1].toUnsignedBigInt64 << 32) |
        (a[0].toUnsignedBigInt64 << 40);
  }

  static int secp256k1FeImplSetB32Limit(Secp256k1Fe r, List<int> a) {
    secp256k1FeSetB32Mod(r, a);
    return (!((r[4] == Secp256k1Const.mask48) &
            ((r[3] & r[2] & r[1]) == Secp256k1Const.mask52) &
            (r[0] >= Secp256k1Const.mask47)))
        .toInt;
  }

  static void secp256k1FeMul(Secp256k1Fe r, Secp256k1Fe a, Secp256k1Fe b) {
    void verifyBits(BigInt x, int n) => _verifyBits(x, n, "secp256k1FeMul");
    void verifyBits128(Secp256k1Uint128 x, int n) =>
        _verifyBits128(x, n, "secp256k1FeMul");
    _cond(r != b, "secp256k1FeMul");
    _cond(a != b, "secp256k1FeMul");
    Secp256k1Uint128 c = Secp256k1Uint128(), d = Secp256k1Uint128();
    BigInt t3, t4, tx, u0;
    BigInt a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3], a4 = a[4];
    BigInt M = Secp256k1Const.mask52, R = Secp256k1Const.bit33Mask;
    verifyBits(a[0], 56);
    verifyBits(a[1], 56);
    verifyBits(a[2], 56);
    verifyBits(a[3], 56);
    verifyBits(a[4], 52);
    verifyBits(b[0], 56);
    verifyBits(b[1], 56);
    verifyBits(b[2], 56);
    verifyBits(b[3], 56);
    verifyBits(b[4], 52);
    _cond(r != b, "secp256k1FeMul");
    _cond(a != b, "secp256k1FeMul");

    secp256k1U128Mul(d, a0, b[3]);
    secp256k1U128AccumMul(d, a1, b[2]);
    secp256k1U128AccumMul(d, a2, b[1]);
    secp256k1U128AccumMul(d, a3, b[0]);
    verifyBits128(d, 114);

    /// [d 0 0 0] = [p3 0 0 0]
    secp256k1U128Mul(c, a4, b[4]);
    verifyBits128(c, 112);
    // /// [c 0 0 0 0 d 0 0 0] = [p8 0 0 0 0 p3 0 0 0]
    secp256k1U128AccumMul(d, R, secp256k1U128ToU64(c));
    secp256k1U128Rshift(c, 64);
    verifyBits128(d, 115);
    verifyBits128(c, 48);

    /// [(c<<12) 0 0 0 0 0 d 0 0 0] = [p8 0 0 0 0 p3 0 0 0]
    t3 = (secp256k1U128ToU64(d) & M).toUnsigned64;
    secp256k1U128Rshift(d, 52);
    verifyBits(t3, 52);
    verifyBits128(d, 63);

    /// [(c<<12) 0 0 0 0 d t3 0 0 0] = [p8 0 0 0 0 p3 0 0 0]

    secp256k1U128AccumMul(d, a0, b[4]);
    secp256k1U128AccumMul(d, a1, b[3]);
    secp256k1U128AccumMul(d, a2, b[2]);
    secp256k1U128AccumMul(d, a3, b[1]);
    secp256k1U128AccumMul(d, a4, b[0]);
    verifyBits128(d, 115);

    /// [(c<<12) 0 0 0 0 d t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]
    secp256k1U128AccumMul(d, R << 12, secp256k1U128ToU64(c));
    verifyBits128(d, 116);

    /// [d t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]
    t4 = (secp256k1U128ToU64(d) & M).toUnsigned64;
    secp256k1U128Rshift(d, 52);
    verifyBits(t4, 52);
    verifyBits128(d, 64);

    /// [d t4 t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]
    tx = (t4 >> 48).toUnsigned64;
    t4 = (t4 & (M >> 4)).toUnsigned64;
    verifyBits(tx, 4);
    verifyBits(t4, 48);

    /// [d t4+(tx<<48) t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]

    secp256k1U128Mul(c, a0, b[0]);
    verifyBits128(c, 112);

    /// [d t4+(tx<<48) t3 0 0 c] = [p8 0 0 0 p4 p3 0 0 p0]
    secp256k1U128AccumMul(d, a1, b[4]);
    secp256k1U128AccumMul(d, a2, b[3]);
    secp256k1U128AccumMul(d, a3, b[2]);
    secp256k1U128AccumMul(d, a4, b[1]);
    verifyBits128(d, 114);

    /// [d t4+(tx<<48) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    u0 = (secp256k1U128ToU64(d) & M).toUnsigned64;
    secp256k1U128Rshift(d, 52);
    verifyBits(u0, 52);
    verifyBits128(d, 62);

    /// [d u0 t4+(tx<<48) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    /// [d 0 t4+(tx<<48)+(u0<<52) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    u0 = ((u0 << 4) | tx).toUnsigned64;
    verifyBits(u0, 56);

    /// [d 0 t4+(u0<<48) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    secp256k1U128AccumMul(c, u0, R >> 4);
    verifyBits128(c, 113);

    /// [d 0 t4 t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    r[0] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[0], 52);
    verifyBits128(c, 61);

    /// [d 0 t4 t3 0 c r0] = [p8 0 0 p5 p4 p3 0 0 p0]

    secp256k1U128AccumMul(c, a0, b[1]);
    secp256k1U128AccumMul(c, a1, b[0]);
    verifyBits128(c, 114);

    /// [d 0 t4 t3 0 c r0] = [p8 0 0 p5 p4 p3 0 p1 p0]
    secp256k1U128AccumMul(d, a2, b[4]);
    secp256k1U128AccumMul(d, a3, b[3]);
    secp256k1U128AccumMul(d, a4, b[2]);
    verifyBits128(d, 114);

    /// [d 0 t4 t3 0 c r0] = [p8 0 p6 p5 p4 p3 0 p1 p0]
    secp256k1U128AccumMul(c, secp256k1U128ToU64(d) & M, R);
    secp256k1U128Rshift(d, 52);
    verifyBits128(c, 115);
    verifyBits128(d, 62);

    /// [d 0 0 t4 t3 0 c r0] = [p8 0 p6 p5 p4 p3 0 p1 p0]
    r[1] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[1], 52);
    verifyBits128(c, 63);

    /// [d 0 0 t4 t3 c r1 r0] = [p8 0 p6 p5 p4 p3 0 p1 p0]

    secp256k1U128AccumMul(c, a0, b[2]);
    secp256k1U128AccumMul(c, a1, b[1]);
    secp256k1U128AccumMul(c, a2, b[0]);
    verifyBits128(c, 114);

    /// [d 0 0 t4 t3 c r1 r0] = [p8 0 p6 p5 p4 p3 p2 p1 p0]
    secp256k1U128AccumMul(d, a3, b[4]);
    secp256k1U128AccumMul(d, a4, b[3]);
    verifyBits128(d, 114);

    /// [d 0 0 t4 t3 c t1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    secp256k1U128AccumMul(c, R, secp256k1U128ToU64(d));
    secp256k1U128Rshift(d, 64);
    verifyBits128(c, 115);
    verifyBits128(d, 50);

    /// [(d<<12) 0 0 0 t4 t3 c r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]

    r[2] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[2], 52);
    verifyBits128(c, 63);

    /// [(d<<12) 0 0 0 t4 t3+c r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    secp256k1U128AccumMul(c, R << 12, secp256k1U128ToU64(d));
    secp256k1U128AccumU64(c, t3);
    verifyBits128(c, 100);

    /// [t4 c r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    r[3] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[3], 52);
    verifyBits128(c, 48);

    /// [t4+c r3 r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    r[4] = secp256k1U128ToU64(c) + t4;
    verifyBits(r[4], 49);

    /// [r4 r3 r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
  }

  static void _verifyBits(BigInt x, int n, String op) {
    _cond((x >> n) == BigInt.zero, op);
  }

  static void _verifyBits128(Secp256k1Uint128 x, int n, String op) {
    _cond(_secp256k1U128CheckBits(x, n, op) != 0, op);
  }

  static int _secp256k1U128CheckBits(Secp256k1Uint128 r, int n, String op) {
    _cond(n < 128, op);
    return (r.r >> n == BigInt.zero).toInt;
  }

  static void secp256k1FeSqr(Secp256k1Fe r, Secp256k1Fe a) {
    void verifyBits(BigInt x, int n) => _verifyBits(x, n, "secp256k1FeSqr");
    void verifyBits128(Secp256k1Uint128 x, int n) =>
        _verifyBits128(x, n, "secp256k1FeSqr");
    Secp256k1Uint128 c = Secp256k1Uint128(), d = Secp256k1Uint128();
    BigInt a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3], a4 = a[4];
    BigInt t3, t4, tx, u0;
    final M = Secp256k1Const.mask52, R = Secp256k1Const.bit33Mask;

    verifyBits(a[0], 56);
    verifyBits(a[1], 56);
    verifyBits(a[2], 56);
    verifyBits(a[3], 56);
    verifyBits(a[4], 52);

    secp256k1U128Mul(d, a0 * BigInt.two, a3);
    secp256k1U128AccumMul(d, a1 * BigInt.two, a2);
    verifyBits128(d, 114);

    /// [d 0 0 0] = [p3 0 0 0]
    secp256k1U128Mul(c, a4, a4);
    verifyBits128(c, 112);

    /// [c 0 0 0 0 d 0 0 0] = [p8 0 0 0 0 p3 0 0 0]
    secp256k1U128AccumMul(d, R, secp256k1U128ToU64(c));
    secp256k1U128Rshift(c, 64);
    verifyBits128(d, 115);
    verifyBits128(c, 48);

    /// [(c<<12) 0 0 0 0 0 d 0 0 0] = [p8 0 0 0 0 p3 0 0 0]
    t3 = (secp256k1U128ToU64(d) & M).toUnsigned64;
    secp256k1U128Rshift(d, 52);
    verifyBits(t3, 52);
    verifyBits128(d, 63);

    /// [(c<<12) 0 0 0 0 d t3 0 0 0] = [p8 0 0 0 0 p3 0 0 0]

    a4 = (a4 * BigInt.two).toUnsigned64;
    secp256k1U128AccumMul(d, a0, a4);
    secp256k1U128AccumMul(d, a1 * BigInt.two, a3);
    secp256k1U128AccumMul(d, a2, a2);
    verifyBits128(d, 115);

    /// [(c<<12) 0 0 0 0 d t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]
    secp256k1U128AccumMul(d, R << 12, secp256k1U128ToU64(c));
    verifyBits128(d, 116);

    /// [d t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]
    t4 = (secp256k1U128ToU64(d) & M).toUnsigned64;
    secp256k1U128Rshift(d, 52);
    verifyBits(t4, 52);
    verifyBits128(d, 64);

    /// [d t4 t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]
    tx = (t4 >> 48).toUnsigned64;
    t4 = (t4 & (M >> 4)).toUnsigned64;
    verifyBits(tx, 4);
    verifyBits(t4, 48);

    /// [d t4+(tx<<48) t3 0 0 0] = [p8 0 0 0 p4 p3 0 0 0]

    secp256k1U128Mul(c, a0, a0);
    verifyBits128(c, 112);

    /// [d t4+(tx<<48) t3 0 0 c] = [p8 0 0 0 p4 p3 0 0 p0]
    secp256k1U128AccumMul(d, a1, a4);
    secp256k1U128AccumMul(d, a2 * BigInt.two, a3);
    verifyBits128(d, 114);

    /// [d t4+(tx<<48) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    u0 = (secp256k1U128ToU64(d) & M).toUnsigned64;
    secp256k1U128Rshift(d, 52);
    verifyBits(u0, 52);
    verifyBits128(d, 62);

    /// [d u0 t4+(tx<<48) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    /// [d 0 t4+(tx<<48)+(u0<<52) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    u0 = ((u0 << 4) | tx).toUnsigned64;
    verifyBits(u0, 56);

    /// [d 0 t4+(u0<<48) t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    secp256k1U128AccumMul(c, u0, R >> 4);
    verifyBits128(c, 113);

    /// [d 0 t4 t3 0 0 c] = [p8 0 0 p5 p4 p3 0 0 p0]
    r[0] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[0], 52);
    verifyBits128(c, 61);

    /// [d 0 t4 t3 0 c r0] = [p8 0 0 p5 p4 p3 0 0 p0]

    a0 = (a0 * BigInt.two).toUnsigned64;
    secp256k1U128AccumMul(c, a0, a1);
    verifyBits128(c, 114);

    /// [d 0 t4 t3 0 c r0] = [p8 0 0 p5 p4 p3 0 p1 p0]
    secp256k1U128AccumMul(d, a2, a4);
    secp256k1U128AccumMul(d, a3, a3);
    verifyBits128(d, 114);

    /// [d 0 t4 t3 0 c r0] = [p8 0 p6 p5 p4 p3 0 p1 p0]
    secp256k1U128AccumMul(c, secp256k1U128ToU64(d) & M, R);
    secp256k1U128Rshift(d, 52);
    verifyBits128(c, 115);
    verifyBits128(d, 62);

    /// [d 0 0 t4 t3 0 c r0] = [p8 0 p6 p5 p4 p3 0 p1 p0]
    r[1] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[1], 52);
    verifyBits128(c, 63);

    /// [d 0 0 t4 t3 c r1 r0] = [p8 0 p6 p5 p4 p3 0 p1 p0]

    secp256k1U128AccumMul(c, a0, a2);
    secp256k1U128AccumMul(c, a1, a1);
    verifyBits128(c, 114);

    /// [d 0 0 t4 t3 c r1 r0] = [p8 0 p6 p5 p4 p3 p2 p1 p0]
    secp256k1U128AccumMul(d, a3, a4);
    verifyBits128(d, 114);

    /// [d 0 0 t4 t3 c r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    secp256k1U128AccumMul(c, R, secp256k1U128ToU64(d));
    secp256k1U128Rshift(d, 64);
    verifyBits128(c, 115);
    verifyBits128(d, 50);

    /// [(d<<12) 0 0 0 t4 t3 c r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    r[2] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[2], 52);
    verifyBits128(c, 63);

    /// [(d<<12) 0 0 0 t4 t3+c r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]

    secp256k1U128AccumMul(c, R << 12, secp256k1U128ToU64(d));
    secp256k1U128AccumU64(c, t3);
    verifyBits128(c, 100);

    /// [t4 c r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    r[3] = secp256k1U128ToU64(c) & M;
    secp256k1U128Rshift(c, 52);
    verifyBits(r[3], 52);
    verifyBits128(c, 48);

    /// [t4+c r3 r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
    r[4] = secp256k1U128ToU64(c) + t4;
    verifyBits(r[4], 49);

    /// [r4 r3 r2 r1 r0] = [p8 p7 p6 p5 p4 p3 p2 p1 p0]
  }

  static int secp256k1ScalarReduce(Secp256k1Scalar r, int overflow) {
    Secp256k1Uint128 t = Secp256k1Uint128();
    _cond(overflow <= 1, "secp256k1ScalarReduce");

    secp256k1U128FromU64(t, r[0]);
    secp256k1U128AccumU64(t, overflow.toBigInt * Secp256k1Const.secp256k1NC0);
    r[0] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[1]);
    secp256k1U128AccumU64(t, overflow.toBigInt * Secp256k1Const.secp256k1NC1);
    r[1] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[2]);
    secp256k1U128AccumU64(t, overflow.toBigInt * Secp256k1Const.secp256k1NC2);
    r[2] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[3]);
    r[3] = secp256k1U128ToU64(t);

    secp256k1ScalarVerify(r);
    return overflow;
  }

  static int secp256k1ScalarAdd(
      Secp256k1Scalar r, Secp256k1Scalar a, Secp256k1Scalar b) {
    int overflow;
    Secp256k1Uint128 t = Secp256k1Uint128();
    secp256k1ScalarVerify(a);
    secp256k1ScalarVerify(b);

    secp256k1U128FromU64(t, a[0]);
    secp256k1U128AccumU64(t, b[0]);
    r[0] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, a[1]);
    secp256k1U128AccumU64(t, b[1]);
    r[1] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, a[2]);
    secp256k1U128AccumU64(t, b[2]);
    r[2] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, a[3]);
    secp256k1U128AccumU64(t, b[3]);
    r[3] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    overflow = secp256k1U128ToU64(t).toInt() + secp256k1ScalarCheckOverflow(r);
    _cond(overflow == 0 || overflow == 1, "secp256k1ScalarAdd");
    secp256k1ScalarReduce(r, overflow);
    secp256k1ScalarVerify(r);
    return overflow.toInt();
  }

  static int secp256k1ScalarCheckOverflow(Secp256k1Scalar a) {
    int yes = 0;
    int no = 0;
    no |= (a[3] < Secp256k1Const.secp256k1n3).toInt;
    no |= (a[2] < Secp256k1Const.secp256k1n2).toInt;
    yes |= (a[2] > Secp256k1Const.secp256k1n2).toInt & ~no;
    no |= (a[1] < Secp256k1Const.secp256k1n1).toInt;
    yes |= (a[1] > Secp256k1Const.secp256k1n1).toInt & ~no;
    yes |= (a[0] >= Secp256k1Const.secp256k1n0).toInt & ~no;
    return yes;
  }

  static void secp256k1ScalarHalf(Secp256k1Scalar r, Secp256k1Scalar a) {
    BigInt mask = -(a[0] & BigInt.one);
    Secp256k1Uint128 t = Secp256k1Uint128();
    secp256k1ScalarVerify(a);

    secp256k1U128FromU64(t, (a[0] >> 1) | (a[1] << 63));
    secp256k1U128AccumU64(t, (Secp256k1Const.secp256k1NH0 + BigInt.one) & mask);
    r[0] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, (a[1] >> 1) | (a[2] << 63));
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1NH1 & mask);
    r[1] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, (a[2] >> 1) | (a[3] << 63));
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1NH2 & mask);
    r[2] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    r[3] = secp256k1U128ToU64(t) +
        (a[3] >> 1) +
        (Secp256k1Const.secp256k1NH3 & mask);
  }

  static void secp256k1ScalarMul512(
      List<BigInt> l8, Secp256k1Scalar a, Secp256k1Scalar b) {
    /// 160 bit accumulator.
    BigInt c0 = BigInt.zero, c1 = BigInt.zero;
    int c2 = 0;

    BigInt extractFast() {
      final n = c0;
      c0 = c1;
      c1 = BigInt.zero;
      _cond(c2 == 0, "secp256k1ScalarMul512");
      return n;
    }

    void muladd(BigInt a, BigInt b) {
      BigInt tl, th = BigInt.zero;
      Secp256k1Uint128 t = Secp256k1Uint128();
      secp256k1U128Mul(t, a, b);
      th = secp256k1U128HiU64(t);
      tl = secp256k1U128ToU64(t);
      c0 = (c0 + tl).toUnsigned64;
      th = (th + (c0 < tl).toBigInt).toUnsigned64;
      c1 = (c1 + th).toUnsigned64;
      c2 += (c1 < th).toInt;

      _cond((c1 >= th) || (c2 != 0), "secp256k1ScalarMul512");
    }

    void muladdFast(BigInt a, BigInt b) {
      BigInt tl, th = BigInt.zero;
      Secp256k1Uint128 t = Secp256k1Uint128();
      secp256k1U128Mul(t, a, b);
      th = secp256k1U128HiU64(t);
      tl = secp256k1U128ToU64(t);
      c0 = (c0 + tl).toUnsigned64;
      th = (th + (c0 < tl).toBigInt).toUnsigned64;
      c1 = (c1 + th).toUnsigned64;
    }

    BigInt extract() {
      final n = c0;
      c0 = c1;
      c1 = c2.toBigInt;
      c2 = 0;
      return n;
    }

    muladdFast(a[0], b[0]);
    l8[0] = extractFast();
    muladd(a[0], b[1]);
    muladd(a[1], b[0]);
    l8[1] = extract();
    muladd(a[0], b[2]);
    muladd(a[1], b[1]);
    muladd(a[2], b[0]);
    l8[2] = extract();
    muladd(a[0], b[3]);
    muladd(a[1], b[2]);
    muladd(a[2], b[1]);
    muladd(a[3], b[0]);
    l8[3] = extract();
    muladd(a[1], b[3]);
    muladd(a[2], b[2]);
    muladd(a[3], b[1]);
    l8[4] = extract();
    muladd(a[2], b[3]);
    muladd(a[3], b[2]);
    l8[5] = extract();
    muladdFast(a[3], b[3]);
    l8[6] = extractFast();
    _cond(c1 == BigInt.zero, "secp256k1ScalarMul512");
    l8[7] = c0;
  }

  static void secp256k1ScalarReduce512(Secp256k1Scalar r, List<BigInt> l) {
    Secp256k1Uint128 c128 = Secp256k1Uint128();
    BigInt c, c0, c1, c2;
    BigInt n0 = l[4], n1 = l[5], n2 = l[6], n3 = l[7];
    BigInt m0, m1, m2, m3, m4, m5;
    int m6;
    BigInt p0, p1, p2, p3;
    int p4;

    /// Reduce 512 bits into 385.
    /// m[0..6] = l[0..3] + n[0..3] * SECP256K1_N_C.
    c0 = l[0];
    c1 = BigInt.zero;
    c2 = BigInt.zero;
    BigInt extractFast() {
      final n = c0;
      c0 = c1;
      c1 = BigInt.zero;
      _cond(c2 == BigInt.zero, "secp256k1ScalarReduce512");
      return n;
    }

    void muladd(BigInt a, BigInt b) {
      BigInt tl, th = BigInt.zero;
      Secp256k1Uint128 t = Secp256k1Uint128();
      secp256k1U128Mul(t, a, b);
      th = secp256k1U128HiU64(t);
      tl = secp256k1U128ToU64(t);
      c0 = (c0 + tl).toUnsigned64;
      th = (th + (c0 < tl).toBigInt).toUnsigned64;
      c1 = (c1 + th).toUnsigned64;
      c2 = (c2 + (c1 < th).toBigInt).toUnsigned64;

      _cond((c1 >= th) || (c2 != BigInt.zero), "secp256k1ScalarReduce512");
    }

    void muladdFast(BigInt a, BigInt b) {
      BigInt tl, th = BigInt.zero;
      Secp256k1Uint128 t = Secp256k1Uint128();
      secp256k1U128Mul(t, a, b);
      th = secp256k1U128HiU64(t);
      tl = secp256k1U128ToU64(t);
      c0 = (c0 + tl).toUnsigned64;
      th = (th + (c0 < tl).toBigInt).toUnsigned64;
      c1 = (c1 + th).toUnsigned64;
    }

    BigInt extract() {
      final n = c0;
      c0 = c1;
      c1 = c2;
      c2 = BigInt.zero;
      return n;
    }

    void sumaddFast(BigInt a) {
      c0 = (c0 + a).toUnsigned64;
      c1 = (c1 + (c0 < a).toBigInt).toUnsigned64;
      _cond((c1 != BigInt.zero) | (c0 >= (a)), "secp256k1ScalarReduce512");
      _cond(c2 == BigInt.zero, "secp256k1ScalarReduce512");
    }

    void sumadd(BigInt a) {
      c0 = (c0 + a).toUnsigned64;
      BigInt over = (c0 < a).toBigInt;
      c1 = (c1 + over).toUnsigned64;
      c2 = (c2 + (c1 < over).toBigInt).toUnsigned64;
    }

    muladdFast(n0, Secp256k1Const.secp256k1NC0);
    m0 = extractFast();

    sumaddFast(l[1]);
    muladd(n1, Secp256k1Const.secp256k1NC0);
    muladd(n0, Secp256k1Const.secp256k1NC1);
    m1 = extract();
    sumadd(l[2]);
    muladd(n2, Secp256k1Const.secp256k1NC0);
    muladd(n1, Secp256k1Const.secp256k1NC1);
    sumadd(n0);
    m2 = extract();
    sumadd(l[3]);
    muladd(n3, Secp256k1Const.secp256k1NC0);
    muladd(n2, Secp256k1Const.secp256k1NC1);
    sumadd(n1);
    m3 = extract();
    muladd(n3, Secp256k1Const.secp256k1NC1);
    sumadd(n2);
    m4 = extract();
    sumaddFast(n3);
    m5 = extractFast();
    _cond(c0 <= BigInt.one, "secp256k1ScalarReduce512");
    m6 = c0.toUnSignedInt32;

    /// Reduce 385 bits into 258.
    /// p[0..4] = m[0..3] + m[4..6] * SECP256K1_N_C.
    c0 = m0;
    c1 = BigInt.zero;
    c2 = BigInt.zero;
    muladdFast(m4, Secp256k1Const.secp256k1NC0);
    p0 = extractFast();
    sumaddFast(m1);
    muladd(m5, Secp256k1Const.secp256k1NC0);
    muladd(m4, Secp256k1Const.secp256k1NC1);
    p1 = extract();
    sumadd(m2);
    muladd(m6.toBigInt, Secp256k1Const.secp256k1NC0);
    muladd(m5, Secp256k1Const.secp256k1NC1);
    sumadd(m4);
    p2 = extract();
    sumaddFast(m3);
    muladdFast(m6.toBigInt, Secp256k1Const.secp256k1NC1);
    sumaddFast(m5);
    p3 = extractFast();
    p4 = c0.toUnSignedInt32 + m6;
    _cond(p4 <= 2, "secp256k1ScalarReduce512");

    /// Reduce 258 bits into 256.
    /// r[0..3] = p[0..3] + p[4] * SECP256K1_N_C.
    secp256k1U128FromU64(c128, p0);
    secp256k1U128AccumMul(c128, Secp256k1Const.secp256k1NC0, p4.toBigInt);
    r[0] = secp256k1U128ToU64(c128);
    secp256k1U128Rshift(c128, 64);
    secp256k1U128AccumU64(c128, p1);
    secp256k1U128AccumMul(c128, Secp256k1Const.secp256k1NC1, p4.toBigInt);
    r[1] = secp256k1U128ToU64(c128);
    secp256k1U128Rshift(c128, 64);
    secp256k1U128AccumU64(c128, p2);
    secp256k1U128AccumU64(c128, p4.toBigInt);
    r[2] = secp256k1U128ToU64(c128);
    secp256k1U128Rshift(c128, 64);
    secp256k1U128AccumU64(c128, p3);
    r[3] = secp256k1U128ToU64(c128);
    c = secp256k1U128HiU64(c128);
    secp256k1ScalarReduce(
        r, c.toUnSignedInt32 + secp256k1ScalarCheckOverflow(r));
  }

  static void secp256k1ScalarSetInt(Secp256k1Scalar r, int v) {
    r[0] = v.toBigInt;
    r[1] = BigInt.zero;
    r[2] = BigInt.zero;
    r[3] = BigInt.zero;

    secp256k1ScalarVerify(r);
  }

  static int secp256k1ScalarGetBitsLimb32(
      Secp256k1Scalar a, int offset, int count) {
    secp256k1ScalarVerify(a);
    _cond(count > 0 && count <= 32, "secp256k1ScalarGetBitsLimb32");
    _cond((offset + count - 1) >> 6 == offset >> 6,
        "secp256k1ScalarGetBitsLimb32");
    final n = (a[offset >> 6] >> (offset & 0x3F)) &
        (0xFFFFFFFF >> (32 - count)).toBigInt;
    return n.toUnSignedInt32;
  }

  static int secp256k1ScalarGetBitsVar(
      Secp256k1Scalar a, int offset, int count) {
    secp256k1ScalarVerify(a);
    _cond(count > 0 && count <= 32, "secp256k1ScalarGetBitsVar");
    _cond(offset + count <= 256, "secp256k1ScalarGetBitsVar");

    if ((offset + count - 1) >> 6 == offset >> 6) {
      return secp256k1ScalarGetBitsLimb32(a, offset, count);
    } else {
      final n = ((a[offset >> 6] >> (offset & 0x3F)) |
              (a[(offset >> 6) + 1] << (64 - (offset & 0x3F)))) &
          (0xFFFFFFFF >> (32 - count)).toBigInt;
      _cond((offset >> 6) + 1 < 4, "secp256k1ScalarGetBitsVar");
      return n.toUnSignedInt32;
    }
  }

  static void secp256k1ScalarCaddBit(Secp256k1Scalar r, int bit, int flag) {
    Secp256k1Uint128 t = Secp256k1Uint128();
    int vflag = flag;
    secp256k1ScalarVerify(r);
    _cond(bit < 256, "secp256k1ScalarCaddBit");

    bit += (vflag - 1) & 0x100;
    secp256k1U128FromU64(t, r[0]);
    secp256k1U128AccumU64(t, (((bit >> 6) == 0)).toBigInt << (bit & 0x3F));
    r[0] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[1]);
    secp256k1U128AccumU64(t, (((bit >> 6) == 1)).toBigInt << (bit & 0x3F));
    r[1] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[2]);
    secp256k1U128AccumU64(t, (((bit >> 6) == 2)).toBigInt << (bit & 0x3F));
    r[2] = secp256k1U128ToU64(t);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[3]);
    secp256k1U128AccumU64(t, (((bit >> 6) == 3)).toBigInt << (bit & 0x3F));
    r[3] = secp256k1U128ToU64(t);

    secp256k1ScalarVerify(r);
    _cond(secp256k1U128HiU64(t) == BigInt.zero, "secp256k1ScalarCaddBit");
  }

  static BigInt _secp256k1ReadBe64(List<int> p, {int offset = 0}) {
    return p[offset + 0].toBigInt << 56 |
        p[offset + 1].toBigInt << 48 |
        p[offset + 2].toBigInt << 40 |
        p[offset + 3].toBigInt << 32 |
        p[offset + 4].toBigInt << 24 |
        p[offset + 5].toBigInt << 16 |
        p[offset + 6].toBigInt << 8 |
        p[offset + 7].toBigInt;
  }

  static void secp256k1ScalarSetB32(Secp256k1Scalar r, List<int> b32) {
    b32.asMin32("secp256k1ScalarSetB32", offset: 0);
    r[0] = _secp256k1ReadBe64(b32, offset: 24);
    r[1] = _secp256k1ReadBe64(b32, offset: 16);
    r[2] = _secp256k1ReadBe64(b32, offset: 8);
    r[3] = _secp256k1ReadBe64(b32);
    secp256k1ScalarReduce(r, secp256k1ScalarCheckOverflow(r));
  }

  static void _secp256k1WriteBe64(List<int> p, BigInt x, {int offset = 0}) {
    p[offset + 7] = x.toUnsignedInt8;
    p[offset + 6] = (x >> 8).toUnsignedInt8;
    p[offset + 5] = (x >> 16).toUnsignedInt8;
    p[offset + 4] = (x >> 24).toUnsignedInt8;
    p[offset + 3] = (x >> 32).toUnsignedInt8;
    p[offset + 2] = (x >> 40).toUnsignedInt8;
    p[offset + 1] = (x >> 48).toUnsignedInt8;
    p[offset + 0] = (x >> 56).toUnsignedInt8;
  }

  static void secp256k1ScalarGetB32(List<int> bin, Secp256k1Scalar a,
      {int offset = 0}) {
    bin.asMin32("secp256k1ScalarGetB32");
    secp256k1ScalarVerify(a);
    _secp256k1WriteBe64(bin, a[3], offset: offset + 0);
    _secp256k1WriteBe64(bin, a[2], offset: offset + 8);
    _secp256k1WriteBe64(bin, a[1], offset: offset + 16);
    _secp256k1WriteBe64(bin, a[0], offset: offset + 24);
  }

  static int secp256k1ScalarIsZero(Secp256k1Scalar a) {
    secp256k1ScalarVerify(a);
    return ((a[0] | a[1] | a[2] | a[3]) == BigInt.zero).toInt;
  }

  static void secp256k1ScalarNegate(Secp256k1Scalar r, Secp256k1Scalar a) {
    BigInt nonzero =
        (Secp256k1Const.secp256k1n3 * (secp256k1ScalarIsZero(a) == 0).toBigInt);
    Secp256k1Uint128 t = Secp256k1Uint128();
    secp256k1ScalarVerify(a);
    secp256k1U128FromU64(t, ~a[0]);
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1n0 + BigInt.one);
    r[0] = (secp256k1U128ToU64(t) & nonzero);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, ~a[1]);
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1n1);
    r[1] = (secp256k1U128ToU64(t) & nonzero);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, ~a[2]);
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1n2);
    r[2] = (secp256k1U128ToU64(t) & nonzero);
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, ~a[3]);
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1n3);
    r[3] = (secp256k1U128ToU64(t) & nonzero);
    secp256k1ScalarVerify(r);
  }

  static int secp256k1ScalarIsOne(Secp256k1Scalar a) {
    secp256k1ScalarVerify(a);
    return (((a[0] ^ BigInt.one) | a[1] | a[2] | a[3]) == BigInt.zero).toInt;
  }

  static int secp256k1ScalarIsHigh(Secp256k1Scalar a) {
    int yes = 0;
    int no = 0;
    secp256k1ScalarVerify(a);
    no |= (a[3] < Secp256k1Const.secp256k1NH3).toInt;
    yes |= (a[3] > Secp256k1Const.secp256k1NH3).toInt & ~no;
    no |= (a[2] < Secp256k1Const.secp256k1NH2).toInt & ~yes;
    no |= (a[1] < Secp256k1Const.secp256k1NH1).toInt & ~yes;
    yes |= (a[1] > Secp256k1Const.secp256k1NH1).toInt & ~no;
    yes |= (a[0] > Secp256k1Const.secp256k1NH0).toInt & ~no;
    return yes;
  }

  static int secp256k1ScalarCondNegate(Secp256k1Scalar r, int flag) {
    int vflag = flag;
    BigInt mask = (-vflag).toBigInt;
    BigInt nonzero = (secp256k1ScalarIsZero(r) != 0).toBigInt - BigInt.one;
    Secp256k1Uint128 t = Secp256k1Uint128();
    secp256k1ScalarVerify(r);

    secp256k1U128FromU64(t, r[0] ^ mask);
    secp256k1U128AccumU64(t, (Secp256k1Const.secp256k1n0 + BigInt.one) & mask);
    r[0] = secp256k1U128ToU64(t) & nonzero;
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[1] ^ mask);
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1n1 & mask);
    r[1] = secp256k1U128ToU64(t) & nonzero;
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[2] ^ mask);
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1n2 & mask);
    r[2] = secp256k1U128ToU64(t) & nonzero;
    secp256k1U128Rshift(t, 64);
    secp256k1U128AccumU64(t, r[3] ^ mask);
    secp256k1U128AccumU64(t, Secp256k1Const.secp256k1n3 & mask);
    r[3] = secp256k1U128ToU64(t) & nonzero;

    secp256k1ScalarVerify(r);
    return 2 * (mask == BigInt.zero).toInt - 1;
  }

  static void secp256k1ScalarMul(
      Secp256k1Scalar r, Secp256k1Scalar a, Secp256k1Scalar b) {
    List<BigInt> l = List.filled(8, BigInt.zero);
    secp256k1ScalarVerify(a);
    secp256k1ScalarVerify(b);

    secp256k1ScalarMul512(l, a, b);
    secp256k1ScalarReduce512(r, l);

    secp256k1ScalarVerify(r);
  }

  static int secp256k1ScalarEq(Secp256k1Scalar a, Secp256k1Scalar b) {
    secp256k1ScalarVerify(a);
    secp256k1ScalarVerify(b);
    final n = ((a[0] ^ b[0]) | (a[1] ^ b[1]) | (a[2] ^ b[2]) | (a[3] ^ b[3])) ==
        BigInt.zero;
    return n.toInt;
  }

  static void secp256k1ScalarMulShiftVar(
      Secp256k1Scalar r, Secp256k1Scalar a, Secp256k1Scalar b, int shift) {
    List<BigInt> l = List.filled(8, BigInt.zero);
    int shiftlimbs;
    int shiftlow;
    int shifthigh;
    secp256k1ScalarVerify(a);
    secp256k1ScalarVerify(b);
    _cond(shift >= 256, "secp256k1ScalarMulShiftVar");

    secp256k1ScalarMul512(l, a, b);
    shiftlimbs = shift >> 6;
    shiftlow = shift & 0x3F;
    shifthigh = 64 - shiftlow;

    r[0] = shift < 512
        ? (l[0 + shiftlimbs] >> shiftlow |
            (shift < 448 && shiftlow.toBool
                ? (l[1 + shiftlimbs] << shifthigh)
                : BigInt.zero))
        : BigInt.zero;
    r[1] = shift < 448
        ? (l[1 + shiftlimbs] >> shiftlow |
            (shift < 384 && shiftlow.toBool
                ? (l[2 + shiftlimbs] << shifthigh)
                : BigInt.zero))
        : BigInt.zero;
    r[2] = shift < 384
        ? (l[2 + shiftlimbs] >> shiftlow |
            (shift < 320 && shiftlow.toBool
                ? (l[3 + shiftlimbs] << shifthigh)
                : BigInt.zero))
        : BigInt.zero;
    r[3] = shift < 320 ? (l[3 + shiftlimbs] >> shiftlow) : BigInt.zero;
    secp256k1ScalarCaddBit(
        r,
        0,
        ((l[(shift - 1) >> 6] >> ((shift - 1) & 0x3f)) & BigInt.one)
            .toSignedInt32);

    secp256k1ScalarVerify(r);
  }

  static void secp256k1ScalarCmov(
      Secp256k1Scalar r, Secp256k1Scalar a, int flag) {
    BigInt mask0, mask1;
    int vflag = flag;
    secp256k1ScalarVerify(a);
    mask0 = vflag.toBigInt + maskBig64;
    mask1 = ~mask0;
    r[0] = (r[0] & mask0) | (a[0] & mask1);
    r[1] = (r[1] & mask0) | (a[1] & mask1);
    r[2] = (r[2] & mask0) | (a[2] & mask1);
    r[3] = (r[3] & mask0) | (a[3] & mask1);
  }

  static void secp256k1ScalarFromSigned62(
      Secp256k1Scalar r, Secp256k1ModinvSigned a) {
    BigInt a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3], a4 = a[4];

    _cond(a0 >> 62 == BigInt.zero, "secp256k1ScalarFromSigned62");
    _cond(a1 >> 62 == BigInt.zero, "secp256k1ScalarFromSigned62");
    _cond(a2 >> 62 == BigInt.zero, "secp256k1ScalarFromSigned62");
    _cond(a3 >> 62 == BigInt.zero, "secp256k1ScalarFromSigned62");
    _cond(a4 >> 8 == BigInt.zero, "secp256k1ScalarFromSigned62");

    r[0] = (a0 | a1 << 62).toUnsigned64;
    r[1] = (a1 >> 2 | a2 << 60).toUnsigned64;
    r[2] = (a2 >> 4 | a3 << 58).toUnsigned64;
    r[3] = (a3 >> 6 | a4 << 56).toUnsigned64;

    secp256k1ScalarVerify(r);
  }

  static void secp256k1ScalarToSigned62(
      Secp256k1ModinvSigned r, Secp256k1Scalar a) {
    final BigInt m62 = Secp256k1Const.mask62;
    BigInt a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3];
    secp256k1ScalarVerify(a);

    r[0] = a0 & m62;
    r[1] = ((a0 >> 62 | a1 << 2) & m62);
    r[2] = ((a1 >> 60 | a2 << 4) & m62);
    r[3] = ((a2 >> 58 | a3 << 6) & m62);
    r[4] = (a3 >> 56);
  }

  static void secp256k1ScalarInverse(Secp256k1Scalar r, Secp256k1Scalar x) {
    Secp256k1ModinvSigned s = Secp256k1ModinvSigned();
    int zeroIn = secp256k1ScalarIsZero(x);
    secp256k1ScalarVerify(x);

    secp256k1ScalarToSigned62(s, x);
    secp256k1Modinv64(s, Secp256k1Const.secp256k1ConstModinfoScalar);
    secp256k1ScalarFromSigned62(r, s);

    secp256k1ScalarVerify(r);
    _cond(secp256k1ScalarIsZero(r) == zeroIn, "secp256k1ScalarInverse");
  }

  static void secp256k1ScalarVerify(Secp256k1Scalar r) {
    _cond(secp256k1ScalarCheckOverflow(r) == 0, 'secp256k1ScalarVerify');
  }

  static void secp256k1ScalarInverseVar(Secp256k1Scalar r, Secp256k1Scalar x) {
    Secp256k1ModinvSigned s = Secp256k1ModinvSigned();
    secp256k1ScalarVerify(x);
    secp256k1ScalarToSigned62(s, x);
    secp256k1Modinv64Var(s, Secp256k1Const.secp256k1ConstModinfoScalar);
    secp256k1ScalarFromSigned62(r, s);
    secp256k1ScalarVerify(r);
  }

  static int secp256k1ScalarIsEven(Secp256k1Scalar a) {
    secp256k1ScalarVerify(a);
    final r = !(a[0] & BigInt.one).toBool;
    return r.toInt;
  }

  static void secp256k1I128FromI64(Secp256k1Int128 r, BigInt a) {
    // r.r = a.toSigned64;
    r.setS64(a);
  }

  static BigInt secp256k1I128ToU64(Secp256k1Int128 a) {
    return a.r.toUnsigned64;
  }

  static void secp256k1I128AccumMul(Secp256k1Int128 r, BigInt a, BigInt b) {
    final ml = (a * b).toSigned128;
    r.set(r.r + ml);
  }

  static void secp256k1I128Mul(Secp256k1Int128 r, BigInt a, BigInt b) {
    r.set(a * b);
  }

  static void secp256k1I128Rshift(Secp256k1Int128 r, int n) {
    _cond(n < 128, "secp256k1I128Rshift");
    // r.r = (r.r >>= n).toSigned128;
    r.set(r.r >> n);
  }

  static BigInt secp256k1I128ToI64(Secp256k1Int128 a) {
    /// Verify that a represents a 64 bit signed value by checking that the high bits are a sign extension of the low bits.
    return secp256k1I128ToU64(a).toSigned64;
  }

  static int secp256k1I128CheckPow2(Secp256k1Int128 r, int n, int sign) {
    _cond(n < 127, "secp256k1I128CheckPow2");
    _cond(sign == 1 || sign == -1, "secp256k1I128CheckPow2");
    return (r.r == ((sign.toBigInt << n).toUnsigned128).toSigned128).toInt;
  }

  static BigInt secp256k1Modinv64Abs(BigInt v) {
    // VERIFY_CHECK(v > INT64_MIN);
    if (v < BigInt.zero) return -v;
    return v;
  }

  static void secp256k1Modinv64Mul62(Secp256k1ModinvSigned r,
      Secp256k1ModinvSigned a, int alen, BigInt factor) {
    BigInt m62 = Secp256k1Const.mask62;
    Secp256k1Int128 c = Secp256k1Int128(), d = Secp256k1Int128();
    int i;
    secp256k1I128FromI64(c, BigInt.zero);
    for (i = 0; i < 4; ++i) {
      if (i < alen) secp256k1I128AccumMul(c, a[i], factor);
      r[i] = secp256k1I128ToU64(c) & m62;
      secp256k1I128Rshift(c, 62);
    }
    if (4 < alen) secp256k1I128AccumMul(c, a[4], factor);
    secp256k1I128FromI64(d, secp256k1I128ToI64(c));
    _cond(secp256k1I128EqVar(c, d) == 1, "secp256k1Modinv64Mul62");
    r[4] = secp256k1I128ToI64(c);
  }

  static int secp256k1I128EqVar(Secp256k1Int128 a, Secp256k1Int128 b) {
    return (a.r == b.r).toInt;
  }

  static int secp256k1Modinv64MulCmp62(Secp256k1ModinvSigned a, int alen,
      Secp256k1ModinvSigned b, BigInt factor) {
    int i;
    Secp256k1ModinvSigned am = Secp256k1ModinvSigned(),
        bm = Secp256k1ModinvSigned();
    secp256k1Modinv64Mul62(am, a, alen, BigInt.one);
    secp256k1Modinv64Mul62(bm, b, 5, factor);
    for (i = 0; i < 4; ++i) {
      /// Verify that all but the top limb of a and b are normalized.
      _cond(am[i] >> 62 == BigInt.zero, "secp256k1Modinv64MulCmp62");
      _cond(bm[i] >> 62 == BigInt.zero, "secp256k1Modinv64MulCmp62");
    }
    for (i = 4; i >= 0; --i) {
      if (am[i] < bm[i]) return -1;
      if (am[i] > bm[i]) return 1;
    }
    return 0;
  }

  static void secp256k1Modinv64Normalize62(
      Secp256k1ModinvSigned r, BigInt sign, Secp256k1ModinvInfo modinfo) {
    final BigInt m62 = Secp256k1Const.mask62;
    BigInt r0 = r[0], r1 = r[1], r2 = r[2], r3 = r[3], r4 = r[4];
    BigInt condAdd, condNegate;

    condAdd = (r4 >> 63).toSigned64;
    r0 = (r0 + (modinfo.modulus[0] & condAdd)).toSigned64;
    r1 = (r1 + (modinfo.modulus[1] & condAdd)).toSigned64;
    r2 = (r2 + (modinfo.modulus[2] & condAdd)).toSigned64;
    r3 = (r3 + (modinfo.modulus[3] & condAdd)).toSigned64;
    r4 = (r4 + (modinfo.modulus[4] & condAdd)).toSigned64;
    condNegate = sign >> 63;
    r0 = ((r0 ^ condNegate) - condNegate).toSigned64;
    r1 = ((r1 ^ condNegate) - condNegate).toSigned64;
    r2 = ((r2 ^ condNegate) - condNegate).toSigned64;
    r3 = ((r3 ^ condNegate) - condNegate).toSigned64;
    r4 = ((r4 ^ condNegate) - condNegate).toSigned64;

    /// Propagate the top bits, to bring limbs back to range (-2^62,2^62).
    r1 = (r1 + (r0 >> 62)).toSigned64;
    r0 = (r0 & m62).toSigned64;

    r2 = (r2 + (r1 >> 62)).toSigned64;
    r1 = (r1 & m62).toSigned64;

    r3 = (r3 + (r2 >> 62)).toSigned64;
    r2 = (r2 & m62).toSigned64;

    r4 = (r4 + (r3 >> 62)).toSigned64;
    r3 = (r3 & m62).toSigned64;

    condAdd = r4 >> 63;
    r0 = (r0 + (modinfo.modulus[0] & condAdd)).toSigned64;
    r1 = (r1 + (modinfo.modulus[1] & condAdd)).toSigned64;
    r2 = (r2 + (modinfo.modulus[2] & condAdd)).toSigned64;
    r3 = (r3 + (modinfo.modulus[3] & condAdd)).toSigned64;
    r4 = (r4 + (modinfo.modulus[4] & condAdd)).toSigned64;

    r1 = (r1 + (r0 >> 62)).toSigned64;
    r0 = (r0 & m62).toSigned64;

    r2 = (r2 + (r1 >> 62)).toSigned64;
    r1 = (r1 & m62).toSigned64;

    r3 = (r3 + (r2 >> 62)).toSigned64;
    r2 = (r2 & m62).toSigned64;

    r4 = (r4 + (r3 >> 62)).toSigned64;
    r3 = (r3 & m62).toSigned64;

    r[0] = r0;
    r[1] = r1;
    r[2] = r2;
    r[3] = r3;
    r[4] = r4;

    _cond(r0 >> 62 == BigInt.zero, "secp256k1Modinv64Normalize62");
    _cond(r1 >> 62 == BigInt.zero, "secp256k1Modinv64Normalize62");
    _cond(r2 >> 62 == BigInt.zero, "secp256k1Modinv64Normalize62");
    _cond(r3 >> 62 == BigInt.zero, "secp256k1Modinv64Normalize62");
    _cond(r4 >> 62 == BigInt.zero, "secp256k1Modinv64Normalize62");
    _cond(secp256k1Modinv64MulCmp62(r, 5, modinfo.modulus, BigInt.zero) >= 0,
        "secp256k1Modinv64Normalize62");
    _cond(secp256k1Modinv64MulCmp62(r, 5, modinfo.modulus, BigInt.one) < 0,
        "secp256k1Modinv64Normalize62");
  }

  static void secp256k1I128Det(
      Secp256k1Int128 r, BigInt a, BigInt b, BigInt c, BigInt d) {
    BigInt ad = (a * d).toSigned128;
    BigInt bc = (b * c).toSigned128;
    r.set(ad - bc);
  }

  static int secp256k1Modinv64DetCheckPow2(
      Secp256k1ModinvTrans t, int n, int abs) {
    Secp256k1Int128 a = Secp256k1Int128();
    secp256k1I128Det(a, t.u, t.v, t.q, t.r);
    if (secp256k1I128CheckPow2(a, n, 1).toBool) return 1;
    if (abs.toBool && secp256k1I128CheckPow2(a, n, -1).toBool) return 1;
    return 0;
  }

  static BigInt secp256k1Modinv64Divsteps59(
      BigInt zeta, BigInt f0, BigInt g0, Secp256k1ModinvTrans t) {
    BigInt u = 8.toBigInt, v = BigInt.zero, q = BigInt.zero, r = 8.toBigInt;
    BigInt c1, c2;
    BigInt mask1, mask2, f = f0, g = g0, x, y, z;
    int i;

    for (i = 3; i < 62; ++i) {
      _cond((f & BigInt.one).toUnsigned64 == BigInt.one,
          "secp256k1Modinv64Divsteps59");
      _cond((u * f0 + v * g0).toUnsigned64 == (f << i).toUnsigned64,
          "secp256k1Modinv64Divsteps59");
      _cond((q * f0 + r * g0).toUnsigned64 == (g << i).toUnsigned64,
          "secp256k1Modinv64Divsteps59");

      /// Compute conditional masks for (zeta < 0) and for (g & 1).
      c1 = (zeta >> 63).toUnsigned64;
      mask1 = c1;
      c2 = (g & BigInt.one).toUnsigned64;
      mask2 = (-c2).toUnsigned64;

      /// Compute x,y,z, conditionally negated versions of f,u,v.
      x = ((f ^ mask1) - mask1).toUnsigned64;
      y = ((u ^ mask1) - mask1).toUnsigned64;
      z = ((v ^ mask1) - mask1).toUnsigned64;

      /// Conditionally add x,y,z to g,q,r.
      g = (g + (x & mask2)).toUnsigned64;
      q = (q + (y & mask2)).toUnsigned64;
      r = (r + (z & mask2)).toUnsigned64;

      /// In what follows, c1 is a condition mask for (zeta < 0) and (g & 1).
      mask1 = (mask1 & mask2).toUnsigned64;

      /// Conditionally change zeta into -zeta-2 or zeta-1.
      zeta = ((zeta ^ mask1) - BigInt.one).toSigned64;

      /// Conditionally add g,q,r to f,u,v.
      f = (f + (g & mask1)).toUnsigned64;
      u = (u + (q & mask1)).toUnsigned64;
      v = (v + (r & mask1)).toUnsigned64;

      /// Shifts
      g = (g >> 1).toUnsigned64;
      u = (u << 1).toUnsigned64;
      v = (v << 1).toUnsigned64;

      /// Bounds on zeta that follow from the bounds on iteration count (max 10*59 divsteps).
      _cond(zeta >= -591.toBigInt && zeta <= 591.toBigInt,
          "secp256k1Modinv64Divsteps59");
    }

    /// Return data in t and return value.
    // t.u = u.toSigned64;
    // t.v = v.toSigned64;
    // t.q = q.toSigned64;
    // t.r = r.toSigned64;
    t.set(u, v, q, r);

    _cond(secp256k1Modinv64DetCheckPow2(t, 65, 0).toBool,
        "secp256k1Modinv64Divsteps59");

    return zeta;
  }

  static BigInt secp256k1Modinv64Divsteps62Var(
      BigInt eta, BigInt f0, BigInt g0, Secp256k1ModinvTrans t) {
    /// Transformation matrix; see comments in secp256k1_modinv64_divsteps_62.
    BigInt u = BigInt.one, v = BigInt.zero, q = BigInt.zero, r = BigInt.one;
    BigInt f = f0, g = g0, m;
    int w;
    int i = 62, limit, zeros;

    for (;;) {
      /// Use a sentinel bit to count zeros only up to i.
      zeros = secp256k1CtzVar((g | (maxU64 << i)).toUnsigned64);

      /// Perform zeros divsteps at once; they all just divide g by two.
      g = (g >> zeros).toUnsigned64;
      u = (u << zeros).toUnsigned64;
      v = (v << zeros).toUnsigned64;
      eta = (eta - zeros.toBigInt).toSigned64;
      i = (i - zeros).toSigned32;

      /// We're done once we've done 62 divsteps.
      if (i == 0) break;
      _cond((f & BigInt.one) == BigInt.one, "secp256k1Modinv64Divsteps62Var");
      _cond((g & BigInt.one) == BigInt.one, "secp256k1Modinv64Divsteps62Var");
      _cond((u * f0 + v * g0).toUnsigned64 == (f << (62 - i)).toUnsigned64,
          "secp256k1Modinv64Divsteps62Var");
      _cond((q * f0 + r * g0).toUnsigned64 == (g << (62 - i)).toUnsigned64,
          "secp256k1Modinv64Divsteps62Var");

      /// Bounds on eta that follow from the bounds on iteration count (max 12*62 divsteps).
      _cond(eta >= -745.toBigInt && eta <= 745.toBigInt,
          "secp256k1Modinv64Divsteps62Var");

      /// If eta is negative, negate it and replace f,g with g,-f.
      if (eta.isNegative) {
        BigInt tmp;
        eta = -eta;
        tmp = f;
        f = g;
        g = (-tmp).toUnsigned64;
        tmp = u;
        u = q;
        q = (-tmp).toUnsigned64;
        tmp = v;
        v = r;
        r = (-tmp).toUnsigned64;
        limit = (eta.toSignedInt32 + 1) > i ? i : (eta.toSignedInt32 + 1);
        // VERIFY_CHECK(limit > 0 && limit <= 62);
        /// m is a mask for the bottom min(limit, 6) bits.
        m = ((maxU64 >> (64 - limit)) & 63.toBigInt).toUnsigned64;

        w = ((f * g * (f * f - BigInt.two)) & m).toUnSignedInt32;
      } else {
        limit = (eta.toSignedInt32 + 1) > i ? i : (eta.toSignedInt32 + 1);
        _cond(limit > 0 && limit <= 62, "secp256k1Modinv64Divsteps62Var");

        /// m is a mask for the bottom min(limit, 4) bits.
        m = ((maxU64 >> (64 - limit)) & 15.toBigInt).toUnsigned64;

        w = (f + (((f + BigInt.one) & 4.toBigInt) << 1)).toUnSignedInt32;
        w = (((-w).toBigInt * g) & m).toUnSignedInt32;
      }
      g = (g + (f * w.toBigInt)).toUnsigned64;
      q = (q + (u * w.toBigInt)).toUnsigned64;
      r = (r + (v * w.toBigInt)).toUnsigned64;
      _cond((g & m) == BigInt.zero, "secp256k1Modinv64Divsteps62Var");
    }

    /// Return data in t and return value.
    // t.u = u.toSigned64;
    // t.v = v.toSigned64;
    // t.q = q.toSigned64;
    // t.r = r.toSigned64;
    t.set(u, v, q, r);

    _cond(secp256k1Modinv64DetCheckPow2(t, 62, 0).toBool,
        "secp256k1Modinv64Divsteps62Var");

    return eta;
  }

  static (BigInt, int) secp256k1Modinv64Posdivsteps62var(
      BigInt eta, BigInt f0, BigInt g0, Secp256k1ModinvTrans t, int jacp) {
    /// Transformation matrix; see comments in secp256k1_modinv64_divsteps_62.
    BigInt u = BigInt.one, v = BigInt.zero, q = BigInt.zero, r = BigInt.one;
    BigInt f = f0, g = g0, m;
    int w;
    int i = 62, limit, zeros;
    int jac = jacp;

    for (;;) {
      /// Use a sentinel bit to count zeros only up to i.
      zeros = secp256k1CtzVar(g | (maxU64 << i));

      /// Perform zeros divsteps at once; they all just divide g by two.
      g = (g >> zeros).toUnsigned64;
      u = (u << zeros).toUnsigned64;
      v = (v << zeros).toUnsigned64;
      eta = (eta - zeros.toBigInt).toSigned64;
      i -= zeros;

      jac = (jac ^ (zeros & ((f >> 1) ^ (f >> 2)).toSignedInt32));

      /// We're done once we've done 62 posdivsteps.
      if (i == 0) break;
      _cond(
          (f & BigInt.one) == BigInt.one, "secp256k1Modinv64Posdivsteps62var");
      _cond(
          (g & BigInt.one) == BigInt.one, "secp256k1Modinv64Posdivsteps62var");
      _cond((u * f0 + v * g0) == f << (62 - i),
          "secp256k1Modinv64Posdivsteps62var");
      _cond((q * f0 + r * g0) == g << (62 - i),
          "secp256k1Modinv64Posdivsteps62var");

      /// If eta is negative, negate it and replace f,g with g,f.
      if (eta < BigInt.zero) {
        BigInt tmp;
        eta = -eta;
        tmp = f;
        f = g;
        g = tmp;
        tmp = u;
        u = q;
        q = tmp;
        tmp = v;
        v = r;
        r = tmp;

        jac ^= ((f & g) >> 1).toSignedInt32;

        limit = (eta.toSignedInt32 + 1) > i ? i : (eta.toSignedInt32 + 1);
        _cond(limit > 0 && limit <= 62, "secp256k1Modinv64Posdivsteps62var");

        /// m is a mask for the bottom min(limit, 6) bits.
        m = ((maxU64 >> (64 - limit)) & 63.toBigInt).toUnsigned64;

        w = ((f * g * (f * f - BigInt.two)) & m).toUnSignedInt32;
      } else {
        limit = (eta.toSignedInt32 + 1) > i ? i : (eta.toSignedInt32 + 1);
        _cond(limit > 0 && limit <= 62, "secp256k1Modinv64Posdivsteps62var");

        /// m is a mask for the bottom min(limit, 4) bits.
        m = ((maxU64 >> (64 - limit)) & 15.toBigInt).toUnsigned64;

        w = (f + (((f + BigInt.one) & 4.toBigInt) << 1)).toUnSignedInt32;
        w = (((-w).toBigInt * g) & m).toUnSignedInt32;
      }
      g += f * w.toBigInt;
      q += u * w.toBigInt;
      r += v * w.toBigInt;
      _cond((g & m) == BigInt.zero, "secp256k1Modinv64Posdivsteps62var");
    }

    /// Return data in t and return value.
    // t.u = u.toSigned64;
    // t.v = v.toSigned64;
    // t.q = q.toSigned64;
    // t.r = r.toSigned64;

    t.set(u, v, q, r);

    _cond(secp256k1Modinv64DetCheckPow2(t, 62, 1).toBool,
        "secp256k1Modinv64Posdivsteps62var");

    return (eta, jac);
  }

  static void secp256k1Modinv64UpdateDe62(
      Secp256k1ModinvSigned d,
      Secp256k1ModinvSigned e,
      Secp256k1ModinvTrans t,
      Secp256k1ModinvInfo modinfo) {
    final BigInt m62 = Secp256k1Const.mask62;
    final BigInt d0 = d[0], d1 = d[1], d2 = d[2], d3 = d[3], d4 = d[4];
    final BigInt e0 = e[0], e1 = e[1], e2 = e[2], e3 = e[3], e4 = e[4];
    final BigInt u = t.u, v = t.v, q = t.q, r = t.r;
    BigInt md, me, sd, se;
    Secp256k1Int128 cd = Secp256k1Int128(), ce = Secp256k1Int128();
    _cond(secp256k1Modinv64MulCmp62(d, 5, modinfo.modulus, (-2).toBigInt) > 0,
        "secp256k1Modinv64UpdateDe62");
    _cond(secp256k1Modinv64MulCmp62(d, 5, modinfo.modulus, BigInt.one) < 0,
        "secp256k1Modinv64UpdateDe62");
    _cond(secp256k1Modinv64MulCmp62(e, 5, modinfo.modulus, (-2).toBigInt) > 0,
        "secp256k1Modinv64UpdateDe62");
    _cond(secp256k1Modinv64MulCmp62(e, 5, modinfo.modulus, BigInt.one) < 0,
        "secp256k1Modinv64UpdateDe62");
    _cond(
        secp256k1Modinv64Abs(u) <=
            ((BigInt.one << 62).toSigned64 - secp256k1Modinv64Abs(v)),
        "secp256k1Modinv64UpdateDe62");
    _cond(
        secp256k1Modinv64Abs(q) <=
            ((BigInt.one << 62).toSigned64 - secp256k1Modinv64Abs(r)),
        "secp256k1Modinv64UpdateDe62");

    /// [md,me] start as zero; plus [u,q] if d is negative; plus [v,r] if e is negative.
    sd = (d4 >> 63).toSigned64;
    se = (e4 >> 63).toSigned64;
    md = ((u & sd).toSigned64 + (v & se).toSigned64).toSigned64;
    me = ((q & sd).toSigned64 + (r & se).toSigned64).toSigned64;

    /// Begin computing t*[d,e].
    /// Begin computing t*[d,e].
    secp256k1I128Mul(cd, u, d0);
    secp256k1I128AccumMul(cd, v, e0);
    secp256k1I128Mul(ce, q, d0);
    secp256k1I128AccumMul(ce, r, e0);

    /// Correct md,me so that t*[d,e]+modulus*[md,me] has 62 zero bottom bits.
    md = (md -
            (((modinfo.modulusInv * secp256k1I128ToU64(cd)).toUnsigned64 + md) &
                m62))
        .toSigned64;
    me = (me -
            (((modinfo.modulusInv * secp256k1I128ToU64(ce)).toUnsigned64 + me) &
                m62))
        .toSigned64;

    /// Update the beginning of computation for t*[d,e]+modulus*[md,me] now md,me are known.
    secp256k1I128AccumMul(cd, modinfo.modulus[0], md);
    secp256k1I128AccumMul(ce, modinfo.modulus[0], me);

    /// Verify that the low 62 bits of the computation are indeed zero, and then throw them away.
    _cond((secp256k1I128ToU64(cd) & m62) == BigInt.zero,
        "secp256k1Modinv64UpdateDe62");
    secp256k1I128Rshift(cd, 62);
    _cond((secp256k1I128ToU64(ce) & m62) == BigInt.zero,
        "secp256k1Modinv64UpdateDe62");
    secp256k1I128Rshift(ce, 62);

    /// Compute limb 1 of t*[d,e]+modulus*[md,me], and store it as output limb 0 (= down shift).
    secp256k1I128AccumMul(cd, u, d1);
    secp256k1I128AccumMul(cd, v, e1);
    secp256k1I128AccumMul(ce, q, d1);
    secp256k1I128AccumMul(ce, r, e1);
    if (modinfo.modulus[1].toBool) {
      /// Optimize for the case where limb of modulus is zero.
      secp256k1I128AccumMul(cd, modinfo.modulus[1], md);
      secp256k1I128AccumMul(ce, modinfo.modulus[1], me);
    }
    d[0] = secp256k1I128ToU64(cd) & m62;
    secp256k1I128Rshift(cd, 62);
    e[0] = secp256k1I128ToU64(ce) & m62;
    secp256k1I128Rshift(ce, 62);

    /// Compute limb 2 of t*[d,e]+modulus*[md,me], and store it as output limb 1.
    secp256k1I128AccumMul(cd, u, d2);
    secp256k1I128AccumMul(cd, v, e2);
    secp256k1I128AccumMul(ce, q, d2);
    secp256k1I128AccumMul(ce, r, e2);
    if (modinfo.modulus[2].toBool) {
      /// Optimize for the case where limb of modulus is zero.
      secp256k1I128AccumMul(cd, modinfo.modulus[2], md);
      secp256k1I128AccumMul(ce, modinfo.modulus[2], me);
    }
    d[1] = secp256k1I128ToU64(cd) & m62;
    secp256k1I128Rshift(cd, 62);
    e[1] = secp256k1I128ToU64(ce) & m62;
    secp256k1I128Rshift(ce, 62);

    /// Compute limb 3 of t*[d,e]+modulus*[md,me], and store it as output limb 2.
    secp256k1I128AccumMul(cd, u, d3);
    secp256k1I128AccumMul(cd, v, e3);
    secp256k1I128AccumMul(ce, q, d3);
    secp256k1I128AccumMul(ce, r, e3);
    if (modinfo.modulus[3].toBool) {
      /// Optimize for the case where limb of modulus is zero.
      secp256k1I128AccumMul(cd, modinfo.modulus[3], md);
      secp256k1I128AccumMul(ce, modinfo.modulus[3], me);
    }
    d[2] = secp256k1I128ToU64(cd) & m62;
    secp256k1I128Rshift(cd, 62);
    e[2] = secp256k1I128ToU64(ce) & m62;
    secp256k1I128Rshift(ce, 62);

    /// Compute limb 4 of t*[d,e]+modulus*[md,me], and store it as output limb 3.
    secp256k1I128AccumMul(cd, u, d4);
    secp256k1I128AccumMul(cd, v, e4);
    secp256k1I128AccumMul(ce, q, d4);
    secp256k1I128AccumMul(ce, r, e4);
    secp256k1I128AccumMul(cd, modinfo.modulus[4], md);
    secp256k1I128AccumMul(ce, modinfo.modulus[4], me);
    d[3] = secp256k1I128ToU64(cd) & m62;
    secp256k1I128Rshift(cd, 62);
    e[3] = secp256k1I128ToU64(ce) & m62;
    secp256k1I128Rshift(ce, 62);

    /// What remains is limb 5 of t*[d,e]+modulus*[md,me]; store it as output limb 4.
    d[4] = secp256k1I128ToI64(cd);
    e[4] = secp256k1I128ToI64(ce);

    _cond(secp256k1Modinv64MulCmp62(d, 5, modinfo.modulus, (-2).toBigInt) > 0,
        "secp256k1Modinv64UpdateDe62");
    _cond(secp256k1Modinv64MulCmp62(d, 5, modinfo.modulus, BigInt.one) < 0,
        "secp256k1Modinv64UpdateDe62");
    _cond(secp256k1Modinv64MulCmp62(e, 5, modinfo.modulus, (-2).toBigInt) > 0,
        "secp256k1Modinv64UpdateDe62");
    _cond(secp256k1Modinv64MulCmp62(e, 5, modinfo.modulus, BigInt.one) < 0,
        "secp256k1Modinv64UpdateDe62");
  }

  static void secp256k1Modinv64UpdateFg62(Secp256k1ModinvSigned f,
      Secp256k1ModinvSigned g, Secp256k1ModinvTrans t) {
    final BigInt m62 = Secp256k1Const.mask62;

    final BigInt f0 = f[0], f1 = f[1], f2 = f[2], f3 = f[3], f4 = f[4];
    final BigInt g0 = g[0], g1 = g[1], g2 = g[2], g3 = g[3], g4 = g[4];
    final BigInt u = t.u, v = t.v, q = t.q, r = t.r;
    Secp256k1Int128 cf = Secp256k1Int128(), cg = Secp256k1Int128();

    /// Start computing t*[f,g].
    secp256k1I128Mul(cf, u, f0);
    secp256k1I128AccumMul(cf, v, g0);
    secp256k1I128Mul(cg, q, f0);
    secp256k1I128AccumMul(cg, r, g0);
    // /// Verify that the bottom 62 bits of the result are zero, and then throw them away.
    _cond((secp256k1I128ToU64(cf) & m62) == BigInt.zero,
        "secp256k1Modinv64UpdateFg62");
    secp256k1I128Rshift(cf, 62);
    _cond((secp256k1I128ToU64(cg) & m62) == BigInt.zero,
        "secp256k1Modinv64UpdateFg62");
    secp256k1I128Rshift(cg, 62);
    // /// Compute limb 1 of t*[f,g], and store it as output limb 0 (= down shift).
    secp256k1I128AccumMul(cf, u, f1);
    secp256k1I128AccumMul(cf, v, g1);
    secp256k1I128AccumMul(cg, q, f1);
    secp256k1I128AccumMul(cg, r, g1);
    f[0] = secp256k1I128ToU64(cf) & m62;
    secp256k1I128Rshift(cf, 62);
    g[0] = secp256k1I128ToU64(cg) & m62;
    secp256k1I128Rshift(cg, 62);

    /// Compute limb 2 of t*[f,g], and store it as output limb 1.
    secp256k1I128AccumMul(cf, u, f2);
    secp256k1I128AccumMul(cf, v, g2);
    secp256k1I128AccumMul(cg, q, f2);
    secp256k1I128AccumMul(cg, r, g2);
    f[1] = secp256k1I128ToU64(cf) & m62;
    secp256k1I128Rshift(cf, 62);
    g[1] = secp256k1I128ToU64(cg) & m62;
    secp256k1I128Rshift(cg, 62);

    /// Compute limb 3 of t*[f,g], and store it as output limb 2.
    secp256k1I128AccumMul(cf, u, f3);
    secp256k1I128AccumMul(cf, v, g3);
    secp256k1I128AccumMul(cg, q, f3);
    secp256k1I128AccumMul(cg, r, g3);
    f[2] = secp256k1I128ToU64(cf) & m62;
    secp256k1I128Rshift(cf, 62);
    g[2] = secp256k1I128ToU64(cg) & m62;
    secp256k1I128Rshift(cg, 62);

    /// Compute limb 4 of t*[f,g], and store it as output limb 3.
    secp256k1I128AccumMul(cf, u, f4);
    secp256k1I128AccumMul(cf, v, g4);
    secp256k1I128AccumMul(cg, q, f4);
    secp256k1I128AccumMul(cg, r, g4);
    f[3] = secp256k1I128ToU64(cf) & m62;
    secp256k1I128Rshift(cf, 62);
    g[3] = secp256k1I128ToU64(cg) & m62;
    secp256k1I128Rshift(cg, 62);

    /// What remains is limb 5 of t*[f,g]; store it as output limb 4.
    f[4] = secp256k1I128ToI64(cf);
    g[4] = secp256k1I128ToI64(cg);
  }

  static void secp256k1Modinv64UpdateFg62Var(int len, Secp256k1ModinvSigned f,
      Secp256k1ModinvSigned g, Secp256k1ModinvTrans t) {
    final BigInt m62 = Secp256k1Const.mask62;
    final BigInt u = t.u, v = t.v, q = t.q, r = t.r;
    BigInt fi, gi;
    Secp256k1Int128 cf = Secp256k1Int128(), cg = Secp256k1Int128();
    int i;
    _cond(len > 0, "secp256k1Modinv64UpdateFg62Var");

    /// Start computing t*[f,g].
    fi = f[0];
    gi = g[0];
    secp256k1I128Mul(cf, u, fi);
    secp256k1I128AccumMul(cf, v, gi);
    secp256k1I128Mul(cg, q, fi);
    secp256k1I128AccumMul(cg, r, gi);

    ///  Verify that the bottom 62 bits of the result are zero, and then throw them away.
    _cond((secp256k1I128ToU64(cf) & m62) == BigInt.zero,
        "secp256k1Modinv64UpdateFg62Var");
    secp256k1I128Rshift(cf, 62);
    _cond((secp256k1I128ToU64(cg) & m62) == BigInt.zero,
        "secp256k1Modinv64UpdateFg62Var");
    secp256k1I128Rshift(cg, 62);

    for (i = 1; i < len; ++i) {
      fi = f[i];
      gi = g[i];
      secp256k1I128AccumMul(cf, u, fi);
      secp256k1I128AccumMul(cf, v, gi);
      secp256k1I128AccumMul(cg, q, fi);
      secp256k1I128AccumMul(cg, r, gi);
      f[i - 1] = secp256k1I128ToU64(cf) & m62;
      secp256k1I128Rshift(cf, 62);
      g[i - 1] = secp256k1I128ToU64(cg) & m62;
      secp256k1I128Rshift(cg, 62);
    }

    /// What remains is limb (len) of t*[f,g]; store it as output limb (len-1).
    f[len - 1] = secp256k1I128ToI64(cf);
    g[len - 1] = secp256k1I128ToI64(cg);
  }

  static void secp256k1Modinv64(
      Secp256k1ModinvSigned x, Secp256k1ModinvInfo modinfo) {
    /// Start with d=0, e=1, f=modulus, g=x, zeta=-1.
    Secp256k1ModinvSigned d = Secp256k1ModinvSigned();
    Secp256k1ModinvSigned e = Secp256k1Const.modeInvOne.clone();
    Secp256k1ModinvSigned f = modinfo.modulus.clone();
    Secp256k1ModinvSigned g = x.clone();
    int i;
    BigInt zeta = (-1).toBigInt;

    /// Do 10 iterations of 59 divsteps each = 590 divsteps. This suffices for 256-bit inputs.
    for (i = 0; i < 10; ++i) {
      /// Compute transition matrix and new zeta after 59 divsteps.
      Secp256k1ModinvTrans t = Secp256k1ModinvTrans();
      zeta = secp256k1Modinv64Divsteps59(
          zeta, f[0].toUnsigned64, g[0].toUnsigned64, t);

      /// Update d,e using that transition matrix.
      secp256k1Modinv64UpdateDe62(d, e, t, modinfo);

      /// Update f,g using that transition matrix.
      _cond(
          secp256k1Modinv64MulCmp62(
                  f, 5, modinfo.modulus, Secp256k1Const.minosOne) >
              0,
          "secp256k1Modinv64");
      _cond(secp256k1Modinv64MulCmp62(f, 5, modinfo.modulus, BigInt.one) <= 0,
          "secp256k1Modinv64");
      _cond(
          secp256k1Modinv64MulCmp62(
                  g, 5, modinfo.modulus, Secp256k1Const.minosOne) >
              0,
          "secp256k1Modinv64");

      /// g > -modulus
      _cond(secp256k1Modinv64MulCmp62(g, 5, modinfo.modulus, BigInt.one) < 0,
          "secp256k1Modinv64");

      secp256k1Modinv64UpdateFg62(f, g, t);

      _cond(
          secp256k1Modinv64MulCmp62(
                  f, 5, modinfo.modulus, Secp256k1Const.minosOne) >
              0,
          "secp256k1Modinv64");

      /// f > -modulus
      _cond(secp256k1Modinv64MulCmp62(f, 5, modinfo.modulus, BigInt.one) <= 0,
          "secp256k1Modinv64");

      /// f <= modulus
      _cond(
          secp256k1Modinv64MulCmp62(
                  g, 5, modinfo.modulus, Secp256k1Const.minosOne) >
              0,
          "secp256k1Modinv64");

      /// g > -modulus
      _cond(secp256k1Modinv64MulCmp62(g, 5, modinfo.modulus, BigInt.one) < 0,
          "secp256k1Modinv64");

      /// g <  modulus
    }

    /// g == 0
    _cond(
        secp256k1Modinv64MulCmp62(
                g, 5, Secp256k1Const.secp256k1Signed62One, BigInt.zero) ==
            0,
        "secp256k1Modinv64");
    // /// |f| == 1, or (x == 0 and d == 0 and f == modulus)
    _cond(
        secp256k1Modinv64MulCmp62(f, 5, Secp256k1Const.secp256k1Signed62One,
                    Secp256k1Const.minosOne) ==
                0 ||
            secp256k1Modinv64MulCmp62(
                    f, 5, Secp256k1Const.secp256k1Signed62One, BigInt.one) ==
                0 ||
            (secp256k1Modinv64MulCmp62(x, 5,
                        Secp256k1Const.secp256k1Signed62One, BigInt.zero) ==
                    0 &&
                secp256k1Modinv64MulCmp62(d, 5,
                        Secp256k1Const.secp256k1Signed62One, BigInt.zero) ==
                    0 &&
                secp256k1Modinv64MulCmp62(f, 5, modinfo.modulus, BigInt.one) ==
                    0),
        "secp256k1Modinv64");

    /// Optionally negate d, normalize to [0,modulus), and return it.
    secp256k1Modinv64Normalize62(d, f[4], modinfo);
    x.set(d);
  }

  static void secp256k1Modinv64Var(
      Secp256k1ModinvSigned x, Secp256k1ModinvInfo modinfo) {
    Secp256k1ModinvSigned d = Secp256k1ModinvSigned();
    Secp256k1ModinvSigned e = Secp256k1Const.modeInvOne.clone();

    Secp256k1ModinvSigned f = modinfo.modulus.clone();
    Secp256k1ModinvSigned g = x.clone();

    int j, len = 5;
    BigInt eta = Secp256k1Const.minosOne;

    /// eta = -delta; delta is initially 1
    BigInt cond, fn, gn;

    /// Do iterations of 62 divsteps each until g=0.
    while (true) {
      /// Compute transition matrix and new eta after 62 divsteps.
      Secp256k1ModinvTrans t = Secp256k1ModinvTrans();
      eta = secp256k1Modinv64Divsteps62Var(
          eta, f[0].toUnsigned64, g[0].toUnsigned64, t);

      /// Update d,e using that transition matrix.
      secp256k1Modinv64UpdateDe62(d, e, t, modinfo);

      /// Update f,g using that transition matrix.
      _cond(
          secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, (-1).toBigInt) > 0,
          "secp256k1Modinv64Var");

      /// f > -modulus
      _cond(secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, BigInt.one) <= 0,
          "secp256k1Modinv64Var");

      /// f <= modulus
      _cond(
          secp256k1Modinv64MulCmp62(g, len, modinfo.modulus, (-1).toBigInt) > 0,
          "secp256k1Modinv64Var");

      /// g > -modulus
      _cond(secp256k1Modinv64MulCmp62(g, len, modinfo.modulus, BigInt.one) < 0,
          "secp256k1Modinv64Var");

      /// g <  modulus

      secp256k1Modinv64UpdateFg62Var(len, f, g, t);

      /// If the bottom limb of g is zero, there is a chance that g=0.
      if (g[0] == BigInt.zero) {
        cond = BigInt.zero;

        /// Check if the other limbs are also 0.
        for (j = 1; j < len; ++j) {
          cond = (cond | g[j]).toSigned64;
        }

        /// If so, we're done.
        if (cond == BigInt.zero) break;
      }

      /// Determine if len>1 and limb (len-1) of both f and g is 0 or -1.
      fn = f[len - 1];
      gn = g[len - 1];
      cond = ((len - 2).toBigInt >> 63).toSigned64;
      cond = (cond | (fn ^ (fn >> 63))).toSigned64;
      cond = (cond | (gn ^ (gn >> 63))).toSigned64;

      /// If so, reduce length, propagating the sign of f and g's top limb into the one below.
      if (cond == BigInt.zero) {
        f[len - 2] = (f[len - 2] | (fn.toUnsigned64 << 62)).toSigned64;
        g[len - 2] = (g[len - 2] | (gn.toUnsigned64 << 62)).toSigned64;
        --len;
      }
      _cond(
          secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, (-1).toBigInt) > 0,
          "secp256k1Modinv64Var");

      /// f > -modulus
      _cond(secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, BigInt.one) <= 0,
          "secp256k1Modinv64Var");

      /// f <= modulus
      _cond(
          secp256k1Modinv64MulCmp62(
                  g, len, modinfo.modulus, Secp256k1Const.minosOne) >
              0,
          "secp256k1Modinv64Var");

      /// g > -modulus
      _cond(secp256k1Modinv64MulCmp62(g, len, modinfo.modulus, BigInt.one) < 0,
          "secp256k1Modinv64Var");

      /// g <  modulus
    }

    /// g == 0
    _cond(
        secp256k1Modinv64MulCmp62(
                g, len, Secp256k1Const.secp256k1Signed62One, BigInt.zero) ==
            0,
        "secp256k1Modinv64Var");
    // /// |f| == 1, or (x == 0 and d == 0 and f == modulus)
    _cond(
        secp256k1Modinv64MulCmp62(f, len, Secp256k1Const.secp256k1Signed62One,
                    (-1).toBigInt) ==
                0 ||
            secp256k1Modinv64MulCmp62(
                    f, len, Secp256k1Const.secp256k1Signed62One, BigInt.one) ==
                0 ||
            (secp256k1Modinv64MulCmp62(x, 5,
                        Secp256k1Const.secp256k1Signed62One, BigInt.zero) ==
                    0 &&
                secp256k1Modinv64MulCmp62(d, 5,
                        Secp256k1Const.secp256k1Signed62One, BigInt.zero) ==
                    0 &&
                secp256k1Modinv64MulCmp62(
                        f, len, modinfo.modulus, BigInt.one) ==
                    0),
        "secp256k1Modinv64Var");

    /// Optionally negate d, normalize to [0,modulus), and return it.
    secp256k1Modinv64Normalize62(d, f[len - 1], modinfo);
    x.set(d);
  }

  /// Compute the Jacobi symbol of x modulo modinfo.modulus (variable time). gcd(x,modulus) must be 1.
  static int secp256k1Jacobi64MaybeVar(
      Secp256k1ModinvSigned x, Secp256k1ModinvInfo modinfo) {
    /// Start with f=modulus, g=x, eta=-1.
    Secp256k1ModinvSigned f = modinfo.modulus.clone();
    Secp256k1ModinvSigned g = x.clone();
    int j, len = 5;
    BigInt eta = Secp256k1Const.minosOne;

    /// eta = -delta; delta is initially 1
    BigInt cond, fn, gn;
    int jac = 0;
    int count;

    /// The input limbs must all be non-negative.
    _cond(
        g[0] >= BigInt.zero &&
            g[1] >= BigInt.zero &&
            g[2] >= BigInt.zero &&
            g[3] >= BigInt.zero &&
            g[4] >= BigInt.zero,
        "secp256k1Jacobi64MaybeVar");

    _cond((g[0] | g[1] | g[2] | g[3] | g[4]) != BigInt.zero,
        "secp256k1Jacobi64MaybeVar");

    for (count = 0; count < 12; ++count) {
      /// Compute transition matrix and new eta after 62 posdivsteps.
      Secp256k1ModinvTrans t = Secp256k1ModinvTrans();
      final etaR = secp256k1Modinv64Posdivsteps62var(
          eta,
          (f[0] | (f[1].toUnsigned64 << 62)).toUnsigned64,
          (g[0] | (g[1].toUnsigned64 << 62)).toUnsigned64,
          t,
          jac);
      eta = etaR.$1;
      jac = etaR.$2;

      /// Update f,g using that transition matrix.
      _cond(secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, BigInt.zero) > 0,
          "secp256k1Jacobi64MaybeVar");

      /// f > 0
      _cond(secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, BigInt.one) <= 0,
          "secp256k1Jacobi64MaybeVar");

      /// f <= modulus
      _cond(secp256k1Modinv64MulCmp62(g, len, modinfo.modulus, BigInt.zero) > 0,
          "secp256k1Jacobi64MaybeVar");

      /// g > 0
      _cond(secp256k1Modinv64MulCmp62(g, len, modinfo.modulus, BigInt.one) < 0,
          "secp256k1Jacobi64MaybeVar");

      /// g < modulus

      secp256k1Modinv64UpdateFg62Var(len, f, g, t);

      /// If the bottom limb of f is 1, there is a chance that f=1.
      if (f[0] == BigInt.one) {
        cond = BigInt.zero;

        /// Check if the other limbs are also 0.
        for (j = 1; j < len; ++j) {
          cond |= f[j];
        }

        /// If so, we're done. When f=1, the Jacobi symbol (g | f)=1.
        if (cond == BigInt.zero) return 1 - 2 * (jac & 1);
      }

      /// Determine if len>1 and limb (len-1) of both f and g is 0.
      fn = f[len - 1];
      gn = g[len - 1];
      cond = (len.toBigInt.toSigned64 - BigInt.two) >> 63;
      cond |= fn;
      cond |= gn;

      /// If so, reduce length.
      if (cond == BigInt.zero) --len;

      _cond(secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, BigInt.zero) > 0,
          "secp256k1Jacobi64MaybeVar");

      /// f > 0
      _cond(secp256k1Modinv64MulCmp62(f, len, modinfo.modulus, BigInt.one) <= 0,
          "secp256k1Jacobi64MaybeVar");

      /// f <= modulus
      _cond(secp256k1Modinv64MulCmp62(g, len, modinfo.modulus, BigInt.zero) > 0,
          "secp256k1Jacobi64MaybeVar");

      /// g > 0
      _cond(secp256k1Modinv64MulCmp62(g, len, modinfo.modulus, BigInt.one) < 0,
          "secp256k1Jacobi64MaybeVar");

      /// g < modulus
    }

    /// The loop failed to converge to f=g after 1550 iterations. Return 0, indicating unknown result.
    return 0;
  }

  static void secp256k1GeSetGejZinv(
      Secp256k1Ge r, Secp256k1Gej a, Secp256k1Fe zi) {
    Secp256k1Fe zi2 = Secp256k1Fe();
    Secp256k1Fe zi3 = Secp256k1Fe();
    _cond(a.infinity == 0, "secp256k1GeSetGejZinv");
    secp256k1FeSqr(zi2, zi);
    secp256k1FeMul(zi3, zi2, zi);
    secp256k1FeMul(r.x, a.x, zi2);
    secp256k1FeMul(r.y, a.y, zi3);
    r.infinity = a.infinity;
  }

  static void secp256k1GeSetGeZinv(
      Secp256k1Ge r, Secp256k1Ge a, Secp256k1Fe zi) {
    Secp256k1Fe zi2 = Secp256k1Fe();
    Secp256k1Fe zi3 = Secp256k1Fe();
    _cond(a.infinity == 0, "secp256k1GeSetGeZinv");

    secp256k1FeSqr(zi2, zi);
    secp256k1FeMul(zi3, zi2, zi);
    secp256k1FeMul(r.x, a.x, zi2);
    secp256k1FeMul(r.y, a.y, zi3);
    r.infinity = a.infinity;
  }

  static void secp256k1GeSetXy(Secp256k1Ge r, Secp256k1Fe x, Secp256k1Fe y) {
    r.infinity = 0;
    r.x = x.clone();
    r.y = y.clone();
  }

  static int secp256k1GeIsInfinity(Secp256k1Ge a) {
    _cond(a.infinity == 0 || a.infinity == 1, "secp256k1GeIsInfinity");
    return a.infinity;
  }

  static void secp256k1GeSetGejVar(Secp256k1Ge r, Secp256k1Gej a) {
    Secp256k1Fe z2 = Secp256k1Fe(), z3 = Secp256k1Fe();
    if (secp256k1GejIsInfinity(a).toBool) {
      secp256k1GeSetInfinity(r);
      return;
    }
    r.infinity = 0;
    secp256k1FeInvVar(a.z, a.z);
    secp256k1FeSqr(z2, a.z);
    secp256k1FeMul(z3, a.z, z2);
    secp256k1FeMul(a.x, a.x, z2);
    secp256k1FeMul(a.y, a.y, z3);
    secp256k1FeSetInt(a.z, 1);
    secp256k1GeSetXy(r, a.x, a.y);
  }

  static void secp256k1GeSetAllGej(
      List<Secp256k1Ge> r, List<Secp256k1Gej> a, int len) {
    Secp256k1Fe u = Secp256k1Fe();
    int i;
    for (i = 0; i < len; i++) {
      _cond(secp256k1GejIsInfinity(a[i]) == 0, "secp256k1GeSetAllGej");
    }
    if (len == 0) {
      return;
    }

    /// Use destination's x coordinates as scratch space
    r[0].x = a[0].z.clone();
    for (i = 1; i < len; i++) {
      secp256k1FeMul(r[i].x, r[i - 1].x, a[i].z);
    }
    secp256k1FeInv(u, r[len - 1].x);

    for (i = len - 1; i > 0; i--) {
      secp256k1FeMul(r[i].x, r[i - 1].x, u);
      secp256k1FeMul(u, u, a[i].z);
    }
    r[0].x = u.clone();

    for (i = 0; i < len; i++) {
      secp256k1GeSetGejZinv(r[i], a[i], r[i].x);
    }
  }

  static void secp256k1GeSetAllGejVar(
      List<Secp256k1Ge> r, List<Secp256k1Gej> a, int len) {
    Secp256k1Fe u = Secp256k1Fe();
    int i;
    int lastI = -1;

    for (i = 0; i < len; i++) {
      if (a[i].infinity.toBool) {
        secp256k1GeSetInfinity(r[i]);
      } else {
        /// Use destination's x coordinates as scratch space
        if (lastI == -1) {
          r[i].x = a[i].z.clone();
        } else {
          secp256k1FeMul(r[i].x, r[lastI].x, a[i].z);
        }
        lastI = i;
      }
    }
    if (lastI == -1) {
      return;
    }
    secp256k1FeInvVar(u, r[lastI].x);

    i = lastI;
    while (i > 0) {
      i--;
      if (!a[i].infinity.toBool) {
        secp256k1FeMul(r[lastI].x, r[i].x, u);
        secp256k1FeMul(u, u, a[lastI].z);
        lastI = i;
      }
    }
    _cond(a[lastI].infinity == 0, "secp256k1GeSetAllGejVar");
    r[lastI].x = u;

    for (i = 0; i < len; i++) {
      if (!a[i].infinity.toBool) {
        secp256k1GeSetGejZinv(r[i], a[i], r[i].x);
      }
    }
  }

  static void secp256k1GeTableSetGlobalz(
      int len, List<Secp256k1Ge> a, List<Secp256k1Fe> zr) {
    int i;
    Secp256k1Fe zs = Secp256k1Fe();
    if (len > 0) {
      i = len - 1;

      /// Ensure all y values are in weak normal form for fast negation of points
      secp256k1FeNormalizeWeak(a[i].y);
      zs = zr[i].clone();

      /// Work our way backwards, using the z-ratios to scale the x/y values.
      while (i > 0) {
        if (i != len - 1) {
          secp256k1FeMul(zs, zs, zr[i]);
        }
        i--;
        secp256k1GeSetGeZinv(a[i], a[i], zs);
      }
    }
  }

  static void secp256k1GejSetInfinity(Secp256k1Gej r) {
    r.infinity = 1;
    secp256k1FeSetInt(r.x, 0);
    secp256k1FeSetInt(r.y, 0);
    secp256k1FeSetInt(r.z, 0);
  }

  static void secp256k1GeSetInfinity(Secp256k1Ge r) {
    r.infinity = 1;
    secp256k1FeSetInt(r.x, 0);
    secp256k1FeSetInt(r.y, 0);
  }

  static int secp256k1GeSetXoVar(Secp256k1Ge r, Secp256k1Fe x, int odd) {
    Secp256k1Fe x2 = Secp256k1Fe(), x3 = Secp256k1Fe();
    int ret;

    r.x = x.clone();
    secp256k1FeSqr(x2, x);
    secp256k1FeMul(x3, x, x2);
    r.infinity = 0;
    secp256k1FeAddInt(x3, Secp256k1Const.secp256k1B);
    ret = secp256k1FeSqrt(r.y, x3);
    secp256k1FeNormalizeVar(r.y);
    if (secp256k1FeIsOdd(r.y) != odd) {
      secp256k1FeNegate(r.y, r.y, 1);
    }
    return ret;
  }

  static void secp256k1FeAddInt(Secp256k1Fe r, int a) {
    _cond(0 <= a && a <= 0x7FFF, "secp256k1FeAddInt");
    r[0] += a.toBigInt;
  }

  static int secp256k1FeIsOdd(Secp256k1Fe a) {
    return (a[0] & BigInt.one).toSignedInt32;
  }

  static void secp256k1GejSetGe(Secp256k1Gej r, Secp256k1Ge a) {
    r.infinity = a.infinity;
    r.x = a.x.clone();
    r.y = a.y.clone();
    secp256k1FeSetInt(r.z, 1);
  }

  static int secp256k1GejEqVar(Secp256k1Gej a, Secp256k1Gej b) {
    Secp256k1Gej tmp = Secp256k1Gej();
    secp256k1GejNeg(tmp, a);
    secp256k1GejAddVar(tmp, tmp, b, null);
    return secp256k1GejIsInfinity(tmp);
  }

  static int secp256k1GejEqGeVar(Secp256k1Gej a, Secp256k1Ge b) {
    Secp256k1Gej tmp = Secp256k1Gej();
    secp256k1GejNeg(tmp, a);
    secp256k1GejAddGeVar(tmp, tmp, b, null);
    return secp256k1GejIsInfinity(tmp);
  }

  static int secp256k1GeEqVar(Secp256k1Ge a, Secp256k1Ge b) {
    Secp256k1Fe tmp = Secp256k1Fe();
    if (a.infinity != b.infinity) return 0;
    if (a.infinity.toBool) return 1;

    tmp = a.x.clone();
    secp256k1FeNormalizeWeak(tmp);
    if (!secp256k1FeEqual(tmp, b.x).toBool) return 0;

    tmp = a.y.clone();
    secp256k1FeNormalizeWeak(tmp);
    if (!secp256k1FeEqual(tmp, b.y).toBool) return 0;

    return 1;
  }

  static int secp256k1GejEqXVar(Secp256k1Fe x, Secp256k1Gej a) {
    Secp256k1Fe r = Secp256k1Fe();
    _cond(a.infinity == 0, "secp256k1GejEqXVar");

    secp256k1FeSqr(r, a.z);
    secp256k1FeMul(r, r, x);
    return secp256k1FeEqual(r, a.x);
  }

  static void secp256k1GejNeg(Secp256k1Gej r, Secp256k1Gej a) {
    r.infinity = a.infinity;
    r.x = a.x.clone();
    r.y = a.y.clone();
    r.z = a.z.clone();
    secp256k1FeNormalizeWeak(r.y);
    secp256k1FeNegate(r.y, r.y, 1);
  }

  static int secp256k1GejIsInfinity(Secp256k1Gej a) {
    _cond(a.infinity == 0 || a.infinity == 1, "secp256k1GejIsInfinity");
    return a.infinity;
  }

  static int secp256k1GeIsValidVar(Secp256k1Ge a) {
    Secp256k1Fe y2 = Secp256k1Fe(), x3 = Secp256k1Fe();
    if (a.infinity.toBool) {
      return 0;
    }

    /// y^2 = x^3 + 7
    secp256k1FeSqr(y2, a.y);
    secp256k1FeSqr(x3, a.x);
    secp256k1FeMul(x3, x3, a.x);
    secp256k1FeAddInt(x3, Secp256k1Const.secp256k1B);
    return secp256k1FeEqual(y2, x3);
  }

  static void secp256k1GejDouble(Secp256k1Gej r, Secp256k1Gej a) {
    /// Operations: 3 mul, 4 sqr, 8 add/half/mul_int/negate
    Secp256k1Fe l = Secp256k1Fe(), s = Secp256k1Fe(), t = Secp256k1Fe();
    r.infinity = a.infinity;

    secp256k1FeMul(r.z, a.z, a.y);
    secp256k1FeSqr(s, a.y);
    secp256k1FeSqr(l, a.x);
    secp256k1FeMulInt(l, 3);
    secp256k1FeHalf(l);
    secp256k1FeNegate(t, s, 1);
    secp256k1FeMul(t, t, a.x);
    secp256k1FeSqr(r.x, l);
    secp256k1FeAdd(r.x, t);
    secp256k1FeAdd(r.x, t);
    secp256k1FeSqr(s, s);
    secp256k1FeAdd(t, r.x);
    secp256k1FeMul(r.y, t, l);
    secp256k1FeAdd(r.y, s);
    secp256k1FeNegate(r.y, r.y, 2);
  }

  static void secp256k1GejDoubleVar(
      Secp256k1Gej r, Secp256k1Gej a, Secp256k1Fe? rzr) {
    /// For secp256k1, 2Q is infinity if and only if Q is infinity. This is because if 2Q = infinity,
    ///  Q must equal -Q, or that Q.y == -(Q.y), or Q.y is 0. For a point on y^2 = x^3 + 7 to have
    ///  y=0, x^3 must be -7 mod p. However, -7 has no cube root mod p.
    ///
    ///  Having said this, if this function receives a point on a sextic twist, e.g. by
    ///  a fault attack, it is possible for y to be 0. This happens for y^2 = x^3 + 6,
    ///  since -6 does have a cube root mod p. For this point, this function will not set
    ///  the infinity flag even though the point doubles to infinity, and the result
    ///  point will be gibberish (z = 0 but infinity = 0).
    ///
    if (a.infinity.toBool) {
      secp256k1GejSetInfinity(r);
      if (rzr != null) {
        secp256k1FeSetInt(rzr, 1);
      }
      return;
    }

    if (rzr != null) {
      rzr.set(a.y);
      secp256k1FeNormalizeWeak(rzr);
    }

    secp256k1GejDouble(r, a);
  }

  static void secp256k1GejAddVar(
      Secp256k1Gej r, Secp256k1Gej a, Secp256k1Gej b, Secp256k1Fe? rzr) {
    /// 12 mul, 4 sqr, 11 add/negate/normalizes_to_zero (ignoring special cases)
    Secp256k1Fe z22 = Secp256k1Fe(),
        z12 = Secp256k1Fe(),
        u1 = Secp256k1Fe(),
        u2 = Secp256k1Fe(),
        s1 = Secp256k1Fe(),
        s2 = Secp256k1Fe(),
        h = Secp256k1Fe(),
        i = Secp256k1Fe(),
        h2 = Secp256k1Fe(),
        h3 = Secp256k1Fe(),
        t = Secp256k1Fe();
    if (a.infinity.toBool) {
      _cond(rzr == null, "secp256k1GejAddVar");
      r.set(b);
      return;
    }
    if (b.infinity.toBool) {
      if (rzr != null) {
        secp256k1FeSetInt(rzr, 1);
      }
      r.set(a);
      return;
    }

    secp256k1FeSqr(z22, b.z);
    secp256k1FeSqr(z12, a.z);
    secp256k1FeMul(u1, a.x, z22);
    secp256k1FeMul(u2, b.x, z12);
    secp256k1FeMul(s1, a.y, z22);
    secp256k1FeMul(s1, s1, b.z);
    secp256k1FeMul(s2, b.y, z12);
    secp256k1FeMul(s2, s2, a.z);
    secp256k1FeNegate(h, u1, 1);
    secp256k1FeAdd(h, u2);
    secp256k1FeNegate(i, s2, 1);
    secp256k1FeAdd(i, s1);
    if (secp256k1FeNormalizesToZeroVar(h).toBool) {
      if (secp256k1FeNormalizesToZeroVar(i).toBool) {
        secp256k1GejDoubleVar(r, a, rzr);
      } else {
        if (rzr != null) {
          secp256k1FeSetInt(rzr, 0);
        }
        secp256k1GejSetInfinity(r);
      }
      return;
    }

    r.infinity = 0;
    secp256k1FeMul(t, h, b.z);
    if (rzr != null) {
      rzr.set(t);
    }
    secp256k1FeMul(r.z, a.z, t);

    secp256k1FeSqr(h2, h);
    secp256k1FeNegate(h2, h2, 1);
    secp256k1FeMul(h3, h2, h);
    secp256k1FeMul(t, u1, h2);

    secp256k1FeSqr(r.x, i);
    secp256k1FeAdd(r.x, h3);
    secp256k1FeAdd(r.x, t);
    secp256k1FeAdd(r.x, t);

    secp256k1FeAdd(t, r.x);
    secp256k1FeMul(r.y, t, i);
    secp256k1FeMul(h3, h3, s1);
    secp256k1FeAdd(r.y, h3);
  }

  static void secp256k1GejAddGeVar(
      Secp256k1Gej r, Secp256k1Gej a, Secp256k1Ge b, Secp256k1Fe? rzr) {
    /// Operations: 8 mul, 3 sqr, 11 add/negate/normalizes_to_zero (ignoring special cases)
    Secp256k1Fe z12 = Secp256k1Fe(),
        u1 = Secp256k1Fe(),
        u2 = Secp256k1Fe(),
        s1 = Secp256k1Fe(),
        s2 = Secp256k1Fe(),
        h = Secp256k1Fe(),
        i = Secp256k1Fe(),
        h2 = Secp256k1Fe(),
        h3 = Secp256k1Fe(),
        t = Secp256k1Fe();
    if (a.infinity.toBool) {
      (rzr == null);
      secp256k1GejSetGe(r, b);
      return;
    }
    if (b.infinity.toBool) {
      if (rzr != null) {
        secp256k1FeSetInt(rzr, 1);
      }
      r.set(a);
      return;
    }

    secp256k1FeSqr(z12, a.z);
    u1 = a.x.clone();
    secp256k1FeMul(u2, b.x, z12);
    s1 = a.y.clone();
    secp256k1FeMul(s2, b.y, z12);
    secp256k1FeMul(s2, s2, a.z);
    secp256k1FeNegate(h, u1, Secp256k1Const.secp256k1GejXMagnitudeMax);
    secp256k1FeAdd(h, u2);
    secp256k1FeNegate(i, s2, 1);
    secp256k1FeAdd(i, s1);
    if (secp256k1FeNormalizesToZeroVar(h).toBool) {
      if (secp256k1FeNormalizesToZeroVar(i).toBool) {
        secp256k1GejDoubleVar(r, a, rzr);
      } else {
        if (rzr != null) {
          secp256k1FeSetInt(rzr, 0);
        }
        secp256k1GejSetInfinity(r);
      }
      return;
    }

    r.infinity = 0;
    if (rzr != null) {
      rzr.set(h);
    }
    secp256k1FeMul(r.z, a.z, h);

    secp256k1FeSqr(h2, h);
    secp256k1FeNegate(h2, h2, 1);
    secp256k1FeMul(h3, h2, h);
    secp256k1FeMul(t, u1, h2);

    secp256k1FeSqr(r.x, i);
    secp256k1FeAdd(r.x, h3);
    secp256k1FeAdd(r.x, t);
    secp256k1FeAdd(r.x, t);

    secp256k1FeAdd(t, r.x);
    secp256k1FeMul(r.y, t, i);
    secp256k1FeMul(h3, h3, s1);
    secp256k1FeAdd(r.y, h3);
  }

  static void secp256k1GejAddZinvVar(
      Secp256k1Gej r, Secp256k1Gej a, Secp256k1Ge b, Secp256k1Fe bzinv) {
    /// Operations: 9 mul, 3 sqr, 11 add/negate/normalizes_to_zero (ignoring special cases)
    Secp256k1Fe az = Secp256k1Fe(),
        z12 = Secp256k1Fe(),
        u1 = Secp256k1Fe(),
        u2 = Secp256k1Fe(),
        s1 = Secp256k1Fe(),
        s2 = Secp256k1Fe(),
        h = Secp256k1Fe(),
        i = Secp256k1Fe(),
        h2 = Secp256k1Fe(),
        h3 = Secp256k1Fe(),
        t = Secp256k1Fe();

    if (a.infinity.toBool) {
      Secp256k1Fe bzinv2 = Secp256k1Fe(), bzinv3 = Secp256k1Fe();
      r.infinity = b.infinity;
      secp256k1FeSqr(bzinv2, bzinv);
      secp256k1FeMul(bzinv3, bzinv2, bzinv);
      secp256k1FeMul(r.x, b.x, bzinv2);
      secp256k1FeMul(r.y, b.y, bzinv3);
      secp256k1FeSetInt(r.z, 1);
      return;
    }
    if (b.infinity.toBool) {
      r.set(a);
      return;
    }

    /// We need to calculate (rx,ry,rz) = (ax,ay,az) + (bx,by,1/bzinv). Due to
    /// secp256k1's isomorphism we can multiply the Z coordinates on both sides
    ///  by bzinv, and get: (rx,ry,rz*bzinv) = (ax,ay,az*bzinv) + (bx,by,1).
    ///  This means that (rx,ry,rz) can be calculated as
    /// (ax,ay,az*bzinv) + (bx,by,1), when not applying the bzinv factor to rz.
    /// The variable az below holds the modified Z coordinate for a, which is used
    /// for the computation of rx and ry, but not for rz.
    ///
    secp256k1FeMul(az, a.z, bzinv);

    secp256k1FeSqr(z12, az);
    u1 = a.x.clone();
    secp256k1FeMul(u2, b.x, z12);
    s1 = a.y.clone();
    secp256k1FeMul(s2, b.y, z12);
    secp256k1FeMul(s2, s2, az);
    secp256k1FeNegate(h, u1, Secp256k1Const.secp256k1GejXMagnitudeMax);
    secp256k1FeAdd(h, u2);
    secp256k1FeNegate(i, s2, 1);
    secp256k1FeAdd(i, s1);
    if (secp256k1FeNormalizesToZeroVar(h).toBool) {
      if (secp256k1FeNormalizesToZeroVar(i).toBool) {
        secp256k1GejDoubleVar(r, a, null);
      } else {
        secp256k1GejSetInfinity(r);
      }
      return;
    }

    r.infinity = 0;
    secp256k1FeMul(r.z, a.z, h);

    secp256k1FeSqr(h2, h);
    secp256k1FeNegate(h2, h2, 1);
    secp256k1FeMul(h3, h2, h);
    secp256k1FeMul(t, u1, h2);

    secp256k1FeSqr(r.x, i);
    secp256k1FeAdd(r.x, h3);
    secp256k1FeAdd(r.x, t);
    secp256k1FeAdd(r.x, t);

    secp256k1FeAdd(t, r.x);
    secp256k1FeMul(r.y, t, i);
    secp256k1FeMul(h3, h3, s1);
    secp256k1FeAdd(r.y, h3);
  }

  static void secp256k1GejAddGe(Secp256k1Gej r, Secp256k1Gej a, Secp256k1Ge b) {
    /// Operations: 7 mul, 5 sqr, 21 add/cmov/half/mul_int/negate/normalizes_to_zero
    Secp256k1Fe zz = Secp256k1Fe(),
        u1 = Secp256k1Fe(),
        u2 = Secp256k1Fe(),
        s1 = Secp256k1Fe(),
        s2 = Secp256k1Fe(),
        t = Secp256k1Fe(),
        tt = Secp256k1Fe(),
        m = Secp256k1Fe(),
        n = Secp256k1Fe(),
        q = Secp256k1Fe(),
        rr = Secp256k1Fe();
    Secp256k1Fe mAlt = Secp256k1Fe(), rrAlt = Secp256k1Fe();
    int degenerate;
    _cond(b.infinity == 0, "secp256k1GejAddGe");

    secp256k1FeSqr(zz, a.z);
    u1 = a.x.clone();
    secp256k1FeMul(u2, b.x, zz);
    s1 = a.y.clone();
    secp256k1FeMul(s2, b.y, zz);
    secp256k1FeMul(s2, s2, a.z);
    t = u1.clone();
    secp256k1FeAdd(t, u2);
    m = s1.clone();
    secp256k1FeAdd(m, s2);
    secp256k1FeSqr(rr, t);
    secp256k1FeNegate(mAlt, u2, 1);
    secp256k1FeMul(tt, u1, mAlt);
    secp256k1FeAdd(rr, tt);

    degenerate = secp256k1FeNormalizesToZero(m);

    rrAlt = s1.clone();
    secp256k1FeMulInt(rrAlt, 2);
    secp256k1FeAdd(mAlt, u1);

    secp256k1FeCmov(rrAlt, rr, (!degenerate.toBool).toInt);
    secp256k1FeCmov(mAlt, m, (!degenerate.toBool).toInt);

    secp256k1FeSqr(n, mAlt);
    secp256k1FeNegate(q, t, Secp256k1Const.secp256k1GejXMagnitudeMax + 1);
    secp256k1FeMul(q, q, n);

    secp256k1FeSqr(n, n);
    secp256k1FeCmov(n, m, degenerate);
    secp256k1FeSqr(t, rrAlt);
    secp256k1FeMul(r.z, a.z, mAlt);
    secp256k1FeAdd(t, q);
    r.x = t.clone();
    secp256k1FeMulInt(t, 2);
    secp256k1FeAdd(t, q);
    secp256k1FeMul(t, t, rrAlt);
    secp256k1FeAdd(t, n);
    secp256k1FeNegate(r.y, t, Secp256k1Const.secp256k1GejYMagnitudeMax + 2);
    secp256k1FeHalf(r.y);

    /// In case a.infinity == 1, replace r with (b.x, b.y, 1).
    secp256k1FeCmov(r.x, b.x, a.infinity);
    secp256k1FeCmov(r.y, b.y, a.infinity);
    secp256k1FeCmov(r.z, Secp256k1Const.secp256k1FeOne, a.infinity);
    r.infinity = secp256k1FeNormalizesToZero(r.z);
  }

  static int secp256k1Rotr32(int x, int by) {
    /// Reduce rotation amount to avoid UB when shifting.
    const int mask = 8 * 4 - 1;

    /// Turned into a rot instruction by GCC and clang.
    return ((x >> (by & mask)).toUnSigned32 |
            (x << ((-by) & mask)).toUnSigned32)
        .toUnSigned32;
  }

  static void secp256k1ECmultGen(
      Secp256k1ECmultGenContext ctx, Secp256k1Gej r, Secp256k1Scalar gn) {
    int combOff;
    Secp256k1Ge add = Secp256k1Ge();
    Secp256k1Fe neg = Secp256k1Fe();
    Secp256k1GeStorage adds = Secp256k1GeStorage();
    Secp256k1Scalar d = Secp256k1Scalar();
    List<int> recoded = List.filled((Secp256k1Const.combBits + 31) >> 5, 0);
    int first = 1, i;

    /// Compute the scalar d = (gn + ctx->scalarOffset).
    secp256k1ScalarAdd(d, ctx.scalarOffset, gn);

    /// Convert to recoded array.
    for (i = 0; i < 8 && i < (Secp256k1Const.combBits + 31) >> 5; ++i) {
      recoded[i] = secp256k1ScalarGetBitsLimb32(d, 32 * i, 32);
    }

    /// Outer loop: iterate over combOff from combSpacing - 1 down to 0.
    const int combSpacing = 1;
    const int combPoints = 32;
    combOff = combSpacing - 1;
    const int combBlocks = 43;
    const int combTeeth = 6;
    List<List<Secp256k1GeStorage>> secp256k1ECmultGenPrecTable = tables
        .map((e) => e
            .map((e) => Secp256k1GeStorage.constants(
                BigInt.from(e[0]),
                BigInt.from(e[1]),
                BigInt.from(e[2]),
                BigInt.from(e[3]),
                BigInt.from(e[4]),
                BigInt.from(e[5]),
                BigInt.from(e[6]),
                BigInt.from(e[7]),
                BigInt.from(e[8]),
                BigInt.from(e[9]),
                BigInt.from(e[10]),
                BigInt.from(e[11]),
                BigInt.from(e[12]),
                BigInt.from(e[13]),
                BigInt.from(e[14]),
                BigInt.from(e[15])))
            .toList())
        .toList();
    while (true) {
      int block;
      int bitPos = combOff;

      /// Inner loop: for each block, add table entries to the result.
      for (block = 0; block < combBlocks; ++block) {
        int bits = 0, sign, abs, index, tooth;
        for (tooth = 0; tooth < combTeeth; ++tooth) {
          int bitdata = secp256k1Rotr32(recoded[bitPos >> 5], bitPos & 0x1f);

          /// Clear the bit at position tooth, but sssh, don't tell clang.
          int vmask = (~(1 << tooth)).toUnsigned(32);
          bits = (bits & vmask).toUnsigned(32);

          /// Write the bit into position tooth (and junk into higher bits).
          bits = (bits ^ bitdata << tooth).toUnsigned(32);
          bitPos = (bitPos + combSpacing).toUnsigned(32);
        }

        sign = ((bits >> (combTeeth - 1)) & 1).toUnsigned(32);
        abs = (bits ^ -sign) & (combPoints - 1);
        _cond(sign == 0 || sign == 1, "secp256k1ECmultGen");

        _cond(abs < combPoints, "secp256k1ECmultGen");

        for (index = 0; index < combPoints; ++index) {
          secp256k1GeStorageCmov(adds,
              secp256k1ECmultGenPrecTable[block][index], (index == abs).toInt);
        }

        /// Set add=adds or add=-adds, in constant time, based on sign.
        secp256k1GeFromStorage(add, adds);
        secp256k1FeNegate(neg, add.y, 1);
        secp256k1FeCmov(add.y, neg, sign);

        /// Add the looked up and conditionally negated value to r.
        if (first != 0) {
          /// If this is the first table lookup, we can skip addition.
          secp256k1GejSetGe(r, add);

          /// Give the entry a random Z coordinate to blind intermediary results.
          secp256k1GejRescale(r, ctx.projBlind);
          first = 0;
        } else {
          secp256k1GejAddGe(r, r, add);
        }
      }

      /// Double the result, except in the last iteration.
      if (combOff-- == 0) break;
      secp256k1GejDouble(r, r);
    }

    secp256k1GejAddGe(r, r, ctx.geOffset);
  }

  static void secp256k1GejRescale(Secp256k1Gej r, Secp256k1Fe s) {
    /// Operations: 4 mul, 1 sqr
    Secp256k1Fe zz = Secp256k1Fe();
    _cond(secp256k1FeNormalizesToZeroVar(s) == 0, "secp256k1GejRescale");

    secp256k1FeSqr(zz, s);
    secp256k1FeMul(r.x, r.x, zz);
    secp256k1FeMul(r.y, r.y, zz);
    secp256k1FeMul(r.y, r.y, s);
    secp256k1FeMul(r.z, r.z, s);
  }

  static void secp256k1GeSetGej(Secp256k1Ge r, Secp256k1Gej a) {
    Secp256k1Fe z2 = Secp256k1Fe(), z3 = Secp256k1Fe();
    r.infinity = a.infinity;
    secp256k1FeInv(a.z, a.z);
    secp256k1FeSqr(z2, a.z);
    secp256k1FeMul(z3, a.z, z2);
    secp256k1FeMul(a.x, a.x, z2);
    secp256k1FeMul(a.y, a.y, z3);
    secp256k1FeSetInt(a.z, 1);
    r.x = a.x.clone();
    r.y = a.y.clone();
  }

  static void secp256k1GeToStorage(Secp256k1GeStorage r, Secp256k1Ge a) {
    Secp256k1Fe x, y;
    _cond(a.infinity == 0, "secp256k1GeToStorage");

    x = a.x.clone();
    secp256k1FeNormalize(x);
    y = a.y.clone();
    secp256k1FeNormalize(y);
    secp256k1FeToStorage(r.x, x);
    secp256k1FeToStorage(r.y, y);
  }

  static void secp256k1GeFromStorage(Secp256k1Ge r, Secp256k1GeStorage a) {
    secp256k1FeFromStorage(r.x, a.x);
    secp256k1FeFromStorage(r.y, a.y);
    r.infinity = 0;
  }

  static void secp256k1GejCmov(Secp256k1Gej r, Secp256k1Gej a, int flag) {
    secp256k1FeCmov(r.x, a.x, flag);
    secp256k1FeCmov(r.y, a.y, flag);
    secp256k1FeCmov(r.z, a.z, flag);
    r.infinity ^= (r.infinity ^ a.infinity) & flag;
  }

  static void secp256k1GeStorageCmov(
      Secp256k1GeStorage r, Secp256k1GeStorage a, int flag) {
    secp256k1FeStorageCmov(r.x, a.x, flag);
    secp256k1FeStorageCmov(r.y, a.y, flag);
  }

  static void secp256k1FeStorageCmov(
      Secp256k1FeStorage r, Secp256k1FeStorage a, int flag) {
    BigInt mask0, mask1;
    int vflag = flag;
    mask0 = vflag.toBigInt + ~(BigInt.zero);
    mask1 = ~mask0;
    r[0] = (r[0] & mask0) | (a[0] & mask1);
    r[1] = (r[1] & mask0) | (a[1] & mask1);
    r[2] = (r[2] & mask0) | (a[2] & mask1);
    r[3] = (r[3] & mask0) | (a[3] & mask1);
  }

  static void secp256k1GeMulLambda(Secp256k1Ge r, Secp256k1Ge a) {
    r.set(a);
    secp256k1FeMul(r.x, r.x, Secp256k1Const.secp256k1ConstBeta);
  }

  static int secp256k1GeXOnCurveVar(Secp256k1Fe x) {
    Secp256k1Fe c = Secp256k1Fe();
    secp256k1FeSqr(c, x);
    secp256k1FeMul(c, c, x);
    secp256k1FeAddInt(c, Secp256k1Const.secp256k1B);
    return secp256k1FeIsSquareVar(c);
  }

  static int secp256k1GeXFracOnCurveVar(Secp256k1Fe xn, Secp256k1Fe xd) {
    Secp256k1Fe r = Secp256k1Fe(), t = Secp256k1Fe();
    _cond(
        secp256k1FeNormalizesToZeroVar(xd) == 0, "secp256k1GeXFracOnCurveVar");

    secp256k1FeMul(r, xd, xn);
    secp256k1FeSqr(t, xn);
    secp256k1FeMul(r, r, t);
    secp256k1FeSqr(t, xd);
    secp256k1FeSqr(t, t);
    _cond(Secp256k1Const.secp256k1B <= 31, "secp256k1GeXFracOnCurveVar");
    secp256k1FeMulInt(t, Secp256k1Const.secp256k1B);
    secp256k1FeAdd(r, t);
    return secp256k1FeIsSquareVar(r);
  }

  static int secp256k1FeSqrt(Secp256k1Fe r, Secp256k1Fe a) {
    Secp256k1Fe x2 = Secp256k1Fe(),
        x3 = Secp256k1Fe(),
        x6 = Secp256k1Fe(),
        x9 = Secp256k1Fe(),
        x11 = Secp256k1Fe(),
        x22 = Secp256k1Fe(),
        x44 = Secp256k1Fe(),
        x88 = Secp256k1Fe(),
        x176 = Secp256k1Fe(),
        x220 = Secp256k1Fe(),
        x223 = Secp256k1Fe(),
        t1 = Secp256k1Fe();
    int j, ret;

    _cond(r != a, "secp256k1FeSqrt");

    secp256k1FeSqr(x2, a);
    secp256k1FeMul(x2, x2, a);

    secp256k1FeSqr(x3, x2);
    secp256k1FeMul(x3, x3, a);
    x6 = x3.clone();
    for (j = 0; j < 3; j++) {
      secp256k1FeSqr(x6, x6);
    }
    secp256k1FeMul(x6, x6, x3);

    x9 = x6.clone();
    for (j = 0; j < 3; j++) {
      secp256k1FeSqr(x9, x9);
    }
    secp256k1FeMul(x9, x9, x3);

    x11 = x9.clone();
    for (j = 0; j < 2; j++) {
      secp256k1FeSqr(x11, x11);
    }
    secp256k1FeMul(x11, x11, x2);

    x22 = x11.clone();
    for (j = 0; j < 11; j++) {
      secp256k1FeSqr(x22, x22);
    }
    secp256k1FeMul(x22, x22, x11);

    x44 = x22.clone();
    for (j = 0; j < 22; j++) {
      secp256k1FeSqr(x44, x44);
    }
    secp256k1FeMul(x44, x44, x22);

    x88 = x44.clone();
    for (j = 0; j < 44; j++) {
      secp256k1FeSqr(x88, x88);
    }
    secp256k1FeMul(x88, x88, x44);

    x176 = x88.clone();
    for (j = 0; j < 88; j++) {
      secp256k1FeSqr(x176, x176);
    }
    secp256k1FeMul(x176, x176, x88);

    x220 = x176.clone();
    for (j = 0; j < 44; j++) {
      secp256k1FeSqr(x220, x220);
    }
    secp256k1FeMul(x220, x220, x44);

    x223 = x220.clone();
    for (j = 0; j < 3; j++) {
      secp256k1FeSqr(x223, x223);
    }
    secp256k1FeMul(x223, x223, x3);

    /// The final result is then assembled using a sliding window over the blocks.

    t1 = x223.clone();
    for (j = 0; j < 23; j++) {
      secp256k1FeSqr(t1, t1);
    }
    secp256k1FeMul(t1, t1, x22);
    for (j = 0; j < 6; j++) {
      secp256k1FeSqr(t1, t1);
    }
    secp256k1FeMul(t1, t1, x2);
    secp256k1FeSqr(t1, t1);
    secp256k1FeSqr(r, t1);

    /// Check that a square root was actually calculated

    secp256k1FeSqr(t1, r);
    ret = secp256k1FeEqual(t1, a);

    /// verify
    if (ret == 0) {
      secp256k1FeNegate(t1, t1, 1);
      secp256k1FeNormalizeVar(t1);
      _cond(secp256k1FeEqual(t1, a) == 1, "secp256k1FeSqrt");
    }
    return ret;
  }

  static int secp256k1FeIsQuad(Secp256k1Fe a) {
    Secp256k1Fe r = Secp256k1Fe();
    return secp256k1FeSqrt(r, a);
  }

  static void secp256k1FeHalf(Secp256k1Fe r) {
    BigInt t0 = r[0], t1 = r[1], t2 = r[2], t3 = r[3], t4 = r[4];
    BigInt one = BigInt.one;
    BigInt mask = ((-(t0 & one)).toUnsigned64 >> 12).toUnsigned64;

    t0 = (t0 + (Secp256k1Const.mask47 & mask)).toUnsigned64;
    t1 = (t1 + mask).toUnsigned64;
    t2 = (t2 + mask).toUnsigned64;
    t3 = (t3 + mask).toUnsigned64;
    t4 = (t4 + (mask >> 4)).toUnsigned64;

    _cond((t0 & one) == BigInt.zero, "secp256k1FeHalf");

    r[0] = (t0 >> 1).toUnsigned64 + ((t1 & one) << 51);
    r[1] = (t1 >> 1).toUnsigned64 + ((t2 & one) << 51);
    r[2] = (t2 >> 1).toUnsigned64 + ((t3 & one) << 51);
    r[3] = (t3 >> 1).toUnsigned64 + ((t4 & one) << 51);
    r[4] = (t4 >> 1);
  }

  static void secp256k1FeGetBounds(Secp256k1Fe r, int m) {
    _cond(m >= 0, "secp256k1FeGetBounds");
    _cond(m <= 32, "secp256k1FeGetBounds");
    r[0] = Secp256k1Const.mask52 * BigInt.two * m.toBigInt;
    r[1] = Secp256k1Const.mask52 * BigInt.two * m.toBigInt;
    r[2] = Secp256k1Const.mask52 * BigInt.two * m.toBigInt;
    r[3] = Secp256k1Const.mask52 * BigInt.two * m.toBigInt;
    r[4] = Secp256k1Const.mask48 * BigInt.two * m.toBigInt;
  }

  static int secp256k1FeImplIsSquareVar(Secp256k1Fe x) {
    Secp256k1Fe tmp = Secp256k1Fe();
    Secp256k1ModinvSigned s = Secp256k1ModinvSigned();
    int jac, ret;

    tmp = x.clone();
    secp256k1FeNormalizeVar(tmp);

    /// secp256k1Jacobi64MaybeVar cannot deal with input 0.
    if (secp256k1FeIsZero(tmp).toBool) {
      return 1;
    }
    secp256k1FeToSigned62(s, tmp);
    jac = secp256k1Jacobi64MaybeVar(s, Secp256k1Const.secp256k1ConstModinfoFe);
    if (jac == 0) {
      Secp256k1Fe dummy = Secp256k1Fe();
      ret = secp256k1FeSqrt(dummy, tmp);
    } else {
      ret = (jac >= 0).toInt;
    }
    return ret;
  }

  static void secp256k1FeAdd(Secp256k1Fe r, Secp256k1Fe a) {
    r[0] += a[0];
    r[1] += a[1];
    r[2] += a[2];
    r[3] += a[3];
    r[4] += a[4];
  }

  static void secp256k1FeNegate(Secp256k1Fe r, Secp256k1Fe a, int m) {
    _cond(m >= 0 && m <= 31, "secp256k1FeNegate");
    // /// For all legal values of m (0..31), the following properties hold:
    _cond(
        Secp256k1Const.mask47 * BigInt.two * (m.toBigInt + BigInt.one) >=
            Secp256k1Const.mask52 * BigInt.two * m.toBigInt,
        "secp256k1FeNegate");
    _cond(
        Secp256k1Const.mask52 * BigInt.two * (m.toBigInt + BigInt.one) >=
            Secp256k1Const.mask52 * BigInt.two * m.toBigInt,
        "secp256k1FeNegate");
    _cond(
        Secp256k1Const.mask48 * BigInt.two * (m.toBigInt + BigInt.one) >=
            Secp256k1Const.mask48 * BigInt.two * m.toBigInt,
        "secp256k1FeNegate");
    r[0] = Secp256k1Const.mask47 * BigInt.two * (m + 1).toBigInt - a[0];
    r[1] = Secp256k1Const.mask52 * BigInt.two * (m + 1).toBigInt - a[1];
    r[2] = Secp256k1Const.mask52 * BigInt.two * (m + 1).toBigInt - a[2];
    r[3] = Secp256k1Const.mask52 * BigInt.two * (m + 1).toBigInt - a[3];
    r[4] = Secp256k1Const.mask48 * BigInt.two * (m + 1).toBigInt - a[4];
  }

  static void secp256k1FeSetInt(Secp256k1Fe r, int a) {
    _cond(0 <= a && a <= 0x7FFF, "secp256k1FeSetInt");
    r[0] = a.toBigInt;
    r[1] = r[2] = r[3] = r[4] = BigInt.zero;
  }

  static void secp256k1FeNormalizeVar(Secp256k1Fe r) {
    BigInt t0 = r[0], t1 = r[1], t2 = r[2], t3 = r[3], t4 = r[4];

    /// Reduce t4 at the start so there will be at most a single carry from the first pass
    BigInt m;
    BigInt x = t4 >> 48;
    t4 = t4 & Secp256k1Const.mask48;

    /// The first pass ensures the magnitude is 1, ...
    t0 = (t0 + x * Secp256k1Const.mask33).toUnsigned64;
    t1 = (t1 + (t0 >> 52)).toUnsigned64;
    t0 = (t0 & Secp256k1Const.mask52).toUnsigned64;
    t2 = (t2 + (t1 >> 52)).toUnsigned64;
    t1 = (t1 & Secp256k1Const.mask52).toUnsigned64;
    m = t1;
    t3 = (t3 + (t2 >> 52)).toUnsigned64;
    t2 = (t2 & Secp256k1Const.mask52).toUnsigned64;
    m = (m & t2).toUnsigned64;
    t4 = (t4 + (t3 >> 52)).toUnsigned64;
    t3 = (t3 & Secp256k1Const.mask52).toUnsigned64;
    m = (m & t3).toUnsigned64;

    /// ... except for a possible carry at bit 48 of t4 (i.e. bit 256 of the field element)
    _cond(t4 >> 49 == BigInt.zero, "secp256k1FeNormalizeVar");

    /// At most a single final reduction is needed; check if the value is >= the field characteristic
    x = (t4 >> 48) |
        ((t4 == Secp256k1Const.mask48) &
                (m == Secp256k1Const.mask52) &
                (t0 >= Secp256k1Const.mask47))
            .toBigInt;

    if (x.toBool) {
      t0 = (t0 + Secp256k1Const.mask33).toUnsigned64;
      t1 = (t1 + (t0 >> 52)).toUnsigned64;
      t0 = (t0 & Secp256k1Const.mask52).toUnsigned64;
      t2 = (t2 + (t1 >> 52)).toUnsigned64;
      t1 = (t1 & Secp256k1Const.mask52).toUnsigned64;
      t3 = (t3 + (t2 >> 52)).toUnsigned64;
      t2 = (t2 & Secp256k1Const.mask52).toUnsigned64;
      t4 = (t4 + (t3 >> 52)).toUnsigned64;
      t3 = (t3 & Secp256k1Const.mask52).toUnsigned64;

      /// If t4 didn't carry to bit 48 already, then it should have after any final reduction
      _cond(t4 >> 48 == x, "secp256k1FeNormalizeVar");

      /// Mask off the possible multiple of 2^256 from the final reduction
      t4 = (t4 & Secp256k1Const.mask48).toUnsigned64;
    }

    r[0] = t0;
    r[1] = t1;
    r[2] = t2;
    r[3] = t3;
    r[4] = t4;
  }

  static void secp256k1FeGetB32(List<int> r, Secp256k1Fe a) {
    r.asMin32("secp256k1FeGetB32");
    r[0] = (a[4] >> 40).toUnsignedInt8;
    r[1] = (a[4] >> 32).toUnsignedInt8;
    r[2] = (a[4] >> 24).toUnsignedInt8;
    r[3] = (a[4] >> 16).toUnsignedInt8;
    r[4] = (a[4] >> 8).toUnsignedInt8;
    r[5] = a[4].toUnsignedInt8;
    r[6] = (a[3] >> 44).toUnsignedInt8;
    r[7] = (a[3] >> 36).toUnsignedInt8;
    r[8] = (a[3] >> 28).toUnsignedInt8;
    r[9] = (a[3] >> 20).toUnsignedInt8;
    r[10] = (a[3] >> 12).toUnsignedInt8;
    r[11] = (a[3] >> 4).toUnsignedInt8;
    r[12] = (((a[2] >> 48) & 0xF.toBigInt) | ((a[3] & 0xF.toBigInt) << 4))
        .toUnsignedInt8;
    r[13] = (a[2] >> 40).toUnsignedInt8;
    r[14] = (a[2] >> 32).toUnsignedInt8;
    r[15] = (a[2] >> 24).toUnsignedInt8;
    r[16] = (a[2] >> 16).toUnsignedInt8;
    r[17] = (a[2] >> 8).toUnsignedInt8;
    r[18] = a[2].toUnsignedInt8;
    r[19] = (a[1] >> 44).toUnsignedInt8;
    r[20] = (a[1] >> 36).toUnsignedInt8;
    r[21] = (a[1] >> 28).toUnsignedInt8;
    r[22] = (a[1] >> 20).toUnsignedInt8;
    r[23] = (a[1] >> 12).toUnsignedInt8;
    r[24] = (a[1] >> 4).toUnsignedInt8;
    r[25] = (((a[0] >> 48) & 0xF.toBigInt) | ((a[1] & 0xF.toBigInt) << 4))
        .toUnsignedInt8;
    r[26] = (a[0] >> 40).toUnsignedInt8;
    r[27] = (a[0] >> 32).toUnsignedInt8;
    r[28] = (a[0] >> 24).toUnsignedInt8;
    r[29] = (a[0] >> 16).toUnsignedInt8;
    r[30] = (a[0] >> 8).toUnsignedInt8;
    r[31] = a[0].toUnsignedInt8;
  }

  static void secp256k1FeToStorage(Secp256k1FeStorage r, Secp256k1Fe a) {
    r[0] = a[0] | a[1] << 52;
    r[1] = a[1] >> 12 | a[2] << 40;
    r[2] = a[2] >> 24 | a[3] << 28;
    r[3] = a[3] >> 36 | a[4] << 16;
  }

  static void secp256k1FeCmov(Secp256k1Fe r, Secp256k1Fe a, int flag) {
    _cond(flag == 0 || flag == 1, "secp256k1FeCmov");
    BigInt mask0, mask1;
    int vflag = flag;
    // SECP256K1_CHECKMEM_CHECK_VERIFY(r.n, sizeof(r.n));
    mask0 = vflag.toBigInt + ~(BigInt.zero);
    mask1 = ~mask0;
    r[0] = (r[0] & mask0) | (a[0] & mask1);
    r[1] = (r[1] & mask0) | (a[1] & mask1);
    r[2] = (r[2] & mask0) | (a[2] & mask1);
    r[3] = (r[3] & mask0) | (a[3] & mask1);
    r[4] = (r[4] & mask0) | (a[4] & mask1);
  }

  static void secp256k1FeMulInt(Secp256k1Fe r, int a) {
    _cond(a >= 0 && a <= 32, "secp256k1FeMulInt");
    r[0] *= a.toBigInt;
    r[1] *= a.toBigInt;
    r[2] *= a.toBigInt;
    r[3] *= a.toBigInt;
    r[4] *= a.toBigInt;
  }

  static void secp256k1FeImplFromStorage(Secp256k1Fe r, Secp256k1FeStorage a) {
    r[0] = a[0] & Secp256k1Const.mask52;
    r[1] = a[0] >> 52 | ((a[1] << 12) & Secp256k1Const.mask52);
    r[2] = a[1] >> 40 | ((a[2] << 24) & Secp256k1Const.mask52);
    r[3] = a[2] >> 28 | ((a[3] << 36) & Secp256k1Const.mask52);
    r[4] = a[3] >> 16;
  }

  static void secp256k1FeFromStorage(Secp256k1Fe r, Secp256k1FeStorage a) {
    secp256k1FeImplFromStorage(r, a);
  }

  static void secp256k1FeNormalize(Secp256k1Fe r) {
    BigInt t0 = r[0], t1 = r[1], t2 = r[2], t3 = r[3], t4 = r[4];

    /// Reduce t4 at the start so there will be at most a single carry from the first pass
    BigInt m;
    BigInt x = (t4 >> 48).toUnsigned64;
    t4 = (t4 & Secp256k1Const.mask48).toUnsigned64;

    t0 = (t0 + x * Secp256k1Const.mask33).toUnsigned64;
    t1 = (t1 + (t0 >> 52)).toUnsigned64;
    t0 = (t0 & Secp256k1Const.mask52).toUnsigned64;

    t2 = (t2 + (t1 >> 52)).toUnsigned64;
    t1 = (t1 & Secp256k1Const.mask52).toUnsigned64;
    m = t1;

    t3 = (t3 + (t2 >> 52)).toUnsigned64;
    t2 = (t2 & Secp256k1Const.mask52).toUnsigned64;
    m = (m & t2).toUnsigned64;

    t4 = (t4 + (t3 >> 52)).toUnsigned64;
    t3 = (t3 & Secp256k1Const.mask52).toUnsigned64;
    m = (m & t3).toUnsigned64;

    /// ... except for a possible carry at bit 48 of t4 (i.e. bit 256 of the field element)
    _cond(t4 >> 49 == BigInt.zero, "secp256k1FeNormalize");

    /// At most a single final reduction is needed; check if the value is >= the field characteristic
    x = ((t4 >> 48) |
            ((t4 == Secp256k1Const.mask48) &
                    (m == Secp256k1Const.mask52) &
                    (t0 >= Secp256k1Const.mask47))
                .toBigInt)
        .toUnsigned64;

    t0 = (t0 + x * Secp256k1Const.mask33).toUnsigned64;
    t1 = (t1 + (t0 >> 52)).toUnsigned64;
    t0 = (t0 & Secp256k1Const.mask52).toUnsigned64;

    t2 = (t2 + (t1 >> 52)).toUnsigned64;
    t1 = (t1 & Secp256k1Const.mask52).toUnsigned64;

    t3 = (t3 + (t2 >> 52)).toUnsigned64;
    t2 = (t2 & Secp256k1Const.mask52).toUnsigned64;

    t4 = (t4 + (t3 >> 52)).toUnsigned64;
    t3 = (t3 & Secp256k1Const.mask52).toUnsigned64;

    /// If t4 didn't carry to bit 48 already, then it should have after any final reduction
    _cond(t4 >> 48 == x, "secp256k1FeNormalize");

    /// Mask off the possible multiple of 2^256 from the final reduction
    t4 = (t4 & Secp256k1Const.mask48).toUnsigned64;

    r[0] = t0;
    r[1] = t1;
    r[2] = t2;
    r[3] = t3;
    r[4] = t4;
  }

  static void secp256k1FeToSigned62(Secp256k1ModinvSigned r, Secp256k1Fe a) {
    final BigInt m62 = Secp256k1Const.mask62;
    final BigInt a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3], a4 = a[4];

    r[0] = (a0 | a1 << 52) & m62;
    r[1] = (a1 >> 10 | a2 << 42) & m62;
    r[2] = (a2 >> 20 | a3 << 32) & m62;
    r[3] = (a3 >> 30 | a4 << 22) & m62;
    r[4] = a4 >> 40;
  }

  static void secp256k1FeFromSigned62(Secp256k1Fe r, Secp256k1ModinvSigned a) {
    final BigInt m52 = (maxU64 >> 12).toUnsigned64;
    final BigInt a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3], a4 = a[4];
    _cond(a0 >> 62 == BigInt.zero, "secp256k1FeFromSigned62");
    _cond(a1 >> 62 == BigInt.zero, "secp256k1FeFromSigned62");
    _cond(a2 >> 62 == BigInt.zero, "secp256k1FeFromSigned62");
    _cond(a3 >> 62 == BigInt.zero, "secp256k1FeFromSigned62");
    _cond(a4 >> 8 == BigInt.zero, "secp256k1FeFromSigned62");

    r[0] = a0 & m52;
    r[1] = (a0 >> 52 | a1 << 10) & m52;
    r[2] = (a1 >> 42 | a2 << 20) & m52;
    r[3] = (a2 >> 32 | a3 << 30) & m52;
    r[4] = (a3 >> 22 | a4 << 40);
  }

  /// hh
  static void secp256k1FeInv(Secp256k1Fe r, Secp256k1Fe x) {
    int inputIsZero = secp256k1FeNormalizesToZero(x);
    Secp256k1Fe tmp = x.clone();
    Secp256k1ModinvSigned s = Secp256k1ModinvSigned();

    secp256k1FeNormalize(tmp);
    secp256k1FeToSigned62(s, tmp);
    secp256k1Modinv64(s, Secp256k1Const.secp256k1ConstModinfoFe);
    secp256k1FeFromSigned62(r, s);
    _cond(secp256k1FeNormalizesToZero(r) == inputIsZero, "secp256k1FeInv");
  }

  static void secp256k1FeNormalizeWeak(Secp256k1Fe r) {
    BigInt t0 = r[0], t1 = r[1], t2 = r[2], t3 = r[3], t4 = r[4];

    /// Reduce t4 at the start so there will be at most a single carry from the first pass
    BigInt x = t4 >> 48;
    t4 = (t4 & Secp256k1Const.mask48).toUnsigned64;

// The first pass ensures the magnitude is 1, ...
    t0 = (t0 + (x * Secp256k1Const.mask33)).toUnsigned64;
    t1 = (t1 + (t0 >> 52)).toUnsigned64;
    t0 = (t0 & Secp256k1Const.mask52).toUnsigned64;
    t2 = (t2 + (t1 >> 52)).toUnsigned64;
    t1 = (t1 & Secp256k1Const.mask52).toUnsigned64;
    t3 = (t3 + (t2 >> 52)).toUnsigned64;
    t2 = (t2 & Secp256k1Const.mask52).toUnsigned64;
    t4 = (t4 + (t3 >> 52)).toUnsigned64;
    t3 = (t3 & Secp256k1Const.mask52).toUnsigned64;

    /// ... except for a possible carry at bit 48 of t4 (i.e. bit 256 of the field element)
    _cond(t4 >> 49 == BigInt.zero, "secp256k1FeNormalizeWeak");

    r[0] = t0;
    r[1] = t1;
    r[2] = t2;
    r[3] = t3;
    r[4] = t4;
  }

  static int secp256k1FeNormalizesToZeroVar(Secp256k1Fe r) {
    BigInt t0, t1, t2, t3, t4;
    BigInt z0, z1;
    BigInt x;

    t0 = r[0];
    t4 = r[4];

    /// Reduce t4 at the start so there will be at most a single carry from the first pass
    x = (t4 >> 48).toUnsigned64;

    /// The first pass ensures the magnitude is 1, ...
    t0 = (t0 + x * Secp256k1Const.mask33).toUnsigned64;

    /// z0 tracks a possible raw value of 0, z1 tracks a possible raw value of P
    z0 = (t0 & Secp256k1Const.mask52).toUnsigned64;
    z1 = (z0 ^ 0x1000003D0.toBigInt).toUnsigned64;

    /// Fast return path should catch the majority of cases
    if ((z0 != BigInt.zero) & (z1 != Secp256k1Const.mask52)) {
      return 0;
    }

    t1 = r[1];
    t2 = r[2];
    t3 = r[3];

    t4 = (t4 & Secp256k1Const.mask48).toUnsigned64;

    t1 = (t1 + (t0 >> 52)).toUnsigned64;
    t2 = (t2 + (t1 >> 52)).toUnsigned64;
    t1 = (t1 & Secp256k1Const.mask52).toUnsigned64;
    z0 = (z0 | t1).toUnsigned64;
    z1 = (z1 & t1).toUnsigned64;
    t3 = (t3 + (t2 >> 52)).toUnsigned64;
    t2 = (t2 & Secp256k1Const.mask52).toUnsigned64;
    z0 = (z0 | t2).toUnsigned64;
    z1 = (z1 & t2).toUnsigned64;
    t4 = (t4 + (t3 >> 52)).toUnsigned64;
    t3 = (t3 & Secp256k1Const.mask52).toUnsigned64;
    z0 = (z0 | t3).toUnsigned64;
    z1 = (z1 & t3).toUnsigned64;
    z0 = (z0 | t4).toUnsigned64;
    z1 = (z1 & (t4 ^ Secp256k1Const.high4Mask52)).toUnsigned64;

    /// ... except for a possible carry at bit 48 of t4 (i.e. bit 256 of the field element)
    _cond(t4 >> 49 == BigInt.zero, "secp256k1FeNormalizesToZeroVar");
    final n = ((z0 == BigInt.zero) | (z1 == Secp256k1Const.mask52));
    return n.toInt;
  }

  static int secp256k1FeEqual(Secp256k1Fe a, Secp256k1Fe b) {
    Secp256k1Fe na = Secp256k1Fe();
    secp256k1FeNegate(na, a, 1);
    secp256k1FeAdd(na, b);
    return secp256k1FeNormalizesToZero(na);
  }

  static int secp256k1FeNormalizesToZero(Secp256k1Fe r) {
    BigInt t0 = r[0], t1 = r[1], t2 = r[2], t3 = r[3], t4 = r[4];

    /// z0 tracks a possible raw value of 0, z1 tracks a possible raw value of P
    BigInt z0, z1;

    /// Reduce t4 at the start so there will be at most a single carry from the first pass
    BigInt x = (t4 >> 48).toUnsigned64;

    t4 = (t4 & Secp256k1Const.mask48).toUnsigned64;

    /// The first pass ensures the magnitude is 1, ...
    t0 = (t0 + x * Secp256k1Const.mask33).toUnsigned64;
    t1 = (t1 + (t0 >> 52)).toUnsigned64;
    t0 = (t0 & Secp256k1Const.mask52).toUnsigned64;

    z0 = t0;
    z1 = (t0 ^ 0x1000003D0.toBigInt).toUnsigned64;

    t2 = (t2 + (t1 >> 52)).toUnsigned64;
    t1 = (t1 & Secp256k1Const.mask52).toUnsigned64;

    z0 = (z0 | t1).toUnsigned64;
    z1 = (z1 & t1).toUnsigned64;

    t3 = (t3 + (t2 >> 52)).toUnsigned64;
    t2 = (t2 & Secp256k1Const.mask52).toUnsigned64;

    z0 = (z0 | t2).toUnsigned64;
    z1 = (z1 & t2).toUnsigned64;

    t4 = (t4 + (t3 >> 52)).toUnsigned64;
    t3 = (t3 & Secp256k1Const.mask52).toUnsigned64;

    z0 = (z0 | t3).toUnsigned64;
    z1 = (z1 & t3).toUnsigned64;

    z0 = (z0 | t4).toUnsigned64;
    z1 = (z1 & (t4 ^ Secp256k1Const.high4Mask52)).toUnsigned64;

    /// ... except for a possible carry at bit 48 of t4 (i.e. bit 256 of the field element)
    _cond(t4 >> 49 == BigInt.zero, "secp256k1FeNormalizesToZero");

    return ((z0 == BigInt.zero) | (z1 == Secp256k1Const.mask52)).toInt;
  }

  static void secp256k1FeInvVar(Secp256k1Fe r, Secp256k1Fe x) {
    int inputIsZero = secp256k1FeNormalizesToZero(x);
    Secp256k1Fe tmp = x.clone();
    Secp256k1ModinvSigned s = Secp256k1ModinvSigned();

    secp256k1FeNormalizeVar(tmp);
    secp256k1FeToSigned62(s, tmp);
    secp256k1Modinv64Var(s, Secp256k1Const.secp256k1ConstModinfoFe);
    secp256k1FeFromSigned62(r, s);
    _cond(secp256k1FeNormalizesToZero(r) == inputIsZero, "secp256k1FeInvVar");
  }

  static int secp256k1FeIsSquareVar(Secp256k1Fe x) {
    int ret;
    Secp256k1Fe tmp = x.clone(), sqrt = Secp256k1Fe();
    ret = secp256k1FeImplIsSquareVar(x);
    secp256k1FeNormalizeWeak(tmp);
    _cond(ret == secp256k1FeSqrt(sqrt, tmp), "secp256k1FeIsSquareVar");
    return ret;
  }

  static int secp256k1FeIsZero(Secp256k1Fe a) {
    return ((a[0] | a[1] | a[2] | a[3] | a[4]) == BigInt.zero).toInt;
  }

  static void ecmultConstTableGetGe(
      Secp256k1Ge r, List<Secp256k1Ge> pre, int n) {
    int m = 0;

    /// If the top bit of n is 0, we want the negation.
    int negative = ((n) >> (Secp256k1Const.constGroupSize - 1)) ^ 1;
    int index =
        ((-negative) ^ n) & ((1 << (Secp256k1Const.constGroupSize - 1)) - 1);
    Secp256k1Fe negY = Secp256k1Fe();
    _cond((n.toBigInt) < (BigInt.one << Secp256k1Const.constGroupSize),
        "ecmultConstTableGetGe");
    _cond(index < (1 << (Secp256k1Const.constGroupSize - 1)),
        "ecmultConstTableGetGe");

    (r).x = (pre)[m].x.clone();
    (r).y = (pre)[m].y.clone();
    for (m = 1; m < Secp256k1Const.constTableSize; m++) {
      secp256k1FeCmov((r).x, (pre)[m].x, (m == index).toInt);
      secp256k1FeCmov((r).y, (pre)[m].y, (m == index).toInt);
    }
    (r).infinity = 0;
    secp256k1FeNegate(negY, (r).y, 1);
    secp256k1FeCmov((r).y, negY, negative);
  }

  static void secp256k1ECmultConst(
      Secp256k1Gej r, Secp256k1Ge a, Secp256k1Scalar q) {
    /// The offset to add to s1 and s2 to make them non-negative. Equal to 2^128.
    Secp256k1Scalar s = Secp256k1Scalar(),
        v1 = Secp256k1Scalar(),
        v2 = Secp256k1Scalar();
    List<Secp256k1Ge> preA =
        List.generate(Secp256k1Const.constTableSize, (_) => Secp256k1Ge());
    List<Secp256k1Ge> preALam =
        List.generate(Secp256k1Const.constTableSize, (_) => Secp256k1Ge());
    Secp256k1Fe globalZ = Secp256k1Fe();
    int group, i;
    if (secp256k1GeIsInfinity(a).toBool) {
      secp256k1GejSetInfinity(r);
      return;
    }

    /// Compute v1 and v2.
    secp256k1ScalarAdd(s, q, Secp256k1Const.secp256k1ECmultConstK);
    secp256k1ScalarHalf(s, s);
    secp256k1ScalarSplitLambda(v1, v2, s);
    secp256k1ScalarAdd(v1, v1, Secp256k1Const.sOffset);
    secp256k1ScalarAdd(v2, v2, Secp256k1Const.sOffset);

    /// verify
    for (i = 129; i < 256; ++i) {
      _cond(
          secp256k1ScalarGetBitsLimb32(v1, i, 1) == 0, "secp256k1ECmultConst");
      _cond(
          secp256k1ScalarGetBitsLimb32(v2, i, 1) == 0, "secp256k1ECmultConst");
    }
    secp256k1GejSetGe(r, a);
    secp256k1ECmultConstOddMultiplesTableGlobalz(preA, globalZ, r);

    for (i = 0; i < Secp256k1Const.constTableSize; i++) {
      secp256k1GeMulLambda(preALam[i], preA[i]);
    }

    for (group = Secp256k1Const.constGroup - 1; group >= 0; --group) {
      /// Using the _var get_bits function is ok here, since it's only variable in offset and count, not in the scalar.
      int bits1 = secp256k1ScalarGetBitsVar(v1,
          group * Secp256k1Const.constGroupSize, Secp256k1Const.constGroupSize);
      int bits2 = secp256k1ScalarGetBitsVar(v2,
          group * Secp256k1Const.constGroupSize, Secp256k1Const.constGroupSize);
      Secp256k1Ge t = Secp256k1Ge();
      int j;
//
      ecmultConstTableGetGe(t, preA, bits1);
      if (group == Secp256k1Const.constGroup - 1) {
        /// Directly set r in the first iteration.
        secp256k1GejSetGe(r, t);
      } else {
        /// Shift the result so far up.
        for (j = 0; j < Secp256k1Const.constGroupSize; ++j) {
          secp256k1GejDouble(r, r);
        }
        secp256k1GejAddGe(r, r, t);
      }
      ecmultConstTableGetGe(t, preALam, bits2);
      secp256k1GejAddGe(r, r, t);
    }

    /// Map the result back to the secp256k1 curve from the isomorphic curve.
    secp256k1FeMul(r.z, r.z, globalZ);
  }

  static void secp256k1ECmultConstOddMultiplesTableGlobalz(
      List<Secp256k1Ge> pre, Secp256k1Fe globalz, Secp256k1Gej a) {
    List<Secp256k1Fe> zr =
        List.generate(Secp256k1Const.constTableSize, (_) => Secp256k1Fe());

    secp256k1ECmultOddMultiplesTable(
        Secp256k1Const.constTableSize, pre, zr, globalz, a);
    secp256k1GeTableSetGlobalz(Secp256k1Const.constTableSize, pre, zr);
  }

  static void secp256k1ECmultOddMultiplesTable(int n, List<Secp256k1Ge> preA,
      List<Secp256k1Fe> zr, Secp256k1Fe z, Secp256k1Gej a) {
    Secp256k1Gej d = Secp256k1Gej(), ai = Secp256k1Gej();
    Secp256k1Ge dGe = Secp256k1Ge();
    int i;

    _cond(a.infinity == 0, "secp256k1ECmultOddMultiplesTable");

    secp256k1GejDoubleVar(d, a, null);

    secp256k1GeSetXy(dGe, d.x, d.y);
    secp256k1GeSetGejZinv(preA[0], a, d.z);
    secp256k1GejSetGe(ai, preA[0]);
    ai.z = a.z.clone();

    zr[0] = d.z.clone();

    for (i = 1; i < n; i++) {
      secp256k1GejAddGeVar(ai, ai, dGe, zr[i]);
      secp256k1GeSetXy(preA[i], ai.x, ai.y);
    }

    secp256k1FeMul(z, ai.z, d.z);
  }

  static void secp256k1ScalarSplitLambda(
      Secp256k1Scalar r1, Secp256k1Scalar r2, Secp256k1Scalar k) {
    Secp256k1Scalar c1 = Secp256k1Scalar(), c2 = Secp256k1Scalar();

    secp256k1ScalarVerify(k);
    _cond(!identical(r1, k), "secp256k1ScalarSplitLambda");
    _cond(!identical(r2, k), "secp256k1ScalarSplitLambda");
    _cond(!identical(r1, r2), "secp256k1ScalarSplitLambda");

    /// these _var calls are constant time since the shift amount is constant
    secp256k1ScalarMulShiftVar(c1, k, Secp256k1Const.g1, 384);
    secp256k1ScalarMulShiftVar(c2, k, Secp256k1Const.g2, 384);
    secp256k1ScalarMul(c1, c1, Secp256k1Const.minusB1);
    secp256k1ScalarMul(c2, c2, Secp256k1Const.minusB2);
    secp256k1ScalarAdd(r2, c1, c2);
    secp256k1ScalarMul(r1, r2, Secp256k1Const.secp256k1ConstLambda);
    secp256k1ScalarNegate(r1, r1);
    secp256k1ScalarAdd(r1, r1, k);

    secp256k1ScalarVerify(r1);
    secp256k1ScalarVerify(r2);
  }

  static int secp256k1EcmultConstXonly(
      Secp256k1Fe r, Secp256k1Fe n, Secp256k1Scalar q,
      {Secp256k1Fe? d, int knownOnCurve = 0}) {
    Secp256k1Fe g = Secp256k1Fe(), i = Secp256k1Fe();
    Secp256k1Ge p = Secp256k1Ge();
    Secp256k1Gej rj = Secp256k1Gej();

    /// Compute g = (n^3 + B*d^3).
    secp256k1FeSqr(g, n);
    secp256k1FeMul(g, g, n);
    if (d != null) {
      Secp256k1Fe b = Secp256k1Fe();
      _cond(secp256k1FeNormalizesToZero(d) == 0, "secp256k1EcmultConstXonly");
      secp256k1FeSqr(b, d);
      _cond(Secp256k1Const.secp256k1B <= 8, "secp256k1EcmultConstXonly");
      secp256k1FeMulInt(b, Secp256k1Const.secp256k1B);
      secp256k1FeMul(b, b, d);
      secp256k1FeAdd(g, b);
      if (knownOnCurve == 0) {
        Secp256k1Fe c = Secp256k1Fe();
        secp256k1FeMul(c, g, d);
        if (secp256k1FeIsSquareVar(c) == 0) return 0;
      }
    } else {
      secp256k1FeAddInt(g, Secp256k1Const.secp256k1B);
      if (knownOnCurve == 0) {
        /// g at this point equals x^3 + 7. Test if it is square.
        if (secp256k1FeIsSquareVar(g) == 0) return 0;
      }
    }
    secp256k1FeMul(p.x, g, n);
    secp256k1FeSqr(p.y, g);
    p.infinity = 0;

    /// Perform x-only EC multiplication of P with q.
    _cond(secp256k1ScalarIsZero(q) == 0, "secp256k1EcmultConstXonly");
    secp256k1ECmultConst(rj, p, q);
    _cond(secp256k1GejIsInfinity(rj) == 0, "secp256k1EcmultConstXonly");
    secp256k1FeSqr(i, rj.z);
    secp256k1FeMul(i, i, g);
    if (d != null) secp256k1FeMul(i, i, d);
    secp256k1FeInv(i, i);
    secp256k1FeMul(r, rj.x, i);

    return 1;
  }

  static void secp256k1ECmultGenScalarDiff(Secp256k1Scalar diff) {
    int i;

    /// Compute scalar -1/2.
    Secp256k1Scalar neghalf = Secp256k1Scalar();
    secp256k1ScalarHalf(neghalf, _secp256k1ScalarOne);
    secp256k1ScalarNegate(neghalf, neghalf);

    /// Compute offset = 2^(combBits - 1).
    diff.set(_secp256k1ScalarOne);
    for (i = 0; i < Secp256k1Const.combBits - 1; ++i) {
      secp256k1ScalarAdd(diff, diff, diff);
    }

    /// The result is the sum 2^(combBits - 1) + (-1/2).
    secp256k1ScalarAdd(diff, diff, neghalf);
  }
}

extension _BytesHelper on List<int> {
  void asMin32(String methodName, {int offset = 0}) {
    if (length + offset < 32) {
      throw CryptoException(
          "$methodName operation failed. invalid bytes length.");
    }
    if (any((e) => e.isNegative || e > 0xFF)) {
      throw CryptoException("$methodName operation failed. invalid bytes.");
    }
  }
}

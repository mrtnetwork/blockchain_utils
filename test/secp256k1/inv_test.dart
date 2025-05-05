// *******************************************************************************
// Copyright (c) 2013, 2014, 2015, 2021 Thomas Daede, Cory Fields, Pieter Wuille *
// Distributed under the MIT software license, see the accompanying              *
// file COPYING or https://www.opensource.org/licenses/mit-license.php.          *
// *******************************************************************************

import 'dart:math';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';
import 'package:test/test.dart';

import 'test_constants.dart';
import 'tools.dart';

void main() {
  group("secp256k1 modInv", () {
    test("modinv", () => _modinvTest());
    test("sqrt", () => _testSqrt());
    test("inverse", () => _inv());
  });
}

void _testModinv64Uint16(List<int> out, List<int> ind, List<int> mod) {
  final BigInt m62 = maxU64 >> 2;

  Secp256k1ModinvSigned x = Secp256k1ModinvSigned();
  Secp256k1ModinvInfo m = Secp256k1ModinvInfo(
      modulus: Secp256k1ModinvSigned(), modulusInv: BigInt.zero);

  _uint16ToSigned62(x, ind);
  bool nonzero = (x[0] | x[1] | x[2] | x[3] | x[4]) != BigInt.zero;
  _uint16ToSigned62(m.modulus, mod);
  m = m.copyWith(modulusInv: _modinv2p64(m.modulus[0]) & m62);
  int i, vartime;

  expect(((m.modulusInv * m.modulus[0]) & m62), BigInt.one);
  if (nonzero) {
    int jac;
    List<int> sqr = List<int>.filled(16, 0), negone = List<int>.filled(16, 0);

    mulmod256(sqr, ind, ind, mod);
    _uint16ToSigned62(x, sqr);
    /* Compute jacobi symbol of in^2, which must be 1 (or uncomputable). */
    jac = Secp256k1.secp256k1Jacobi64MaybeVar(x, m);
    expect(jac == 0 || jac == 1, true);
    /* Then compute the jacobi symbol of -(in^2). x and -x have opposite
         * jacobi symbols if and only if (mod % 4) == 3. */
    negone[0] = mod[0] - 1;
    for (i = 1; i < 16; ++i) {
      negone[i] = mod[i];
    }
    mulmod256(sqr, sqr, negone, mod);
    _uint16ToSigned62(x, sqr);

    jac = Secp256k1.secp256k1Jacobi64MaybeVar(x, m);
    expect(jac == 0 || jac == 1 - (mod[0] & 2), true);
  }
  _uint16ToSigned62(x, ind);
  _mutateSignSigned62(m.modulus);

  List<int> tmp = List<int>.filled(16, 0);
  for (vartime = 0; vartime < 2; ++vartime) {
    if (vartime != 0) {
      Secp256k1.secp256k1Modinv64Var(x, m);
    } else {
      Secp256k1.secp256k1Modinv64(x, m);
    }

    /* produce output */
    _signed62ToUint16(out, x);

    /* check if the inverse times the input is 1 (mod m), unless x is 0. */
    mulmod256(tmp, out, ind, mod);
    expect((tmp[0] == 0 ? false : true), nonzero);
    for (i = 1; i < 16; ++i) {
      expect(tmp[i], 0);
    }
    if (vartime != 0) {
      Secp256k1.secp256k1Modinv64Var(x, m);
    } else {
      Secp256k1.secp256k1Modinv64(x, m);
    }
    _signed62ToUint16(tmp, x);
    for (i = 0; i < 16; ++i) {
      expect(tmp[i], ind[i]);
    }
  }
}

void _signed62ToUint16(List<int> out, Secp256k1ModinvSigned ind) {
  int i;
  for (int i = 0; i < 16; i++) {
    out[i] = 0;
  }
  for (i = 0; i < 256; ++i) {
    out[i >> 4] |= ((((ind[i ~/ 62]) >> (i % 62)) & BigInt.one) << (i & 15))
        .toUnsigned(16)
        .toInt();
  }
}

void _modinvTest() {
  for (int i = 0; i < cases.length; ++i) {
    List<int> out = List<int>.filled(16, 0);
    _testModinv64Uint16(out, cases[i][0], cases[i][1]);
    expect(CompareUtils.iterableIsEqual(out, cases[i][2]), true);
  }
}

void _uint16ToSigned62(Secp256k1ModinvSigned out, List<int> ind) {
  for (int i = 0; i < 5; i++) {
    out[i] = BigInt.zero;
  }
  int i;
  for (i = 0; i < 256; ++i) {
    out[i ~/ 62] = out[i ~/ 62] |
        (BigInt.from(((ind[i >> 4]) >> (i & 15))) & BigInt.one).toSigned(64) <<
            (i % 62);
  }
}

void _mutateSignSigned62(Secp256k1ModinvSigned x) {
  final BigInt m62 = ((BigInt.one << 62) - BigInt.one).toSigned(64);
  int testrandBits2() => Random().nextInt(4);

  for (int i = 0; i < 8; i++) {
    int pos = testrandBits2(); // random 0..3
    if (x[pos] > BigInt.zero && x[pos + 1] <= m62) {
      x[pos] -= (m62 + BigInt.one);
      x[pos + 1] += BigInt.one;
    } else if (x[pos] < BigInt.zero && x[pos + 1] >= -m62) {
      x[pos] += (m62 + BigInt.one);
      x[pos + 1] -= BigInt.one;
    }
  }
}

BigInt _modinv2p64(BigInt x) {
  if (x & BigInt.one == BigInt.zero) {
    throw ArgumentError('Input must be odd');
  }

  BigInt w = BigInt.one;
  for (int l = 0; l < 6; l++) {
    w = w * (BigInt.from(2) - w * x);
    w = w.toUnsigned64; // Keep within 64 bits
  }
  return w;
}

void _testSqrt() {
  Secp256k1Fe ns = Secp256k1Fe(),
      x = Secp256k1Fe(),
      s = Secp256k1Fe(),
      t = Secp256k1Fe();
  Secp256k1.secp256k1FeSetInt(x, 0);
  Secp256k1.secp256k1FeSqr(s, x);
  for (int i = 0; i < 10; i++) {
    ns = randomFeNonSqrt();
    for (int j = 0; j < 16; j++) {
      x = randomFe();
      Secp256k1.secp256k1FeSqr(s, x);
      expect(Secp256k1.secp256k1FeIsSquareVar(s), 1);
      _testSquart(s, x);
      Secp256k1.secp256k1FeNegate(t, s, 1);
      expect(Secp256k1.secp256k1FeIsSquareVar(t), 0);
      _testSquart(t, null);
      Secp256k1.secp256k1FeMul(t, s, ns);
      _testSquart(t, null);
    }
  }
}

void _testSquart(Secp256k1Fe a, Secp256k1Fe? k) {
  Secp256k1Fe r1 = Secp256k1Fe();
  Secp256k1Fe r2 = Secp256k1Fe();
  int v = Secp256k1.secp256k1FeSqrt(r1, a);
  expect((v == 0) == (k == null), true);
  if (k != null) {
    Secp256k1.secp256k1FeNegate(r2, r1, 1);
    Secp256k1.secp256k1FeAdd(r1, k);
    Secp256k1.secp256k1FeAdd(r2, k);
    Secp256k1.secp256k1FeNormalize(r1);
    Secp256k1.secp256k1FeNormalize(r2);
    expect(
        Secp256k1.secp256k1FeIsZero(r1) == 1 ||
            Secp256k1.secp256k1FeIsZero(r2) == 1,
        true);
  }
}

void _inv() {
  int i, v, testrand;
  List<int> b32 = List<int>.filled(32, 0);
  Secp256k1Fe xFe = Secp256k1Fe();
  Secp256k1Scalar xScalar = Secp256k1Scalar();
  /* Test fixed test cases through test_inverse_{scalar,field}, both ways. */
  for (i = 0; i < feCases.length; ++i) {
    for (v = 0; v <= 1; ++v) {
      _testInverseField(xFe, feCases[i][0], v);
      expect(_feEqual(xFe, feCases[i][1]), 1);
      _testInverseField(xFe, feCases[i][1], v);
      expect(_feEqual(xFe, feCases[i][0]), 1);
    }
  }
  // return;
  for (i = 0; i < scalarCases.length; ++i) {
    for (v = 0; v <= 1; ++v) {
      _testInverseScalar(xScalar, scalarCases[i][0], v);
      expect(Secp256k1.secp256k1ScalarEq(xScalar, scalarCases[i][1]), 1);
      _testInverseScalar(xScalar, scalarCases[i][1], v);
      expect(Secp256k1.secp256k1ScalarEq(xScalar, scalarCases[i][0]), 1);
    }
  }
  /* Test inputs 0..999 and their respective negations. */
  for (i = 0; i < 1000; ++i) {
    b32[31] = i & 0xff;
    b32[30] = (i >> 8) & 0xff;
    Secp256k1.secp256k1ScalarSetB32(xScalar, b32);
    Secp256k1.secp256k1FeSetB32Mod(xFe, b32);
    for (v = 0; v <= 1; ++v) {
      _testInverseScalar(null, xScalar, v);
      _testInverseField(null, xFe, v);
    }
    Secp256k1.secp256k1ScalarNegate(xScalar, xScalar);
    Secp256k1.secp256k1FeNegate(xFe, xFe, 1);
    for (v = 0; v <= 1; ++v) {
      _testInverseScalar(null, xScalar, v);
      _testInverseField(null, xFe, v);
    }
  }
  /* test 128*count random inputs; half with testrand256_test, half with testrand256 */
  for (testrand = 0; testrand <= 1; ++testrand) {
    for (i = 0; i < 64 * 16; ++i) {
      b32 = QuickCrypto.generateRandom();
      Secp256k1.secp256k1ScalarSetB32(xScalar, b32);
      Secp256k1.secp256k1FeSetB32Mod(xFe, b32);
      for (v = 0; v <= 1; ++v) {
        _testInverseScalar(null, xScalar, v);
        _testInverseField(null, xFe, v);
      }
    }
  }
}

void _testInverseField(Secp256k1Fe? out, Secp256k1Fe x, int v) {
  Secp256k1Fe l = Secp256k1Fe(), r = Secp256k1Fe(), t = Secp256k1Fe();
  Secp256k1Fe feMinusOne = Secp256k1Fe.constants(
    BigInt.from(0xFFFFFFFF),
    BigInt.from(0xFFFFFFFF),
    BigInt.from(0xFFFFFFFF),
    BigInt.from(0xFFFFFFFF),
    BigInt.from(0xFFFFFFFF),
    BigInt.from(0xFFFFFFFF),
    BigInt.from(0xFFFFFFFE),
    BigInt.from(0xFFFFFC2E),
  );

  if (v != 0) {
    Secp256k1.secp256k1FeInvVar(l, x);
  } else {
    Secp256k1.secp256k1FeInv(l, x);
  }
  out?.set(l);
  t = x.clone();
  if (Secp256k1.secp256k1FeNormalizesToZeroVar(t) == 1) {
    expect(Secp256k1.secp256k1FeNormalizesToZero(l), 1);
    return;
  }
  Secp256k1.secp256k1FeMul(t, x, l);
  Secp256k1.secp256k1FeAdd(t, feMinusOne); /* t = x*(1/x)-1 */
  expect(Secp256k1.secp256k1FeNormalizesToZero(t), 1); /* x*(1/x)-1 == 0 */
  r = x.clone(); /* r = x */
  Secp256k1.secp256k1FeAdd(r, feMinusOne); /* r = x-1 */

  if (Secp256k1.secp256k1FeNormalizesToZeroVar(r) == 1) {
    return;
  }

  if (v == 0) {
    Secp256k1.secp256k1FeInv(r, r);
  } else {
    Secp256k1.secp256k1FeInvVar(r, r);
  }
  // return;

  Secp256k1.secp256k1FeAdd(l, feMinusOne);
  if (v == 0) {
    Secp256k1.secp256k1FeInv(l, l);
  } else {
    Secp256k1.secp256k1FeInvVar(l, l);
  } /* l = 1/x-1 */
  Secp256k1.secp256k1FeAddInt(l, 1); /* l = 1/(1/x-1)+1 */
  Secp256k1.secp256k1FeAdd(l, r); /* l = 1/(1/x-1)+1 + 1/(x-1) */
  expect(Secp256k1.secp256k1FeNormalizesToZeroVar(l), 1); /* l == 0 */
}

void _testInverseScalar(Secp256k1Scalar? out, Secp256k1Scalar x, int v) {
  Secp256k1Scalar l = Secp256k1Scalar(),
      r = Secp256k1Scalar(),
      t = Secp256k1Scalar();
  Secp256k1Scalar secp256k1ScalarOne = Secp256k1Scalar.constants(
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.one);
  Secp256k1Scalar scalarMinusOne = Secp256k1Scalar.constants(
      BigInt.from(0xFFFFFFFF),
      BigInt.from(0xFFFFFFFF),
      BigInt.from(0xFFFFFFFF),
      BigInt.from(0xFFFFFFFE),
      BigInt.from(0xBAAEDCE6),
      BigInt.from(0xAF48A03B),
      BigInt.from(0xBFD25E8C),
      BigInt.from(0xD0364140));
  if (v == 0) {
    Secp256k1.secp256k1ScalarInverse(l, x);
  } else {
    Secp256k1.secp256k1ScalarInverseVar(l, x);
  }
  out?.set(l);

  if (Secp256k1.secp256k1ScalarIsZero(x) == 1) {
    expect(Secp256k1.secp256k1ScalarIsZero(l), 1);
    return;
  }
  Secp256k1.secp256k1ScalarMul(t, x, l); /* t = x*(1/x) */
  expect(Secp256k1.secp256k1ScalarIsOne(t), 1); /* x*(1/x) == 1 */
  Secp256k1.secp256k1ScalarAdd(r, x, scalarMinusOne); /* r = x-1 */
  if (Secp256k1.secp256k1ScalarIsZero(r) == 1) {
    return;
  }
  if (v == 0) {
    Secp256k1.secp256k1ScalarInverse(r, r);
  } else {
    Secp256k1.secp256k1ScalarInverseVar(r, r);
  }

  Secp256k1.secp256k1ScalarAdd(l, scalarMinusOne, l);

  if (v == 0) {
    Secp256k1.secp256k1ScalarInverse(l, l);
  } else {
    Secp256k1.secp256k1ScalarInverseVar(l, l);
  }

  Secp256k1.secp256k1ScalarAdd(l, l, secp256k1ScalarOne); /* l = 1/(1/x-1)+1 */
  Secp256k1.secp256k1ScalarAdd(l, r, l); /* l = 1/(1/x-1)+1 + 1/(x-1) */
  expect(Secp256k1.secp256k1ScalarIsZero(l), 1); /* l == 0 */
}

int _feEqual(Secp256k1Fe a, Secp256k1Fe b) {
  Secp256k1Fe an = a.clone();
  Secp256k1Fe bn = b.clone();
  Secp256k1.secp256k1FeNormalizeWeak(an);
  return Secp256k1.secp256k1FeEqual(an, bn);
}

// *******************************************************************************
// Copyright (c) 2013, 2014, 2015, 2021 Thomas Daede, Cory Fields, Pieter Wuille *
// Distributed under the MIT software license, see the accompanying              *
// file COPYING or https://www.opensource.org/licenses/mit-license.php.          *
// *******************************************************************************

import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';
import 'package:test/test.dart';

import 'test_constants.dart';
import 'tools.dart';

void main() {
  // return;
  group("secp256k1 group element", () {
    test("group element endomorphism ", () => _endomorphismTests());
    test("group element ", () => _ge());
    test("group element", () => _gej());
    test("group decompress", () => _groupDecompressTest());
  });
}

void _ge() {
  int i, i1;
  int runs = 6;
  final ge = List.generate((1 + 4 * runs), (i) => Secp256k1Ge());
  final gej = List.generate((1 + 4 * runs), (i) => Secp256k1Gej());
  Secp256k1Fe zf = Secp256k1Fe(), r = Secp256k1Fe();
  Secp256k1Fe zfi2 = Secp256k1Fe(), zfi3 = Secp256k1Fe();
  Secp256k1.secp256k1GejSetInfinity(gej[0]);
  Secp256k1.secp256k1GeSetInfinity(ge[0]);
  for (i = 0; i < runs; i++) {
    int j, k;
    Secp256k1Ge g = Secp256k1Ge();
    randomGeTest(g);
    if (i >= runs - 2) {
      Secp256k1.secp256k1GeMulLambda(g, ge[1]);
      expect(Secp256k1.secp256k1GeEqVar(g, ge[1]), 0);
    }
    if (i >= runs - 1) {
      Secp256k1.secp256k1GeMulLambda(g, g);
    }
    ge[1 + 4 * i] = g.clone();
    ge[2 + 4 * i] = g.clone();
    Secp256k1.secp256k1GeNeg(ge[3 + 4 * i], g);
    Secp256k1.secp256k1GeNeg(ge[4 + 4 * i], g);
    Secp256k1.secp256k1GejSetGe(gej[1 + 4 * i], ge[1 + 4 * i]);
    randomGeJacobian(gej[2 + 4 * i], ge[2 + 4 * i]);
    Secp256k1.secp256k1GejSetGe(gej[3 + 4 * i], ge[3 + 4 * i]);
    randomGeJacobian(gej[4 + 4 * i], ge[4 + 4 * i]);
    for (j = 0; j < 4; j++) {
      _randomGeXMagnitude(ge[1 + j + 4 * i]);
      _randomGeYGagnitude(ge[1 + j + 4 * i]);
      _randomGejXMagnitude(gej[1 + j + 4 * i]);
      _randomGejYMagnitude(gej[1 + j + 4 * i]);
      _randomGejZmagnitude(gej[1 + j + 4 * i]);
    }
    for (j = 0; j < 4; ++j) {
      for (k = 0; k < 4; ++k) {
        int exc = ((j >> 1) == (k >> 1)) ? 1 : 0;
        expect(Secp256k1.secp256k1GeEqVar(ge[1 + j + 4 * i], ge[1 + k + 4 * i]),
            exc);
        expect(
            Secp256k1.secp256k1GejEqVar(gej[1 + j + 4 * i], gej[1 + k + 4 * i]),
            exc);
        expect(
            Secp256k1.secp256k1GejEqGeVar(
                gej[1 + j + 4 * i], ge[1 + k + 4 * i]),
            exc);
        expect(
            Secp256k1.secp256k1GejEqGeVar(
                gej[1 + k + 4 * i], ge[1 + j + 4 * i]),
            exc);
      }
    }
  }

  /* Generate random zf, and zfi2 = 1/zf^2, zfi3 = 1/zf^3 */
  zf = randomFeNonZero();
  _randomFeMagnitude(zf, 8);
  Secp256k1.secp256k1FeInvVar(zfi3, zf);
  Secp256k1.secp256k1FeSqr(zfi2, zfi3);
  Secp256k1.secp256k1FeMul(zfi3, zfi3, zfi2);

  /* Generate random r */
  r = randomFeNonZero();
  for (i1 = 0; i1 < 1 + 4 * runs; i1++) {
    int i2;
    for (i2 = 0; i2 < 1 + 4 * runs; i2++) {
      /* Compute reference result using gej + gej (var). */
      Secp256k1Gej refj = Secp256k1Gej(), resj = Secp256k1Gej();
      Secp256k1Ge ref = Secp256k1Ge();
      Secp256k1Fe zr = Secp256k1Fe();
      Secp256k1.secp256k1GejAddVar(refj, gej[i1], gej[i2],
          Secp256k1.secp256k1GejIsInfinity(gej[i1]) == 1 ? null : zr);
      /* Check Z ratio. */
      if (Secp256k1.secp256k1GejIsInfinity(gej[i1]) == 0 &&
          Secp256k1.secp256k1GejIsInfinity(refj) == 0) {
        Secp256k1Fe zrz = Secp256k1Fe();
        Secp256k1.secp256k1FeMul(zrz, zr, gej[i1].z);
        expect(Secp256k1.secp256k1FeEqual(zrz, refj.z), 1);
      }
      Secp256k1.secp256k1GeSetGejVar(ref, refj);

      /* Test gej + ge with Z ratio result (var). */
      Secp256k1.secp256k1GejAddGeVar(resj, gej[i1], ge[i2],
          Secp256k1.secp256k1GejIsInfinity(gej[i1]) == 1 ? null : zr);
      expect(Secp256k1.secp256k1GejEqGeVar(resj, ref), 1);
      if (Secp256k1.secp256k1GejIsInfinity(gej[i1]) == 0 &&
          Secp256k1.secp256k1GejIsInfinity(resj) == 0) {
        Secp256k1Fe zrz = Secp256k1Fe();
        Secp256k1.secp256k1FeMul(zrz, zr, gej[i1].z);
        expect(Secp256k1.secp256k1FeEqual(zrz, resj.z), 1);
      }

      /* Test gej + ge (var, with additional Z factor). */
      {
        Secp256k1Ge ge2Zfi = ge[i2]
            .clone(); /* the second term with x and y rescaled for z = 1/zf */
        Secp256k1.secp256k1FeMul(ge2Zfi.x, ge2Zfi.x, zfi2);
        Secp256k1.secp256k1FeMul(ge2Zfi.y, ge2Zfi.y, zfi3);
        _randomGeXMagnitude(ge2Zfi);
        _randomGeYGagnitude(ge2Zfi);
        Secp256k1.secp256k1GejAddZinvVar(resj, gej[i1], ge2Zfi, zf);
        expect(Secp256k1.secp256k1GejEqGeVar(resj, ref), 1);
      }

      /* Test gej + ge (const). */
      if (i2 != 0) {
        /* secp256k1GejAddGe does not support its second argument being infinity. */
        Secp256k1.secp256k1GejAddGe(resj, gej[i1], ge[i2]);
        expect(Secp256k1.secp256k1GejEqGeVar(resj, ref), 1);
      }

      /* Test doubling (var). */
      if ((i1 == 0 && i2 == 0) ||
          ((i1 + 3) / 4 == (i2 + 3) / 4 &&
              ((i1 + 3) % 4) / 2 == ((i2 + 3) % 4) / 2)) {
        Secp256k1Fe zr2 = Secp256k1Fe();
        /* Normal doubling with Z ratio result. */
        Secp256k1.secp256k1GejDoubleVar(resj, gej[i1], zr2);
        expect(Secp256k1.secp256k1GejEqGeVar(resj, ref), 1);
        /* Check Z ratio. */
        Secp256k1.secp256k1FeMul(zr2, zr2, gej[i1].z);
        expect(Secp256k1.secp256k1FeEqual(zr2, resj.z), 1);
        /* Normal doubling. */
        Secp256k1.secp256k1GejDoubleVar(resj, gej[i2], null);
        expect(Secp256k1.secp256k1GejEqGeVar(resj, ref), 1);
        /* Constant-time doubling. */
        Secp256k1.secp256k1GejDouble(resj, gej[i2]);
        expect(Secp256k1.secp256k1GejEqGeVar(resj, ref), 1);
      }

      /* Test adding opposites. */
      if ((i1 == 0 && i2 == 0) ||
          ((i1 + 3) / 4 == (i2 + 3) / 4 &&
              ((i1 + 3) % 4) / 2 != ((i2 + 3) % 4) / 2)) {
        expect(Secp256k1.secp256k1GeIsInfinity(ref), 1);
      }

      /* Test adding infinity. */
      if (i1 == 0) {
        expect(Secp256k1.secp256k1GeIsInfinity(ge[i1]), 1);
        expect(Secp256k1.secp256k1GejIsInfinity(gej[i1]), 1);
        expect(Secp256k1.secp256k1GejEqGeVar(gej[i2], ref), 1);
      }
      if (i2 == 0) {
        expect(Secp256k1.secp256k1GeIsInfinity(ge[i2]), 1);
        expect(Secp256k1.secp256k1GejIsInfinity(gej[i2]), 1);
        expect(Secp256k1.secp256k1GejEqGeVar(gej[i1], ref), 1);
      }
    }
  }

  {
    Secp256k1Gej sum = Secp256k1Gej.infinity();
    List<Secp256k1Gej> gejShuffled =
        List.generate(4 * runs + 1, (i) => Secp256k1Gej());
    for (i = 0; i < 4 * runs + 1; i++) {
      gejShuffled[i] = gej[i];
    }
    for (i = 0; i < 4 * runs + 1; i++) {
      int swap = i + testrandBits(4 * runs + 1 - i);
      if (swap != i) {
        Secp256k1Gej t = gejShuffled[i];
        gejShuffled[i] = gejShuffled[swap];
        gejShuffled[swap] = t;
      }
    }
    for (i = 0; i < 4 * runs + 1; i++) {
      Secp256k1.secp256k1GejAddVar(sum, sum, gejShuffled[i], null);
    }
    expect(Secp256k1.secp256k1GejIsInfinity(sum), 1);
  }
  {
    List<Secp256k1Ge> geSetAllVar =
        List.generate(4 * runs + 1, (_) => Secp256k1Ge());
    List<Secp256k1Ge> geSetAll =
        List.generate(4 * runs + 1, (_) => Secp256k1Ge());
    Secp256k1.secp256k1GeSetAllGejVar(geSetAllVar, gej, 4 * runs + 1);

    for (i = 0; i < 4 * runs + 1; i++) {
      Secp256k1Fe s;
      s = randomFeNonZero();
      Secp256k1.secp256k1GejRescale(gej[i], s);
      expect(Secp256k1.secp256k1GejEqGeVar(gej[i], geSetAllVar[i]), 1);
    }

    Secp256k1.secp256k1GeSetAllGej(
        geSetAll.sublist(1), gej.sublist(1), 4 * runs);

    for (i = 1; i < 4 * runs + 1; i++) {
      Secp256k1Fe s;
      // non zero
      s = randomFeNonZero();
      Secp256k1.secp256k1GejRescale(gej[i], s);
      expect(Secp256k1.secp256k1GejEqGeVar(gej[i], geSetAll[i]), 1);
      expect(Secp256k1.secp256k1GeEqVar(geSetAllVar[i], geSetAll[i]), 1);
    }

    /* Test with an array of length 1. */
    Secp256k1.secp256k1GeSetAllGejVar(geSetAllVar, gej.sublist(1), 1);
    Secp256k1.secp256k1GeSetAllGej(geSetAll, gej.sublist(1), 1);

    expect(Secp256k1.secp256k1GejEqGeVar(gej[1], geSetAllVar[1]), 1);
    expect(Secp256k1.secp256k1GejEqGeVar(gej[1], geSetAll[1]), 1);
    expect(Secp256k1.secp256k1GeEqVar(geSetAllVar[1], geSetAll[1]), 1);
  }

  for (i = 1; i < 4 * runs + 1; i++) {
    Secp256k1Fe n = Secp256k1Fe();
    expect(Secp256k1.secp256k1GeXOnCurveVar(ge[i].x), 1);
    /* And the same holds after random rescaling. */
    Secp256k1.secp256k1FeMul(n, zf, ge[i].x);
    expect(Secp256k1.secp256k1GeXFracOnCurveVar(n, zf), 1);
  }

  {
    Secp256k1Fe n = Secp256k1Fe();
    Secp256k1Ge q = Secp256k1Ge();
    int retOnCurve, retFracOnCurve, retSetXo;
    Secp256k1.secp256k1FeMul(n, zf, r);
    retOnCurve = Secp256k1.secp256k1GeXOnCurveVar(r);
    retFracOnCurve = Secp256k1.secp256k1GeXFracOnCurveVar(n, zf);
    retSetXo = Secp256k1.secp256k1GeSetXoVar(q, r, 0);
    expect(retOnCurve, retFracOnCurve);
    expect(retOnCurve, retSetXo);
    if (retSetXo != 0) expect(Secp256k1.secp256k1FeEqual(r, q.x), 1);
  }

  for (i = 0; i < 4 * runs + 1; i++) {
    int odd;
    randomGeTest(ge[i]);
    // randomGeTest(ge[i]);
    odd = Secp256k1.secp256k1FeIsOdd(ge[i].x);
    expect(odd == 0 || odd == 1, true);
    /* randomly set half the points to infinity */
    if (odd == i % 2) {
      Secp256k1.secp256k1GeSetInfinity(ge[i]);
    }
    Secp256k1.secp256k1GejSetGe(gej[i], ge[i]);
  }
  /* batch convert */
  Secp256k1.secp256k1GeSetAllGejVar(ge, gej, 4 * runs + 1);
  /* check result */
  for (i = 0; i < 4 * runs + 1; i++) {
    expect(Secp256k1.secp256k1GejEqGeVar(gej[i], ge[i]), 1);
  }

  /* Test batch gej -> ge conversion with all infinities. */
  for (i = 0; i < 4 * runs + 1; i++) {
    Secp256k1.secp256k1GejSetInfinity(gej[i]);
  }
  /* batch convert */
  Secp256k1.secp256k1GeSetAllGejVar(ge, gej, 4 * runs + 1);
  /* check result */
  for (i = 0; i < 4 * runs + 1; i++) {
    expect(Secp256k1.secp256k1GeIsInfinity(ge[i]), 1);
  }
}

void _randomFeMagnitude(Secp256k1Fe fe, int m, [int? l]) {
  Secp256k1Fe zero = Secp256k1Fe();
  int n = l ?? testrandBits(m + 1);
  Secp256k1.secp256k1FeNormalize(fe);
  if (n == 0) {
    return;
  }
  Secp256k1.secp256k1FeSetInt(zero, 0);
  Secp256k1.secp256k1FeNegate(zero, zero, 0);
  Secp256k1.secp256k1FeMulInt(zero, n - 1);
  Secp256k1.secp256k1FeAdd(fe, zero);
}

void _randomGejXMagnitude(Secp256k1Gej gej, [int? l]) {
  _randomFeMagnitude(gej.x, Secp256k1Const.secp256k1GejXMagnitudeMax, l);
}

void _randomGejYMagnitude(Secp256k1Gej gej, [int? l]) {
  _randomFeMagnitude(gej.y, Secp256k1Const.secp256k1GejYMagnitudeMax, l);
}

void _randomGejZmagnitude(Secp256k1Gej gej, [int? l]) {
  _randomFeMagnitude(gej.z, Secp256k1Const.secp256k1GejZMagnitudeMax, l);
}

void _randomGeXMagnitude(Secp256k1Ge ge, [int? l]) {
  _randomFeMagnitude(ge.x, Secp256k1Const.secp256k1GeXMagnitudeMax, l);
}

int _geXyzEqualsGej(Secp256k1Gej a, Secp256k1Gej b) {
  Secp256k1Gej a2 = Secp256k1Gej();
  Secp256k1Gej b2 = Secp256k1Gej();
  int ret = 1;
  ret &= (a.infinity == b.infinity) ? 1 : 0;
  if (ret == 1 && a.infinity == 0) {
    a2 = a.clone();
    b2 = b.clone();
    Secp256k1.secp256k1FeNormalize(a2.x);
    Secp256k1.secp256k1FeNormalize(a2.y);
    Secp256k1.secp256k1FeNormalize(a2.z);
    Secp256k1.secp256k1FeNormalize(b2.x);
    Secp256k1.secp256k1FeNormalize(b2.y);
    Secp256k1.secp256k1FeNormalize(b2.z);
    ret &= (Secp256k1.secp256k1FeCmpVar(a2.x, b2.x) == 0) ? 1 : 0;
    ret &= (Secp256k1.secp256k1FeCmpVar(a2.y, b2.y) == 0) ? 1 : 0;
    ret &= (Secp256k1.secp256k1FeCmpVar(a2.z, b2.z) == 0) ? 1 : 0;
  }
  return ret;
}

void _gejCmov(Secp256k1Gej a, Secp256k1Gej b) {
  Secp256k1Gej t = a.clone();
  Secp256k1.secp256k1GejCmov(t, b, 0);
  expect(_geXyzEqualsGej(t, a), 1);
  Secp256k1.secp256k1GejCmov(t, b, 1);
  expect(_geXyzEqualsGej(t, b), 1);
}

void _randomGeYGagnitude(Secp256k1Ge ge, [int? l]) {
  _randomFeMagnitude(ge.y, Secp256k1Const.secp256k1GeYMagnitudeMax, l);
}

void _gej() {
  int i;
  Secp256k1Gej a = Secp256k1Gej(), b = Secp256k1Gej();

  /* Tests for secp256k1GejCmov */
  for (i = 0; i < 16; i++) {
    Secp256k1.secp256k1GejSetInfinity(a);
    Secp256k1.secp256k1GejSetInfinity(b);
    _gejCmov(a, b);

    randomGejTest(a);
    _gejCmov(a, b);
    _gejCmov(b, a);

    b = a;
    _gejCmov(a, b);

    randomGejTest(b);
    _gejCmov(a, b);
    _gejCmov(b, a);
  }

  /* Tests for secp256k1GejEqVar */
  for (i = 0; i < 16; i++) {
    Secp256k1Fe fe = Secp256k1Fe();
    randomGejTest(a);
    randomGejTest(b);
    expect(Secp256k1.secp256k1GejEqVar(a, b), 1);

    b = a;
    fe = randomFeNonZero();
    Secp256k1.secp256k1GejRescale(a, fe);
    expect(Secp256k1.secp256k1GejEqVar(a, b), 1);
  }
}

void _groupDecompress(Secp256k1Fe x) {
  /* The input itself, normalized. */
  Secp256k1Fe fex = x.clone();
  /* Results of set_xo_var(..., 0), set_xo_var(..., 1). */
  Secp256k1Ge geEven = Secp256k1Ge(), geOdd = Secp256k1Ge();
  /* Return values of the above calls. */
  int resEven, resOdd;

  Secp256k1.secp256k1FeNormalizeVar(fex);

  resEven = Secp256k1.secp256k1GeSetXoVar(geEven, fex, 0);
  resOdd = Secp256k1.secp256k1GeSetXoVar(geOdd, fex, 1);

  expect(resEven, resOdd);

  if (resEven == 1) {
    Secp256k1.secp256k1FeNormalizeVar(geOdd.x);
    Secp256k1.secp256k1FeNormalizeVar(geEven.x);
    Secp256k1.secp256k1FeNormalizeVar(geOdd.y);
    Secp256k1.secp256k1FeNormalizeVar(geEven.y);

    /* No infinity allowed. */
    expect(geEven.infinity, 0);
    expect(geOdd.infinity, 0);

    /* Check that the x coordinates check out. */
    expect(Secp256k1.secp256k1FeEqual(geEven.x, x), 1);
    expect(Secp256k1.secp256k1FeEqual(geOdd.x, x), 1);

    /* Check odd/even Y in geOdd, geEven. */
    expect(Secp256k1.secp256k1FeIsOdd(geOdd.y), 1);
    expect(Secp256k1.secp256k1FeIsOdd(geEven.y), 0);
  }
}

void _groupDecompressTest() {
  int i;
  for (i = 0; i < 16 * 4; i++) {
    Secp256k1Fe fe = randomFe();
    _groupDecompress(fe);
  }
}

void _scalarSplit(Secp256k1Scalar full) {
  Secp256k1Scalar s = Secp256k1Scalar(),
      s1 = Secp256k1Scalar(),
      slam = Secp256k1Scalar();
  List<int> zero = List<int>.filled(32, 0);
  List<int> tmp = List<int>.filled(32, 0);

  Secp256k1.secp256k1ScalarSplitLambda(s1, slam, full);

  /* check slam*lambda + s1 == full */
  Secp256k1.secp256k1ScalarMul(s, Secp256k1Const.secp256k1ConstLambda, slam);
  Secp256k1.secp256k1ScalarAdd(s, s, s1);
  expect(Secp256k1.secp256k1ScalarEq(s, full), 1);

  /* check that both are <= 128 bits in size */
  if (Secp256k1.secp256k1ScalarIsHigh(s1) == 1) {
    Secp256k1.secp256k1ScalarNegate(s1, s1);
  }
  if (Secp256k1.secp256k1ScalarIsHigh(slam) == 1) {
    Secp256k1.secp256k1ScalarNegate(slam, slam);
  }

  Secp256k1.secp256k1ScalarGetB32(tmp, s1);
  expect(BytesUtils.bytesEqual(zero.sublist(0, 16), tmp.sublist(0, 16)), true);
  Secp256k1.secp256k1ScalarGetB32(tmp, slam);
  expect(BytesUtils.bytesEqual(zero.sublist(0, 16), tmp.sublist(0, 16)), true);
}

void _endomorphismTests() {
  int i;
  Secp256k1Scalar s = Secp256k1Scalar();
  _scalarSplit(Secp256k1Const.secp256k1ScalarZero);
  _scalarSplit(Secp256k1Const.secp256k1ScalarOne);
  Secp256k1.secp256k1ScalarNegate(s, Secp256k1Const.secp256k1ScalarOne);
  _scalarSplit(s);
  _scalarSplit(Secp256k1Const.secp256k1ConstLambda);
  Secp256k1.secp256k1ScalarAdd(s, Secp256k1Const.secp256k1ConstLambda,
      Secp256k1Const.secp256k1ScalarOne);
  _scalarSplit(s);

  for (i = 0; i < 100 * 16; ++i) {
    Secp256k1Scalar full = Secp256k1Scalar();
    randomScalarOrderTest(full);
    _scalarSplit(full);
  }
  for (i = 0; i < scalarsNearSplitBounds.length; ++i) {
    _scalarSplit(scalarsNearSplitBounds[i]);
  }
}

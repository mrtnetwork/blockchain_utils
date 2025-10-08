// *******************************************************************************
// Copyright (c) 2013, 2014, 2015, 2021 Thomas Daede, Cory Fields, Pieter Wuille *
// Distributed under the MIT software license, see the accompanying              *
// file COPYING or https://www.opensource.org/licenses/mit-license.php.          *
// *******************************************************************************
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:test/test.dart';
import 'test_constants.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';

import 'tools.dart';

void main() {
  // return;
  group("secp256k1 mult", () {
    test("random publickey", _testRandomPublicKey);
    test("edge", () => _testEcmultGenEdgeCases());
    // return;
    test("random xonly", _testRandomXonlyPublicKey);
    test("commutativity", _commutativity);
    test("mult zero one", _multZeroOne);
    test("group", _dges);
    test("random mult", _randomMult);
    test("chain mult", _chainMult);
  });
}

void _testRandomPublicKey() {
  Secp256k1ECmultGenContext cr = Secp256k1ECmultGenContext();
  Secp256k1Utils.secp256k1ECmultGenBlind(cr, null);
  for (int i = 0; i < 250; i++) {
    Secp256k1Scalar a = Secp256k1Scalar();
    randomScalarOrderTest(a);
    Secp256k1Gej res2 = Secp256k1Gej();

    if (i % 5 == 0) {
      Secp256k1Utils.secp256k1ECmultGenBlind(cr, QuickCrypto.generateRandom());
    }
    Secp256k1.secp256k1ECmultGen(cr, res2, a);
    Secp256k1Ge mid2 = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(mid2, res2);
    final m2Bytes = Secp256k1Utils.secp256k1ECkeyPubkeySerialize(mid2, false);

    List<int> scalarByte = List<int>.filled(32, 0);
    Secp256k1.secp256k1ScalarGetB32(scalarByte, a);
    Secp256k1Gej res1 = Secp256k1Gej();
    Secp256k1.secp256k1ECmultConst(res1, Secp256k1Const.G, a);
    Secp256k1Ge mid1 = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(mid1, res1);
    final es = BigintUtils.fromBytes(scalarByte);
    final rr = Curves.generatorSecp256k1 * es;
    final m1Bytes = Secp256k1Utils.secp256k1ECkeyPubkeySerialize(mid1, false);
    expect(BytesUtils.bytesEqual(m1Bytes, rr.toBytes(EncodeType.uncompressed)),
        true);
    expect(BytesUtils.bytesEqual(m1Bytes, m2Bytes), true);
    expect(
        BytesUtils.bytesEqual(
            Secp256k1Utils.secp256k1ECkeyPubkeySerialize(mid1, true),
            rr.toBytes()),
        true);
  }
}

void _testRandomXonlyPublicKey() {
  for (int i = 0; i < 250; i++) {
    Secp256k1Scalar a = Secp256k1Scalar();
    randomScalarOrderTest(a);
    List<int> scalarByte = List<int>.filled(32, 0);
    Secp256k1.secp256k1ScalarGetB32(scalarByte, a);
    Secp256k1Fe res1 = Secp256k1Fe();
    Secp256k1.secp256k1EcmultConstXonly(res1, Secp256k1Const.G.x, a);
    List<int> result = List<int>.filled(32, 0);
    Secp256k1.secp256k1FeGetB32(result, res1);

    Secp256k1Ge mid1 = Secp256k1Ge();
    Secp256k1Gej res12 = Secp256k1Gej();
    Secp256k1.secp256k1ECmultConst(res12, Secp256k1Const.G, a);
    Secp256k1.secp256k1GeSetGej(mid1, res12);
    final es = BigintUtils.fromBytes(scalarByte);
    final rr = Curves.generatorSecp256k1 * es;
    expect(BytesUtils.bytesEqual(result, rr.toXonly()), true);
  }
}

void _commutativity() {
  Secp256k1Scalar a = Secp256k1Scalar();
  List<int> result = List<int>.filled(32, 0);
  Secp256k1.secp256k1ScalarGetB32(result, a);

  Secp256k1Scalar b = Secp256k1Scalar();
  Secp256k1Gej res1 = Secp256k1Gej();
  Secp256k1Gej res2 = Secp256k1Gej();
  Secp256k1Ge mid1 = Secp256k1Ge();
  Secp256k1Ge mid2 = Secp256k1Ge();

  randomScalarOrderTest(a);
  randomScalarOrderTest(b);
  Secp256k1.secp256k1ECmultConst(res1, Secp256k1Const.G, a);
  Secp256k1.secp256k1ECmultConst(res2, Secp256k1Const.G, b);

  Secp256k1.secp256k1GeSetGej(mid1, res1);
  Secp256k1.secp256k1GeSetGej(mid2, res2);
  Secp256k1.secp256k1ECmultConst(res1, mid1, b);
  Secp256k1.secp256k1ECmultConst(res2, mid2, a);
  Secp256k1.secp256k1GeSetGej(mid1, res1);
  Secp256k1.secp256k1GeSetGej(mid2, res2);
  expect(Secp256k1.secp256k1GeEqVar(mid1, mid2), 1);
}

void _multZeroOne() {
  Secp256k1Scalar s = Secp256k1Scalar();
  Secp256k1Scalar negone = Secp256k1Scalar();
  Secp256k1Gej res1 = Secp256k1Gej();
  Secp256k1Ge res2 = Secp256k1Ge();
  Secp256k1Ge point = Secp256k1Ge();
  Secp256k1Ge inf = Secp256k1Ge();

  randomScalarOrderTest(s);
  Secp256k1.secp256k1ScalarNegate(negone, Secp256k1Const.secp256k1ScalarOne);
  randomGeTest(point);
  Secp256k1.secp256k1GeSetInfinity(inf);

  /* 0*point */
  Secp256k1.secp256k1ECmultConst(
      res1, point, Secp256k1Const.secp256k1ScalarZero);
  expect(Secp256k1.secp256k1GejIsInfinity(res1), 1);

  /* s*inf */
  Secp256k1.secp256k1ECmultConst(res1, inf, s);
  expect(Secp256k1.secp256k1GejIsInfinity(res1), 1);

  /* 1*point */
  Secp256k1.secp256k1ECmultConst(
      res1, point, Secp256k1Const.secp256k1ScalarOne);
  Secp256k1.secp256k1GeSetGej(res2, res1);
  expect(Secp256k1.secp256k1GeEqVar(res2, point), 1);

  /* -1*point */
  Secp256k1.secp256k1ECmultConst(res1, point, negone);
  Secp256k1.secp256k1GejNeg(res1, res1);
  Secp256k1.secp256k1GeSetGej(res2, res1);
  expect(Secp256k1.secp256k1GeEqVar(res2, point), 1);
}

void _dges() {
  Secp256k1Scalar q = Secp256k1Scalar();
  Secp256k1Ge point = Secp256k1Ge();
  Secp256k1Gej res = Secp256k1Gej();
  int i;
  int cases = 1 + scalarsNearSplitBounds.length;

  /* We are trying to reach the following edge cases (variables are defined as
     * in ecmult_const_impl.h):
     *   1. i = 0: s = 0 <=> q = -K
     *   2. i > 0: v1, v2 large values
     *               <=> s1, s2 large values
     *               <=> s = scalarsNearSplitBounds[i]
     *               <=> q = 2*scalarsNearSplitBounds[i] - K
     */
  for (i = 0; i < cases; ++i) {
    Secp256k1.secp256k1ScalarNegate(q, Secp256k1Const.secp256k1ECmultConstK);
    if (i > 0) {
      Secp256k1.secp256k1ScalarAdd(q, q, scalarsNearSplitBounds[i - 1]);
      Secp256k1.secp256k1ScalarAdd(q, q, scalarsNearSplitBounds[i - 1]);
    }
    randomGeTest(point);
    Secp256k1.secp256k1ECmultConst(res, point, q);
    // _result(point, q, res);
  }
}

// void _result(Secp256k1Ge A, Secp256k1Scalar q, Secp256k1Gej res) {
//   Secp256k1Gej pointj = Secp256k1Gej(), res2j = Secp256k1Gej();
//   Secp256k1Ge res2 = Secp256k1Ge();
//   Secp256k1.secp256k1GejSetGe(pointj, A);
//   // secp256k1_ecmult(res2j, pointj, q, Secp256k1.secp256k1ScalarZero);
//   Secp256k1.secp256k1GeSetGej(res2, res2j);
//   assert(Secp256k1.secp256k1GejEqGeVar(res, res2) == 1);
// }

void _randomMult() {
  /* random starting point A (on the curve) */
  Secp256k1Ge a = Secp256k1Ge.constants(
      BigInt.from(0x6d986544),
      BigInt.from(0x57ff52b8),
      BigInt.from(0xcf1b8126),
      BigInt.from(0x5b802a5b),
      BigInt.from(0xa97f9263),
      BigInt.from(0xb1e88044),
      BigInt.from(0x93351325),
      BigInt.from(0x91bc450a),
      BigInt.from(0x535c59f7),
      BigInt.from(0x325e5d2b),
      BigInt.from(0xc391fbe8),
      BigInt.from(0x3c12787c),
      BigInt.from(0x337e4a98),
      BigInt.from(0xe82a9011),
      BigInt.from(0x0123ba37),
      BigInt.from(0xdd769c7d));
  /* random initial factor xn */
  Secp256k1Scalar xn = Secp256k1Scalar.constants(
      BigInt.from(0x649d4f77),
      BigInt.from(0xc4242df7),
      BigInt.from(0x7f2079c9),
      BigInt.from(0x14530327),
      BigInt.from(0xa31b876a),
      BigInt.from(0xd2d8ce2a),
      BigInt.from(0x2236d5c6),
      BigInt.from(0xd7b2029b));
  /* expected xn * A (from sage) */
  Secp256k1Ge excB = Secp256k1Ge.constants(
      BigInt.from(0x23773684),
      BigInt.from(0x4d209dc7),
      BigInt.from(0x098a786f),
      BigInt.from(0x20d06fcd),
      BigInt.from(0x070a38bf),
      BigInt.from(0xc11ac651),
      BigInt.from(0x03004319),
      BigInt.from(0x1e2a8786),
      BigInt.from(0xed8c3b8e),
      BigInt.from(0xc06dd57b),
      BigInt.from(0xd06ea66e),
      BigInt.from(0x45492b0f),
      BigInt.from(0xb84e4e1b),
      BigInt.from(0xfb77e21f),
      BigInt.from(0x96baae2a),
      BigInt.from(0x63dec956));
  Secp256k1Gej b = Secp256k1Gej();
  Secp256k1.secp256k1ECmultConst(b, a, xn);

  expect(Secp256k1.secp256k1GeIsValidVar(a), 1);
  expect(Secp256k1.secp256k1GejEqGeVar(b, excB), 1);
}

void _chainMult() {
  /* Check known result (randomly generated test problem from sage) */
  final Secp256k1Scalar scalar = Secp256k1Scalar.constants(
      BigInt.from(0x4968d524),
      BigInt.from(0x2abf9b7a),
      BigInt.from(0x466abbcf),
      BigInt.from(0x34b11b6d),
      BigInt.from(0xcd83d307),
      BigInt.from(0x827bed62),
      BigInt.from(0x05fad0ce),
      BigInt.from(0x18fae63b));
  Secp256k1Gej excPoint = Secp256k1Gej.constants(
      BigInt.from(0x5494c15d),
      BigInt.from(0x32099706),
      BigInt.from(0xc2395f94),
      BigInt.from(0x348745fd),
      BigInt.from(0x757ce30e),
      BigInt.from(0x4e8c90fb),
      BigInt.from(0xa2bad184),
      BigInt.from(0xf883c69f),
      BigInt.from(0x5d195d20),
      BigInt.from(0xe191bf7f),
      BigInt.from(0x1be3e55f),
      BigInt.from(0x56a80196),
      BigInt.from(0x6071ad01),
      BigInt.from(0xf1462f66),
      BigInt.from(0xc997fa94),
      BigInt.from(0xdb858435));
  Secp256k1Gej point = Secp256k1Gej();
  Secp256k1Ge res = Secp256k1Ge();
  int i;

  Secp256k1.secp256k1GejSetGe(point, Secp256k1Const.G);
  for (i = 0; i < 100; ++i) {
    Secp256k1Ge tmp = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(tmp, point);
    Secp256k1.secp256k1ECmultConst(point, tmp, scalar);
  }
  Secp256k1.secp256k1GeSetGej(res, point);
  expect(Secp256k1.secp256k1GejEqGeVar(excPoint, res), 1);
}

void _testEcmultGenEdgeCases() {
  Secp256k1ECmultGenContext cr = Secp256k1ECmultGenContext();
  Secp256k1Utils.secp256k1ECmultGenBlind(cr, null);
  int i;
  Secp256k1Gej res1 = Secp256k1Gej(), res3 = Secp256k1Gej();
  Secp256k1Scalar gn = Secp256k1Const.secp256k1ScalarOne.clone(); /* gn = 1 */
  Secp256k1.secp256k1ScalarAdd(
      gn, gn, cr.scalarOffset); /* gn = 1 + scalarOffset */
  Secp256k1.secp256k1ScalarNegate(gn, gn); /* gn = -1 - scalarOffset */

  for (i = -1; i < 2; ++i) {
    Secp256k1.secp256k1ECmultGen(cr, res1, gn);
    Secp256k1.secp256k1ECmultConst(res3, Secp256k1Const.G, gn);
    expect(Secp256k1.secp256k1GejEqVar(res1, res3), 1);
    Secp256k1.secp256k1ScalarAdd(gn, gn, Secp256k1Const.secp256k1ScalarOne);
  }
}

//  void ecmult_const_mult_xonly(void) {
//     int i;

//     /* Test correspondence between secp256k1ECmultConst and secp256k1EcmultConstXonly. */
//     for (i = 0; i < 2*16; ++i) {
//         Secp256k1Ge base = Secp256k1Ge();
//         Secp256k1Gej basej = Secp256k1Gej(), resj = Secp256k1Gej();
//         Secp256k1Fe n = Secp256k1Fe(), d = Secp256k1Fe(), resx = Secp256k1Fe(), v = Secp256k1Fe();
//         Secp256k1Scalar q;
//         int res;
//         /* Random base point. */
//         randomGeTest(base);
//         /* Random scalar to multiply it with. */
//         randomScalarOrderTest(q);
//         /* If i is odd, n=d*base.x for random non-zero d */
//         if ((i & 1)!=0) {
//             testutil_random_fe_non_zero_test(d);
//            Secp256k1. secp256k1FeMul(n, base.x, d);
//         } else {
//             n = base.x;
//         }
//         /* Perform x-only multiplication. */
//         res =  Secp256k1.secp256k1EcmultConstXonly(resx, n, (i & 1)==1 ? d : null, q, i & 2);
//         assert(res==1);
//         /* Perform normal multiplication. */
//         Secp256k1. secp256k1GejSetGe(&basej, &base);
//          Secp256k1.secp256k1_ecmult(&resj, &basej, &q, NULL);
//         /* Check that resj's X coordinate corresponds with resx. */
//         Secp256k1. secp256k1FeSqr(&v, &resj.z);
//         Secp256k1. secp256k1FeMul(&v, &v, &resx);
//         CHECK(fe_equal(&v, &resj.x));
//     }

//     /* Test that secp256k1EcmultConstXonly correctly rejects X coordinates not on curve. */
//     for (i = 0; i < 2*COUNT; ++i) {
//         Secp256k1Fe x, n, d, r;
//         int res;
//         Secp256k1Scalar q;
//         randomScalarOrderTest(&q);
//         /* Generate random X coordinate not on the curve. */
//         do {
//             testutil_random_fe_test(&x);
//         } while (secp256k1GeXOnCurveVar(&x));
//         /* If i is odd, n=d*x for random non-zero d. */
//         if (i & 1) {
//             testutil_random_fe_non_zero_test(&d);
//             secp256k1FeMul(&n, &x, &d);
//         } else {
//             n = x;
//         }
//         res = secp256k1EcmultConstXonly(&r, &n, (i & 1) ? &d : NULL, &q, 0);
//         CHECK(res == 0);
//     }
// }

// void _testPreGTable(List<Secp256k1GeStorage> preG, int n) {
//   /* Tests the preG / pre_g_128 tables for consistency.
//      * For independent verification we take a "geometric" approach to verification.
//      * We check that every entry is on-curve.
//      * We check that for consecutive entries p and q, that p + gg - q = 0 by checking
//      *  (1) p, gg, and -q are colinear.
//      *  (2) p, gg, and -q are all distinct.
//      * where gg is twice the generator, where the generator is the first table entry.
//      *
//      * Checking the table's generators are correct is done in _preG.
//      */
//   Secp256k1Gej g2 = Secp256k1Gej();
//   Secp256k1Ge p = Secp256k1Ge(), q = Secp256k1Ge(), gg = Secp256k1Ge();
//   Secp256k1Fe dpx = Secp256k1Fe(),
//       dpy = Secp256k1Fe(),
//       dqx = Secp256k1Fe(),
//       dqy = Secp256k1Fe();
//   int i;

//   assert(0 < n);

//   Secp256k1.secp256k1GeFromStorage(p, preG[0]);
//   assert(Secp256k1.secp256k1GeIsValidVar(p) == 1);

//   Secp256k1.secp256k1GejSetGe(g2, p);
//   Secp256k1.secp256k1GejDoubleVar(g2, g2, null);
//   Secp256k1.secp256k1GeSetGejVar(gg, g2);
//   for (i = 1; i < n; ++i) {
//     Secp256k1.secp256k1FeNegate(dpx, p.x, 1);
//     Secp256k1.secp256k1FeAdd(dpx, gg.x);
//     Secp256k1.secp256k1FeNormalizeWeak(dpx);
//     Secp256k1.secp256k1FeNegate(dpy, p.y, 1);
//     Secp256k1.secp256k1FeAdd(dpy, gg.y);
//     Secp256k1.secp256k1FeNormalizeWeak(dpy);
//     /* Check that p is not equal to gg */
//     assert(Secp256k1.secp256k1FeNormalizesToZeroVar(dpx) == 0 ||
//         Secp256k1.secp256k1FeNormalizesToZeroVar(dpy) == 0);

//     Secp256k1.secp256k1GeFromStorage(q, preG[i]);
//     assert(Secp256k1.secp256k1GeIsValidVar(q) == 1);

//     Secp256k1.secp256k1FeNegate(dqx, q.x, 1);
//     Secp256k1.secp256k1FeAdd(dqx, gg.x);
//     dqy = q.y;
//     Secp256k1.secp256k1FeAdd(dqy, gg.y);
//     /* Check that -q is not equal to gg */
//     assert(Secp256k1.secp256k1FeNormalizesToZeroVar(dqx) == 0 ||
//         Secp256k1.secp256k1FeNormalizesToZeroVar(dqy) == 0);

//     /* Check that -q is not equal to p */
//     assert(Secp256k1.secp256k1FeEqual(dpx, dqx) == 0 ||
//         Secp256k1.secp256k1FeEqual(dpy, dqy) == 0);

//     /* Check that p, -q and gg are colinear */
//     Secp256k1.secp256k1FeMul(dpx, dpx, dqy);
//     Secp256k1.secp256k1FeMul(dpy, dpy, dqx);
//     assert(Secp256k1.secp256k1FeEqual(dpx, dpy) == 1);

//     p = q;
//   }
// }

// void _preG() {
//   Secp256k1GeStorage gs = Secp256k1GeStorage();
//   Secp256k1Gej gj = Secp256k1Gej();
//   Secp256k1Ge g = Secp256k1Ge();
//   int i;
//   List<Secp256k1GeStorage> secp256k1PreG =
//       List<Secp256k1GeStorage>.generate(8192, (i) => Secp256k1GeStorage());
//   List<Secp256k1GeStorage> secp256k1PreG128 =
//       List<Secp256k1GeStorage>.generate(8192, (i) => Secp256k1GeStorage());
//   /* Check that the preG and pre_g_128 tables are consistent. */
//   _testPreGTable(secp256k1PreG, 8192);
//   _testPreGTable(secp256k1PreG128, 8192);

//   /* Check the first entry from the preG table. */
//   Secp256k1.secp256k1GeToStorage(gs, Secp256k1Const.G);
//   // ass(secp256k1_memcmp_var(&gs, &secp256k1PreG[0], sizeof(gs)) == 0);

//   /* Check the first entry from the pre_g_128 table. */
//   Secp256k1.secp256k1GejSetGe(gj, Secp256k1Const.G);
//   for (i = 0; i < 128; ++i) {
//     Secp256k1.secp256k1GejDoubleVar(gj, gj, null);
//   }
//   Secp256k1.secp256k1GeSetGej(g, gj);
//   Secp256k1.secp256k1GeToStorage(gs, g);
//   // CHECK(secp256k1_memcmp_var(&gs, &secp256k1PreG128[0], sizeof(gs)) == 0);
// }

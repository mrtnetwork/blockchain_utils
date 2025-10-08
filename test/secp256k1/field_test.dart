// *******************************************************************************
// Copyright (c) 2013, 2014, 2015, 2021 Thomas Daede, Cory Fields, Pieter Wuille *
// Distributed under the MIT software license, see the accompanying              *
// file COPYING or https://www.opensource.org/licenses/mit-license.php.          *
// *******************************************************************************

import 'dart:math';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';
import 'package:test/test.dart';
import 'tools.dart';

void main() {
  group("secp256k1 field", () {
    test("sqrt", () => _sqrt());
    test("mul", () => _feMul());
    test("sqr", () => _sqr());
    test("fields", () => _fields());
  });
}

void _sqr() {
  int i;
  Secp256k1Fe x = Secp256k1Fe(),
      y = Secp256k1Fe(),
      lhs = Secp256k1Fe(),
      rhs = Secp256k1Fe(),
      tmp = Secp256k1Fe();

  Secp256k1.secp256k1FeSetInt(x, 1);
  Secp256k1.secp256k1FeNegate(x, x, 1);
  for (i = 1; i <= 512; ++i) {
    Secp256k1.secp256k1FeMulInt(x, 2);
    Secp256k1.secp256k1FeNormalize(x);
    /* Check that (x+y)*(x-y) = x^2 - y*2 for some random values y */
    y = randomFe();

    lhs = x.clone();
    Secp256k1.secp256k1FeAdd(lhs, y); /* lhs = x+y */
    Secp256k1.secp256k1FeNegate(tmp, y, 1); /* tmp = -y */
    Secp256k1.secp256k1FeAdd(tmp, x); /* tmp = x-y */
    Secp256k1.secp256k1FeMul(lhs, lhs, tmp); /* lhs = (x+y)*(x-y) */

    Secp256k1.secp256k1FeSqr(rhs, x); /* rhs = x^2 */
    Secp256k1.secp256k1FeSqr(tmp, y); /* tmp = y^2 */
    Secp256k1.secp256k1FeNegate(tmp, tmp, 1); /* tmp = -y^2 */
    Secp256k1.secp256k1FeAdd(rhs, tmp); /* rhs = x^2 - y^2 */

    expect(_feEqual(lhs, rhs), 1);
  }
}

int _feEqual(Secp256k1Fe a, Secp256k1Fe b) {
  Secp256k1Fe an = a.clone();
  Secp256k1Fe bn = b.clone();
  Secp256k1.secp256k1FeNormalizeWeak(an);
  return Secp256k1.secp256k1FeEqual(an, bn);
}

void _randomFeMagnitude(Secp256k1Fe fe, int m) {
  Secp256k1Fe zero = Secp256k1Fe();
  int n = Random.secure().nextInt(m + 1);
  Secp256k1.secp256k1FeNormalize(fe);
  if (n == 0) {
    return;
  }
  Secp256k1.secp256k1FeSetInt(zero, 0);
  Secp256k1.secp256k1FeNegate(zero, zero, 0);
  Secp256k1.secp256k1FeMulInt(zero, n - 1);
  Secp256k1.secp256k1FeAdd(fe, zero);
}

void _feMul() {
  int i;
  for (i = 0; i < 100 * 16; ++i) {
    Secp256k1Fe a, b, c, d;
    a = randomFe();
    _randomFeMagnitude(a, 8);
    b = randomFe();
    _randomFeMagnitude(b, 8);
    c = randomFe();
    _randomFeMagnitude(c, 8);
    d = randomFe();
    _randomFeMagnitude(d, 8);
    _testFeMull(a, a, 1);
    _testFeMull(c, c, 1);
    _testFeMull(a, b, 0);
    _testFeMull(a, c, 0);
    _testFeMull(c, b, 0);
    _testFeMull(c, d, 0);
  }
}

void _testFeMull(Secp256k1Fe a, Secp256k1Fe b, int useSqr) {
  Secp256k1Fe c = Secp256k1Fe(), an = Secp256k1Fe(), bn = Secp256k1Fe();
  /* Variables in BE 32-byte format. */
  List<int> a32 = List<int>.filled(32, 0),
      b32 = List<int>.filled(32, 0),
      c32 = List<int>.filled(32, 0);
  /* Variables in LE 16x uint16_t format. */
  List<int> a16 = List<int>.filled(16, 0),
      b16 = List<int>.filled(16, 0),
      c16 = List<int>.filled(16, 0);
  /* Field modulus in LE 16x uint16_t format. */
  List<int> m16 = [
    0xfc2f,
    0xffff,
    0xfffe,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
    0xffff,
  ];
  List<int> t16 = List<int>.filled(32, 0);
  int i;

  /* Compute C = A * B in fe format. */
  c = a.clone();
  if (useSqr != 0) {
    Secp256k1.secp256k1FeSqr(c, c);
  } else {
    Secp256k1.secp256k1FeMul(c, c, b);
  }

  /* Convert A, B, C into LE 16x uint16_t format. */
  an = a.clone();
  bn = b.clone();
  Secp256k1.secp256k1FeNormalizeVar(c);
  Secp256k1.secp256k1FeNormalizeVar(an);
  Secp256k1.secp256k1FeNormalizeVar(bn);
  Secp256k1.secp256k1FeGetB32(a32, an);
  Secp256k1.secp256k1FeGetB32(b32, bn);
  Secp256k1.secp256k1FeGetB32(c32, c);
  for (i = 0; i < 16; ++i) {
    a16[i] = (a32[31 - 2 * i] + (a32[30 - 2 * i].toUnsigned(16) << 8))
        .toUnsigned(16);
    b16[i] = (b32[31 - 2 * i] + (b32[30 - 2 * i].toUnsigned(16) << 8))
        .toUnsigned(16);
    c16[i] = (c32[31 - 2 * i] + (c32[30 - 2 * i].toUnsigned(16) << 8))
        .toUnsigned(16);
  }

  // /* Compute T = A * B in LE 16x uint16_t format. */
  _mulmod256(t16, a16, b16, m16);

  for (i = 0; i < 16; i++) {
    int diff = t16[i] - c16[i];
    expect(diff, 0);
  }
  // /* Compare */
}

void _mulmod256(List<int> out, List<int> a, [List<int>? b, List<int>? m]) {
  if (a.length != 16) {
    throw ArgumentError('Expected a.length == 16 and out.length == 32');
  }

  final mul = List<int>.filled(32, 0);
  int mulBitLen = 0;
  int mBitLen = 0;

  if (b != null) {
    if (b.length != 16) throw ArgumentError('b.length must be 16');

    // Compute the product a * b -> mul (512-bit)
    BigInt c = BigInt.zero;
    for (int i = 0; i < 32; i++) {
      // c = BigInt.zero;
      for (int j = i <= 15 ? 0 : i - 15; j <= i && j <= 15; j++) {
        c += BigInt.from(a[j] * b[i - j]).toUnsigned(64);
      }
      mul[i] = (c & BigInt.from(0xFFFF)).toInt();
      c >>= 16;
    }
    expect(c, BigInt.zero);

    // Compute highest set bit in mul
    for (int i = 511; i >= 0; i--) {
      if (((mul[i >> 4] >> (i & 15)) & 1) != 0) {
        mulBitLen = i;
        break;
      }
    }
  } else {
    // b == null -> treat b as 1
    for (int i = 0; i < 16; i++) {
      mul[i] = a[i];
    }
    for (int i = 16; i < 32; i++) {
      mul[i] = 0;
    }

    // Compute highest set bit in mul
    for (int i = 255; i >= 0; i--) {
      if (((mul[i >> 4] >> (i & 15)) & 1) != 0) {
        mulBitLen = i;
        break;
      }
    }
  }

  if (m != null) {
    if (m.length != 16) throw ArgumentError('m.length must be 16');

    // Compute highest set bit in m
    for (int i = 255; i >= 0; i--) {
      if (((m[i >> 4] >> (i & 15)) & 1) != 0) {
        mBitLen = i;
        break;
      }
    }

    for (int i = mulBitLen - mBitLen; i >= 0; i--) {
      final mul2 = List<int>.filled(32, 0);
      BigInt cs = BigInt.zero;

      for (int j = 0; j < 32; j++) {
        int sub = 0;

        for (int p = 0; p < 16; p++) {
          int bitpos = j * 16 - i + p;
          if (bitpos >= 0 && bitpos < 256) {
            sub |= (((m[bitpos >> 4] >> (bitpos & 15)) & 1) << p);
          }
        }

        cs += BigInt.from(mul[j]);
        cs -= BigInt.from(sub);
        mul2[j] = (cs & BigInt.from(0xFFFF)).toInt();
        cs >>= 16;
      }

      if (cs == BigInt.zero) {
        for (int k = 0; k < 32; k++) {
          mul[k] = mul2[k];
        }
      }
    }

    // Check upper limbs are zero beyond modulus
    for (int i = (mBitLen >> 4) + 1; i < 32; i++) {
      expect(mul[i], 0);
    }
  }

  for (int i = 0; i < 16; i++) {
    out[i] = mul[i];
  }
}

void _testSqrt(Secp256k1Fe a, Secp256k1Fe? k) {
  Secp256k1Fe r1 = Secp256k1Fe(), r2 = Secp256k1Fe();
  int v = Secp256k1.secp256k1FeSqrt(r1, a);
  expect((v == 0), (k == null));

  if (k != null) {
    /* Check that the returned root is +/- the given known answer */
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

void _sqrt() {
  Secp256k1Fe ns = Secp256k1Fe(),
      x = Secp256k1Fe(),
      s = Secp256k1Fe(),
      t = Secp256k1Fe();
  int i;

  /* Check sqrt(0) is 0 */
  Secp256k1.secp256k1FeSetInt(x, 0);
  Secp256k1.secp256k1FeSqr(s, x);
  // printU64_5("fe: ",s.n);
  // return;
  _testSqrt(s, x);

  /* Check sqrt of small squares (and their negatives) */
  for (i = 1; i <= 100; i++) {
    Secp256k1.secp256k1FeSetInt(x, i);
    Secp256k1.secp256k1FeSqr(s, x);
    _testSqrt(s, x);
    Secp256k1.secp256k1FeNegate(t, s, 1);
    _testSqrt(t, null);
  }

  /* Consistency checks for large random values */
  for (i = 0; i < 10; i++) {
    int j;
    ns = randomFeNonSqrt();
    for (j = 0; j < 16; j++) {
      x = randomFe();
      Secp256k1.secp256k1FeSqr(s, x);
      expect(Secp256k1.secp256k1FeIsSquareVar(s) != 0, true);
      _testSqrt(s, x);
      Secp256k1.secp256k1FeNegate(t, s, 1);
      expect(Secp256k1.secp256k1FeIsSquareVar(t), 0);
      _testSqrt(t, null);
      Secp256k1.secp256k1FeMul(t, s, ns);
      _testSqrt(t, null);
    }
  }
}

int _testrandBits15() => Random().nextInt(1 << 15); // 0 to 32767

void _fields() {
  Secp256k1Fe x = Secp256k1Fe();
  Secp256k1Fe y = Secp256k1Fe();
  Secp256k1Fe z = Secp256k1Fe();
  Secp256k1Fe q = Secp256k1Fe();
  int v;
  Secp256k1Fe fe5 = Secp256k1Fe.constants(BigInt.zero, BigInt.zero, BigInt.zero,
      BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.from(5));
  int i, j;
  for (i = 0; i < 1000 * 16; i++) {
    Secp256k1FeStorage xs = Secp256k1FeStorage(),
        ys = Secp256k1FeStorage(),
        zs = Secp256k1FeStorage();
    x = randomFe();
    y = randomFeNonZero();
    v = _testrandBits15();
    /* Test that fe_add_int is equivalent to fe_set_int + fe_add. */
    Secp256k1.secp256k1FeSetInt(q, v); /* q = v */
    z = x.clone(); /* z = x */
    Secp256k1.secp256k1FeAdd(z, q); /* z = x+v */
    q = x.clone(); /* q = x */
    Secp256k1.secp256k1FeAddInt(q, v); /* q = x+v */
    expect(_feEqual(q, z) != 0, true);
    /* Test the fe equality and comparison operations. */
    expect(Secp256k1.secp256k1FeEqual(x, x) != 0, true);
    z = x.clone();
    Secp256k1.secp256k1FeAdd(z, y);
    /* Test fe conditional move; z is not normalized here. */
    q = x.clone();
    Secp256k1.secp256k1FeCmov(x, z, 0);
    x = q.clone();
    Secp256k1.secp256k1FeCmov(x, x, 1);

    expect(_feIdentical(x, z), BigInt.zero);
    expect(_feIdentical(x, q) != BigInt.zero, true);
    Secp256k1.secp256k1FeCmov(q, z, 1);
    expect(_feIdentical(q, z), BigInt.one);
    q = z.clone();
    Secp256k1.secp256k1FeNormalizeVar(x);
    Secp256k1.secp256k1FeNormalizeVar(z);
    expect(Secp256k1.secp256k1FeEqual(x, z), 0);
    Secp256k1.secp256k1FeNormalizeVar(q);
    Secp256k1.secp256k1FeCmov(q, z, (i & 1));

    for (j = 0; j < 6; j++) {
      Secp256k1.secp256k1FeNegate(z, z, j + 1);
      Secp256k1.secp256k1FeNormalizeVar(q);
      Secp256k1.secp256k1FeCmov(q, z, (j & 1));
    }
    Secp256k1.secp256k1FeNormalizeVar(z);
    /* Test storage conversion and conditional moves. */
    Secp256k1.secp256k1FeToStorage(xs, x);
    Secp256k1.secp256k1FeToStorage(ys, y);
    Secp256k1.secp256k1FeToStorage(zs, z);
    Secp256k1.secp256k1FeStorageCmov(zs, xs, 0);
    Secp256k1.secp256k1FeStorageCmov(zs, zs, 1);
    Secp256k1.secp256k1FeStorageCmov(ys, xs, 1);
    Secp256k1.secp256k1FeFromStorage(x, xs);
    Secp256k1.secp256k1FeFromStorage(y, ys);
    Secp256k1.secp256k1FeFromStorage(z, zs);
    /* Test that mul_int, mul, and add agree. */
    Secp256k1.secp256k1FeAdd(y, x);
    Secp256k1.secp256k1FeAdd(y, x);
    z = x.clone();
    Secp256k1.secp256k1FeMulInt(z, 3);
    expect(_feEqual(y, z) != 0, true);
    Secp256k1.secp256k1FeAdd(y, x);
    Secp256k1.secp256k1FeAdd(z, x);
    expect(_feEqual(z, y) != 0, true);
    z = x.clone();
    Secp256k1.secp256k1FeMulInt(z, 5);
    Secp256k1.secp256k1FeMul(q, x, fe5);
    expect(_feEqual(z, q) != 0, true);
    Secp256k1.secp256k1FeNegate(x, x, 1);
    Secp256k1.secp256k1FeAdd(z, x);
    Secp256k1.secp256k1FeAdd(q, x);
    expect(_feEqual(y, z) != 0, true);
    expect(_feEqual(q, y) != 0, true);
    /* Check secp256k1FeHalf. */
    z = x.clone();
    Secp256k1.secp256k1FeHalf(z);
    Secp256k1.secp256k1FeAdd(z, z.clone());
    expect(_feEqual(x, z) != 0, true);
    Secp256k1.secp256k1FeAdd(z, z);
    Secp256k1.secp256k1FeHalf(z);
    expect(_feEqual(x, z) != 0, true);
  }
}

BigInt _feIdentical(Secp256k1Fe a, Secp256k1Fe b) {
  BigInt ret = BigInt.one;
  /* Compare the struct member that holds the limbs. */
  for (int i = 0; i < 5; i++) {
    BigInt diff = a[i] - b[i];
    if (diff != BigInt.zero) {
      return ret & BigInt.zero;
    }
  }
  return BigInt.one;
}

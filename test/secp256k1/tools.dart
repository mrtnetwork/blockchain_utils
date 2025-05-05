// *******************************************************************************
// Copyright (c) 2013, 2014, 2015, 2021 Thomas Daede, Cory Fields, Pieter Wuille *
// Distributed under the MIT software license, see the accompanying              *
// file COPYING or https://www.opensource.org/licenses/mit-license.php.          *
// *******************************************************************************

import 'dart:math';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';

Secp256k1Fe randomFe() {
  while (true) {
    final x = Secp256k1Fe();
    if (Secp256k1.secp256k1FeImplSetB32Limit(x, QuickCrypto.generateRandom()) ==
        1) {
      return x;
    }
  }
}

Secp256k1Fe randomFeNonZero() {
  Secp256k1Fe x = randomFe();
  while (Secp256k1.secp256k1FeIsZero(x) == 1) {
    x = randomFe();
  }
  return x;
}

Secp256k1Fe randomFeNonSqrt() {
  Secp256k1Fe r = Secp256k1Fe();
  Secp256k1Fe x = randomFeNonZero();
  if (Secp256k1.secp256k1FeSqrt(r, x) == 1) {
    // x = randomFe();
    Secp256k1.secp256k1FeNegate(x, x, 1);
  }
  return x;
}

void mulmod256(List<int> out, List<int> a, [List<int>? b, List<int>? m]) {
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
    assert(c == BigInt.zero);

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
      assert(mul[i] == 0);
    }
  }

  for (int i = 0; i < 16; i++) {
    out[i] = mul[i];
  }
}

void randomGejTest(Secp256k1Gej gej) {
  Secp256k1Ge ge = Secp256k1Ge();
  randomGeTest(ge);
  randomGeJacobian(gej, ge);
}

void randomGeJacobian(Secp256k1Gej gej, Secp256k1Ge ge, [Secp256k1Fe? z]) {
  Secp256k1Fe z2 = Secp256k1Fe(), z3 = Secp256k1Fe();
  gej.z = z ?? randomFeNonZero();
  Secp256k1.secp256k1FeSqr(z2, gej.z);
  Secp256k1.secp256k1FeMul(z3, z2, gej.z);
  Secp256k1.secp256k1FeMul(gej.x, ge.x, z2);
  Secp256k1.secp256k1FeMul(gej.y, ge.y, z3);
  gej.infinity = ge.infinity;
}

void randomGeTest(Secp256k1Ge ge) {
  Secp256k1Fe fe;
  do {
    fe = randomFe();
    if (Secp256k1.secp256k1GeSetXoVar(ge, fe, testrandBits1()) == 1) {
      Secp256k1.secp256k1FeNormalize(ge.y);
      break;
    }
  } while (true);
  ge.infinity = 0;
}

int testrandBits1() => Random().nextInt(2);
void randomScalarOrderTest(Secp256k1Scalar num) {
  while (true) {
    List<int> b32 = QuickCrypto.generateRandom();
    Secp256k1.secp256k1ScalarSetB32(num, b32);
    if (Secp256k1.secp256k1ScalarIsZero(num) == 1) {
      continue;
    }
    break;
  }
}

int testrandBits(int nBits) {
  if (nBits <= 0 || nBits > 32) {
    throw ArgumentError('nBits must be between 1 and 32');
  }
  return Random().nextInt(nBits);
}

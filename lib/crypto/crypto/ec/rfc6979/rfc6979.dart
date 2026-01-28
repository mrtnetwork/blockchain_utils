// "python-ecdsa" Copyright (c) 2010 Brian Warner

// Portions written in 2005 by Peter Pearson and placed in the public domain.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/secp256k1.dart';

import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// A class that implements the RFC6979 deterministic K value generation algorithm for ECDSA.
class RFC6979 {
  /// Converts a BigInt 'num' into a bytes with a specified 'order'.
  static List<int> bigintToBytesWithPadding(BigInt x, BigInt order) {
    String hexStr = x.toRadixString(16);
    final int hexLen = hexStr.length;
    final int byteLen = (order.bitLength + 7) ~/ 8;

    if (hexLen < byteLen * 2) {
      hexStr = '0' * (byteLen * 2 - hexLen) + hexStr;
    }

    return BytesUtils.fromHexString(hexStr);
  }

  /// Converts a sequence of bits represented as a byte array to a BigInt integer.
  static BigInt bitsToBigIntWithLengthLimit(List<int> data, int qlen) {
    final BigInt x = BigInt.parse(BytesUtils.toHexString(data), radix: 16);
    final int l = data.length * 8;

    if (l > qlen) {
      return (x >> (l - qlen));
    }
    return x;
  }

  /// Converts a sequence of bits represented as a byte array to octets.
  static List<int> bitsToOctetsWithOrderPadding(List<int> data, BigInt order) {
    final BigInt z1 = bitsToBigIntWithLengthLimit(data, order.bitLength);
    BigInt z2 = z1 - order;
    if (z2 < BigInt.zero) {
      z2 = z1;
    }
    final bytes = bigintToBytesWithPadding(z2, order);
    return bytes;
  }

  /// Generates a deterministic K value for ECDSA signatures.
  ///
  /// This method implements the RFC6979 deterministic K value generation algorithm
  /// for use in ECDSA signatures. It takes various input parameters, including the
  /// curve order, secret exponent, a hash function, data, and optional extra entropy.
  ///
  /// Parameters:
  ///   - [order]: The order of the elliptic curve.
  ///   - [secexp]: The secret exponent.
  ///   - [hashFunc]: A hash function to use in the HMAC operations.
  ///   - [data]: Additional data for K generation.
  ///   - [retryGn]: The number of retries allowed in case of invalid K values.
  ///   - [extraEntropy]: Optional extra entropy for K generation.
  static BigInt generateK({
    required BigInt order,
    required BigInt secexp,
    required HashFunc hashFunc,
    required List<int> data,
    int retryGn = 0,
    List<int>? extraEntropy,
  }) {
    final int qlen = order.bitLength;
    final hx = hashFunc();
    final int holen = hx.getDigestLength;
    final int rolen = (qlen + 7) ~/ 8;

    final List<List<int>> bx = [
      BigintUtils.toBytes(secexp, length: BigintUtils.bitlengthInBytes(order)),
      bitsToOctetsWithOrderPadding(data, order),
      extraEntropy ?? [],
    ];

    List<int> v = List<int>.filled(holen, 0);
    v.fillRange(0, holen, 0x01);

    List<int> k = List<int>.filled(holen, 0);

    HMAC hmac = HMAC(hashFunc, k);

    hmac.update([...v, 0x00]);

    for (final i in bx) {
      hmac.update(i);
    }
    k = hmac.digest();

    hmac.clean();
    hmac = HMAC(hashFunc, k);
    hmac.update(v);
    v = hmac.digest();

    hmac.clean();
    hmac = HMAC(hashFunc, k);
    hmac.update([...v, 0x01]);

    for (final i in bx) {
      hmac.update(i);
    }
    k = hmac.digest();

    // Step G
    v = HMAC.hmac(hashFunc, k, v);

    // Step H
    while (true) {
      // Step H1
      List<int> t = List.empty();

      // Step H2
      while (t.length < rolen) {
        v = HMAC.hmac(hashFunc, k, v);
        t = [...t, ...v];
      }

      // Step H3
      final BigInt secret = bitsToBigIntWithLengthLimit(t, qlen);

      if (secret >= BigInt.one && secret < order) {
        if (retryGn <= 0) {
          return secret;
        }
        retryGn -= 1;
      }

      k = HMAC.hmac(hashFunc, k, [...v, 0x00]);
      v = HMAC.hmac(hashFunc, k, v);
    }
  }

  static List<int> generateSecp256k1KBytes({
    required List<int> secexp,
    required HashFunc hashFunc,
    required List<int> data,
    int retryGn = 0,
    List<int>? extraEntropy,
  }) {
    final order = Curves.generatorSecp256k1.order!;
    final int qlen = order.bitLength;
    final hx = hashFunc();
    final int holen = hx.getDigestLength;
    final int rolen = (qlen + 7) ~/ 8;

    final List<List<int>> bx = [
      secexp,
      bitsToOctetsWithOrderPadding(data, order),
      extraEntropy ?? [],
    ];

    List<int> v = List<int>.filled(holen, 0x01);
    // v.fillRange(0, holen, 0x01);

    List<int> k = List<int>.filled(holen, 0);

    HMAC hmac = HMAC(hashFunc, k);

    hmac.update([...v, 0x00]);

    for (final i in bx) {
      hmac.update(i);
    }
    k = hmac.digest();

    hmac.clean();
    hmac = HMAC(hashFunc, k);
    hmac.update(v);
    v = hmac.digest();

    hmac.clean();
    hmac = HMAC(hashFunc, k);
    hmac.update([...v, 0x01]);

    for (final i in bx) {
      hmac.update(i);
    }
    k = hmac.digest();

    // Step G
    v = HMAC.hmac(hashFunc, k, v);

    // Step H
    while (true) {
      // Step H1
      List<int> t = [];

      // Step H2
      while (t.length < rolen) {
        v = HMAC.hmac(hashFunc, k, v);
        t = [...t, ...v];
      }

      // Step H3
      Secp256k1Scalar sc = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarSetB32(sc, t);

      if (Secp256k1.secp256k1ScalarCheckOverflow(sc) == 0) {
        if (retryGn <= 0) {
          return t;
        }
        retryGn -= 1;
      }

      k = HMAC.hmac(hashFunc, k, [...v, 0x00]);
      v = HMAC.hmac(hashFunc, k, v);
    }
  }
}

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

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';

/// A class that implements the RFC6979 deterministic K value generation algorithm for ECDSA.
class RFC6979 {
  /// Generates a deterministic K value for ECDSA signatures.
  ///
  /// This method implements the RFC6979 deterministic K value generation algorithm
  /// for use in ECDSA signatures. It takes various input parameters, including the
  /// curve order, secret exponent, a hash function, data, and optional extra entropy.
  ///
  /// Parameters:
  ///   - order: The order of the elliptic curve.
  ///   - secexp: The secret exponent.
  ///   - hashFunc: A hash function to use in the HMAC operations.
  ///   - data: Additional data for K generation.
  ///   - retryGn: The number of retries allowed in case of invalid K values.
  ///   - extraEntropy: Optional extra entropy for K generation.
  ///
  /// Returns:
  ///   - BigInt: The generated deterministic K value.
  ///
  /// Details:
  ///   - This method follows the RFC6979 algorithm for deterministic K value generation
  ///     in ECDSA signatures. It utilizes the provided parameters to create a secure
  ///     and deterministic K value suitable for ECDSA signature operations.
  ///   - The optional 'extraEntropy' parameter allows you to introduce additional
  ///     entropy for improved security if needed.
  ///   - The method handles the entire K generation process according to the RFC6979
  ///     specifications and returns the generated K value.
  ///
  /// Note: The RFC6979 algorithm ensures that K values are generated deterministically
  ///       and securely, which is essential for cryptographic operations.
  static BigInt generateK(
      BigInt order, BigInt secexp, HashFunc hashFunc, List<int> data,
      {int retryGn = 0, List<int>? extraEntropy}) {
    final int qlen = order.bitLength;
    final hx = hashFunc();
    final int holen = hx.getDigestLength;
    final int rolen = (qlen + 7) ~/ 8;

    final List<List<int>> bx = [
      BigintUtils.toBytes(secexp, length: BigintUtils.orderLen(order)),
      BigintUtils.bitsToOctetsWithOrderPadding(data, order),
      extraEntropy ?? List.empty(),
    ];

    List<int> v = List<int>.filled(holen, 0);
    v.fillRange(0, holen, 0x01);

    List<int> k = List<int>.filled(holen, 0);

    HMAC hmac = HMAC(hashFunc, k);

    hmac.update(List<int>.from([...v, 0x00]));

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
    hmac.update(List<int>.from([...v, 0x01]));

    for (final i in bx) {
      hmac.update(i);
    }
    k = hmac.digest();

    // Step G
    v = HMAC(hashFunc, k).update(v).digest();

    // Step H
    while (true) {
      // Step H1
      List<int> t = List.empty();

      // Step H2
      while (t.length < rolen) {
        v = HMAC(hashFunc, k).update(v).digest();
        t = List<int>.from([...t, ...v]);
      }

      // Step H3
      final BigInt secret = BigintUtils.bitsToBigIntWithLengthLimit(t, qlen);

      if (secret >= BigInt.one && secret < order) {
        if (retryGn <= 0) {
          return secret;
        }
        retryGn -= 1;
      }

      k = HMAC(hashFunc, k).update(List<int>.from([...v, 0x00])).digest();
      v = HMAC(hashFunc, k).update(v).digest();
    }
  }
}

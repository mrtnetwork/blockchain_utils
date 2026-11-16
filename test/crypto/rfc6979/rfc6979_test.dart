// Test vectors sourced from python-ecdsa's `test_SECP256k1_5`/`test_SECP256k1_6`
// (src/ecdsa/test_pyecdsa.py) for the bytes-based k generators on
// secp256k1 — this file is a port of that library's rfc6979.py, so these
// exercise the exact same algorithm/hash choices.
//
// ASSUMPTION: `SHA256.new` is used as the `CbHashFunc` tear-off (per-call
// hash instance) and `SHA256.hash(bytes)` as the one-shot digest helper,
// mirroring how `SHA512.hash(...)` is used elsewhere in this codebase
// (e.g. SchnorrkelMiniSecretKey._expandEd25519). Adjust if hash.dart's
// actual API differs.

import 'dart:convert';

import 'package:blockchain_utils/crypto/crypto/signature/rfc6979/rfc6979.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

List<int> _b(String hex) => BytesUtils.fromHexString(hex);

void rfc6979Test() {
  group('RFC6979.generateKBytes (bytes, secp256k1)', () {
    test(
      'secexp = order-1, message="Satoshi Nakamoto" — python-ecdsa test_SECP256k1_5',
      () {
        final secexp = _b(
          'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140',
        );
        final data = SHA256.hash(utf8.encode('Satoshi Nakamoto'));

        final k = RFC6979.generateSecp256k1KBytes(
          secexp: secexp,
          hashFunc: SHA256.new,
          data: data,
        );

        expect(
          k,
          _b(
            '33A19B60E25FB6F4435AF53A3D42D493644827367E6453928554F43E49AA6F90',
          ),
        );
      },
    );

    test(
      'secexp fixed, message="Alan Turing" — python-ecdsa test_SECP256k1_6',
      () {
        final secexp = _b(
          'F8B8AF8CE3C7CCA5E300D33939540C10D45CE001B8F252BFBC57BA0342904181',
        );
        final data = SHA256.hash(utf8.encode('Alan Turing'));

        final k = RFC6979.generateSecp256k1KBytes(
          // order: order,
          secexp: secexp,
          hashFunc: SHA256.new,
          data: data,
        );

        expect(
          k,
          _b(
            '525A82B70E67874398067543FD84C83D30C175FDC45FDEEE082FE13B1D7CFDF1',
          ),
        );
      },
    );

    test('retryGn=1 and retryGn=15 skip ahead to later candidates', () {
      // Cross-checks that retryGn actually advances the "try-try-again"
      // loop rather than being ignored — using the same key/message as
      // above with retryGn=0 as the baseline.
      final secexp = _b(
        'F8B8AF8CE3C7CCA5E300D33939540C10D45CE001B8F252BFBC57BA0342904181',
      );
      final data = SHA256.hash(utf8.encode('Alan Turing'));

      final k0 = RFC6979.generateSecp256k1KBytes(
        // order: order,
        secexp: secexp,
        hashFunc: SHA256.new,
        data: data,
      );
      final k1 = RFC6979.generateSecp256k1KBytes(
        // order: order,
        secexp: secexp,
        hashFunc: SHA256.new,
        data: data,
        retryGn: 1,
      );

      expect(k0, isNot(equals(k1)));
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(rfc6979Test, "Rfc6979");
}

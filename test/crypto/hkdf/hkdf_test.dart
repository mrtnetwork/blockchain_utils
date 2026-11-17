import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/hkdf/hkdf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:test/test.dart';

import '../../utils.dart';

/// RFC 5869 Appendix A vectors.
final _case1 = {
  "ikm": List<int>.filled(22, 0x0b),
  "salt": List<int>.generate(13, (i) => i),
  "info": List<int>.generate(10, (i) => 0xf0 + i),
  "length": 42,
  "okm":
      "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865",
};
final _case2 = {
  "ikm": List<int>.generate(80, (i) => i),
  "salt": List<int>.generate(80, (i) => 0x60 + i),
  "info": List<int>.generate(80, (i) => 0xb0 + i),
  "length": 82,
  "okm":
      "b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87",
};
final _case3 = {
  "ikm": List<int>.filled(22, 0x0b),
  "salt": null,
  "info": <int>[],
  "length": 42,
  "okm":
      "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8",
};

void hkdfTest() {
  group("HKDF RFC 5869 (SHA-256, backend-routed)", () {
    for (final entry
        in {
          "case1": _case1,
          "case2_long": _case2,
          "case3_empty_salt_info": _case3,
        }.entries) {
      test("RFC vector ${entry.key} via QuickCrypto", () {
        final v = entry.value;
        final okm = QuickCrypto.hkdfDeriveSha256(
          ikm: v["ikm"] as List<int>,
          length: v["length"] as int,
          salt: v["salt"] as List<int>?,
          info: v["info"] as List<int>,
        );
        expect(okm.toHex(), v["okm"]);
      });
    }

    test("HKDF.rfc + deriveRfc matches QuickCrypto path", () {
      final v = _case1;
      final hkdf = HKDF.rfc(
        ikm: v["ikm"] as List<int>,
        hash: QuickCrypto.sha256Instance,
        length: v["length"] as int,
        salt: v["salt"] as List<int>?,
        info: v["info"] as List<int>,
      );
      try {
        expect(hkdf.deriveRfc().toHex(), v["okm"]);
        // Legacy surface agrees when no call-time info is used.
        expect(hkdf.derive().toHex(), v["okm"]);
      } finally {
        hkdf.clean();
      }
    });

    test("length guards fail loudly", () {
      expect(
        () => QuickCrypto.hkdfDeriveSha256(ikm: [1, 2, 3], length: 0),
        throwsA(anything),
      );
      expect(
        () =>
            QuickCrypto.hkdfDeriveSha256(ikm: [1, 2, 3], length: 255 * 32 + 1),
        throwsA(anything),
      );
      expect(
        () => ValidatedKeyDerivationApi(
          blockchainUtils.api.keyDerivation,
        ).hkdfSha256DeriveKey(ikm: [1], length: 0),
        throwsA(anything),
      );
    });
  });

  group("HKDF SHA-512 (backend-routed)", () {
    test("deterministic, salt-sensitive, cross-checked shape", () {
      final ikm = List<int>.filled(22, 0x0b);
      final salt = List<int>.generate(13, (i) => i);
      final info = List<int>.generate(10, (i) => 0xf0 + i);
      final a = QuickCrypto.hkdfDeriveSha512(
        ikm: ikm,
        length: 64,
        salt: salt,
        info: info,
      );
      final b = QuickCrypto.hkdfDeriveSha512(
        ikm: ikm,
        length: 64,
        salt: salt,
        info: info,
      );
      expect(a.length, 64);
      expect(a.toHex(), b.toHex());
      final noSalt = QuickCrypto.hkdfDeriveSha512(
        ikm: ikm,
        length: 64,
        info: info,
      );
      // 64 zero default salt differs from the 13-byte salt above.
      expect(noSalt.toHex(), isNot(equals(a.toHex())));
      // SHA-512 output differs from SHA-256 output for the same inputs.
      final sha256 = QuickCrypto.hkdfDeriveSha256(
        ikm: ikm,
        length: 64,
        salt: salt,
        info: info,
      );
      expect(a.toHex(), isNot(equals(sha256.toHex())));
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(hkdfTest, "HKDF RFC 5869");
}

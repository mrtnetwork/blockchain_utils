import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/sr25519.dart';
import 'package:test/test.dart';

import 'derive_test_vector.dart';
import 'derive_public_vector.dart';

import '../../utils.dart';

void deriveTest() {
  test("shnorrkel public derive", () {
    final vector = derivePublicTestVector.shuffleTake();
    for (final i in vector) {
      SR25519PublicKey publicKey = SR25519PublicKey.fromBytes(
        BytesUtils.fromHexString(i["public_key"]),
      );
      final child = List.from(i["child"]);
      for (int c = 0; c < child.length; c++) {
        final chainCode = BytesUtils.fromHexString(child[c]["chain_code"]);
        publicKey = publicKey.derive(chainCode).$1;
        expect(publicKey.toBytes().toHex(), child[c]["public_key"]);
      }
    }
  });

  test("schnorrkel derive", () {
    final vector = testVector.shuffleTake();
    for (final i in vector) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final miniSecret = SchnorrkelMiniSecretKey(seed);
      SR25519PrivateKey secretKey = miniSecret.toSecretKey();
      expect(secretKey.publicKey.toBytes().toHex(), i["public_key"]);
      expect(secretKey.toBytes().toHex(), i["private_key"]);
      final child = List.from(i["child"]);
      for (int c = 0; c < child.length; c++) {
        final bool isHard = child[c]["is_hard"];
        final chainCode = BytesUtils.fromHexString(child[c]["chain_code"]);
        if (isHard) {
          final deriveHard = secretKey.hardDerive(chainCode);
          secretKey = deriveHard.$1;
        } else {
          final deriveSoft = secretKey.softDerive(chainCode);
          secretKey = deriveSoft.$1;
        }
        expect(secretKey.publicKey.toBytes().toHex(), child[c]["public_key"]);
        if (isHard) {
          expect(secretKey.toBytes().toHex(), child[c]["private_key"]);
        } else {
          final keyBytes = SR25519PrivateKey.fromBytes(
            BytesUtils.fromHexString(child[c]["private_key"]),
          );
          expect(secretKey.key().toHex(), keyBytes.key().toHex());
        }
      }
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(deriveTest, "Derive");
}

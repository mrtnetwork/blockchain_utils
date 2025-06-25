import 'package:blockchain_utils/crypto/crypto/x25519/x25519.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  group("X25519", () {
    test("generate keypair", () {
      for (final i in testVector) {
        final seed = BytesUtils.fromHexString(i["seed"]);
        final key = X25519Keypair.generate(seed: seed);
        expect(key.privateKeyHex(), i["privateKey"]);
        expect(key.publicKeyHex(), i["publicKey"]);
      }
    });
    test("generate shared key", () {
      for (final i in sharedTestVector) {
        final seed = BytesUtils.fromHexString(i["seed"]);
        final key = X25519Keypair.generate(seed: seed);
        expect(key.privateKeyHex(), i["privateKey"]);
        expect(key.publicKeyHex(), i["publicKey"]);
        final publicKey2 = BytesUtils.fromHexString(i["publicKey2"]);
        final mult = BytesUtils.toHexString(
            X25519.scalarMult(key.privateKey, publicKey2));
        expect(mult, i["sharedKey"]);
      }
    });
  });
}

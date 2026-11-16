import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'test_vector.dart';
import '../../../utils.dart';

void suiTest() {
  test("sui secp256k1 address", () {
    for (final i in secp256k1.shuffleTake()) {
      final publicKey = BytesUtils.fromHexString(i["publickKey"]);
      final address = SuiSecp256k1AddrEncoder().encodeKey(publicKey);
      expect(address, i["address"]);
    }
  });
  test("sui secp256r1 address", () {
    for (final i in secp256r1.shuffleTake()) {
      final publicKey = BytesUtils.fromHexString(i["publickKey"]);
      final address = SuiSecp256r1AddrEncoder().encodeKey(publicKey);
      expect(address, i["address"]);
    }
  });
  test("sui ed25519 address", () {
    for (final i in ed25519.shuffleTake()) {
      final publicKey = BytesUtils.fromHexString(i["publickKey"]);
      final address = SuiAddrEncoder().encodeKey(publicKey);
      expect(address, i["address"]);
    }
  });
  test("sui multisig address", () {
    for (final i in multisig.shuffleTake()) {
      final publicKey =
          (i["publicKeys"] as List).map((e) {
            final IPublicKey key = switch (e["type"]) {
              "secp256r1" => Secp256r1PublicKey.fromBytes(
                BytesUtils.fromHexString(e["key"]),
              ),
              "secp256k1" => Secp256k1PublicKey.fromBytes(
                BytesUtils.fromHexString(e["key"]),
              ),
              "Ed25519" => ED25519PublicKey.fromBytes(
                BytesUtils.fromHexString(e["key"]),
              ),
              _ => throw UnimplementedError(),
            };
            return SuiPublicKeyAndWeight(publicKey: key, weight: e["weight"]);
          }).toList();
      final address = SuiAddrEncoder().encodeMultisigKey(
        pubKey: publicKey,
        threshold: i["threshold"],
      );
      expect(address, i["address"]);
    }
  });

  test("invalid multisig keys", () {
    final key1 = _generateRandomKey(CryptoKeyType.ed25519);
    final key2 = _generateRandomKey(CryptoKeyType.secp256k1);
    final key3 = _generateRandomKey(CryptoKeyType.ed25519Monero);
    expect(
      () => SuiAddrEncoder().encodeMultisigKey(
        pubKey: [
          SuiPublicKeyAndWeight(publicKey: key1, weight: 1),
          SuiPublicKeyAndWeight(publicKey: key2, weight: 2),
        ],
        threshold: 5,
      ),
      throwsA(isA<BuError>()),
    );
    expect(
      () => SuiAddrEncoder().encodeMultisigKey(
        pubKey: [
          SuiPublicKeyAndWeight(publicKey: key1, weight: -1),
          SuiPublicKeyAndWeight(publicKey: key2, weight: 1),
          SuiPublicKeyAndWeight(publicKey: key3, weight: 1),
        ],
        threshold: 5,
      ),
      throwsA(isA<BuError>()),
    );
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(suiTest, "Sui");
}

IPublicKey _generateRandomKey(CryptoKeyType type) {
  // Bounded retries: a persistently-throwing backend (e.g. an unexported
  // WASM op) must surface as a test failure, never an infinite hang.
  for (var i = 0; i < 1000; i++) {
    try {
      return IPrivateKey.fromBytes(
        QuickCrypto.generateRandom(length: 32),
        type,
      ).publicKey;
    } catch (_) {}
  }
  throw StateError('Could not generate $type key after 1000 tries.');
}

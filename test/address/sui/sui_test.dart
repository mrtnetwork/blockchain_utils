import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("sui secp256k1 address", () {
    for (final i in secp256k1) {
      final publicKey = BytesUtils.fromHexString(i["publickKey"]);
      final address = SuiSecp256k1AddrEncoder().encodeKey(publicKey);
      expect(address, i["address"]);
    }
  });
  test("sui secp256r1 address", () {
    for (final i in secp256r1) {
      final publicKey = BytesUtils.fromHexString(i["publickKey"]);
      final address = SuiSecp256r1AddrEncoder().encodeKey(publicKey);
      expect(address, i["address"]);
    }
  });
  test("sui ed25519 address", () {
    for (final i in ed25519) {
      final publicKey = BytesUtils.fromHexString(i["publickKey"]);
      final address = SuiAddrEncoder().encodeKey(publicKey);
      expect(address, i["address"]);
    }
  });
  test("sui multisig address", () {
    for (final i in multisig) {
      final publicKey = (i["publicKeys"] as List).map((e) {
        final IPublicKey key = switch (e["type"]) {
          "secp256r1" =>
            Nist256p1PublicKey.fromBytes(BytesUtils.fromHexString(e["key"])),
          "secp256k1" => Secp256k1PublicKeyEcdsa.fromBytes(
              BytesUtils.fromHexString(e["key"])),
          "Ed25519" =>
            Ed25519PublicKey.fromBytes(BytesUtils.fromHexString(e["key"])),
          _ => throw UnimplementedError()
        };
        return SuiPublicKeyAndWeight(publicKey: key, weight: e["weight"]);
      }).toList();
      final address = SuiAddrEncoder()
          .encodeMultisigKey(pubKey: publicKey, threshold: i["threshold"]);
      expect(address, i["address"]);
    }
  });

  test("invalid multisig keys", () {
    final key1 = _generateRandomKey(EllipticCurveTypes.ed25519);
    final key2 = _generateRandomKey(EllipticCurveTypes.secp256k1);
    final key3 = _generateRandomKey(EllipticCurveTypes.ed25519Monero);
    expect(
        () => SuiAddrEncoder().encodeMultisigKey(pubKey: [
              SuiPublicKeyAndWeight(publicKey: key1, weight: 1),
              SuiPublicKeyAndWeight(publicKey: key2, weight: 2),
            ], threshold: 5),
        throwsA(TypeMatcher<AddressConverterException>()));
    expect(
        () => SuiAddrEncoder().encodeMultisigKey(pubKey: [
              SuiPublicKeyAndWeight(publicKey: key1, weight: -1),
              SuiPublicKeyAndWeight(publicKey: key2, weight: 1),
              SuiPublicKeyAndWeight(publicKey: key3, weight: 1),
            ], threshold: 5),
        throwsA(TypeMatcher<AddressConverterException>()));
  });
}

IPublicKey _generateRandomKey(EllipticCurveTypes type) {
  while (true) {
    try {
      return IPrivateKey.fromBytes(QuickCrypto.generateRandom(32), type)
          .publicKey;
    } catch (_) {}
  }
}

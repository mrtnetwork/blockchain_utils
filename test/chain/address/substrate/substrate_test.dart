import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void substrateSubstrateTest() {
  test("substrate ED25519 test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = SubstrateEd25519AddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        ss58Format: params["ss58_format"],
      );
      expect(z, i["address"]);
      final decode = SubstrateEd25519AddrDecoder().decodeAddr(
        z,
        ss58Format: params["ss58_format"],
      );
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("substrate sr25519 test", () {
    // NOTE: this test must NOT reuse the ed25519 `testVector` above —
    // ed25519 public keys are not valid Ristretto encodings, so strict
    // sr25519 key validation correctly rejects them. These are real
    // sr25519 vectors: the Alice dev address (Substrate docs/tutorials)
    // plus `subkey inspect` outputs (scheme default = sr25519).
    for (final v in _sr25519Vectors) {
      final z = SubstrateGenericAddrEncoder().encodeKey(
        BytesUtils.fromHexString(v.$1),
        ss58Format: 42,
        type: CryptoKeyType.sr25519,
      );
      expect(z, v.$2);
      final decode = SubstrateGenericAddrDecoder().decodeAddr(
        z,
        ss58Format: 42,
      );
      expect(decode.toHex(), v.$1.substring(2));
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(substrateSubstrateTest, "Substrate");
}

/// Real sr25519 (pubkey-hex, ss58-42 address) vectors — see test note above.
const List<(String, String)> _sr25519Vectors = [
  (
    '0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d',
    '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY',
  ),
  (
    '0x4a95b20a23190ebe5edeadbeaaf3b254b24780ba7e9afebc0e04fbdb0d26d80c',
    '5DkVsP9rBeqgAWdse9nYATDAV9RWEky2xVBppAN9bzf34GVS',
  ),
  (
    '0xac1ea46ad5376593bf482ae09ed6911512cb7d39873e48c696a882252455d843',
    '5FxPCKXqnB77D2RyVaGbUL4un6aX1eCMvDf1v3W2nYU8pRXj',
  ),
  (
    '0x169be3313d2d1061b4dca389ba6eea62d283ec02f8c985b729912e0d49db2164',
    '5CaMDeYr4KiP1dc1qZ4Q4ebtVBJ8z1SVpfi29bsgrwzBTmDs',
  ),
  (
    '0x341ff69c999f56c5e54f551c0a6a6a319b87deb53cc980ddd7420bfd51d62a36',
    '5DF3qobzyHw439qrDbVwr69QaEdNXkdcVN8hRpGJZDqhYNKb',
  ),
  (
    '0xd6a3105d6768e956e9e5d41050ac29843f98561410d3a47f9dd5b3b227ab8746',
    '5Gv8YYFu8H1btvmrJy9FjjAWfb99wrhV3uhPFoNEr918utyR',
  ),
];

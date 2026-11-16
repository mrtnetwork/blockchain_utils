import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

import '../../utils.dart';

void generateKeyAggTest() {
  _test();
}

void main() {
  BlockchainUtilsTestApi.runTest(
    generateKeyAggTest,
    "Generate Key Agg",
    onNative: _testNative,
  );
}

void _test() {
  test("MuSig2 agg public keys", () {
    final musigConst = Musig2Const();
    final List<List<int>> pubKeys =
        (keyAggTestVector["pubkeys"] as List)
            .map((e) => BytesUtils.fromHexString(e))
            .toList();
    final validateTestCase = List<Map<String, dynamic>>.from(
      keyAggTestVector["valid_test_cases"]!,
    );
    for (final i in validateTestCase) {
      final indeces = List<int>.from(i["key_indices"]);
      final keys = List.generate(indeces.length, (i) {
        return pubKeys.elementAt(indeces[i]);
      });
      MuSig2KeyAggContext key = musigConst.aggPublicKeys(keys);
      String keyHex = BytesUtils.toHexString(key.xOnly(), lowerCase: false);
      expect(keyHex, i["expected"]);
    }
  });

  test("Invalid public key", () {
    final musigConst = Musig2Const();
    List<List<int>> keys = List.generate(
      2,
      (i) =>
          (Secp256k1Point.generator_ *
                  Secp256k1Fr.fromBytesUnchecked(QuickCrypto.generateRandom()))
              .toBytes(),
    );
    keys = [...keys, List<int>.filled(33, 0)..first = 0x2];
    expect(
      () => musigConst.aggPublicKeys(keys),
      throwsA(isA<BuError>()),
    );
  });
}

void _testNative(BlockchainUtilsApi api) {
  test("MuSig2 agg public keys native", () {
    final musig = api.muSig2;
    final List<List<int>> pubKeys =
        (keyAggTestVector["pubkeys"] as List)
            .map((e) => BytesUtils.fromHexString(e))
            .toList();
    final validateTestCase = List<Map<String, dynamic>>.from(
      keyAggTestVector["valid_test_cases"]!,
    );
    for (final i in validateTestCase) {
      final indeces = List<int>.from(i["key_indices"]);
      final keys = List.generate(indeces.length, (i) {
        return pubKeys.elementAt(indeces[i]);
      });
      var key = musig.aggPublicKeys(keys);
      String keyHex = BytesUtils.toHexString(key.toXOnly(), lowerCase: false);
      expect(keyHex, i["expected"]);
    }
  });
}

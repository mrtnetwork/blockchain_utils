import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'nonce_agg_test_vector.dart';

import '../../utils.dart';

void nonceAggTest() {
  _test();
}

void main() {
  BlockchainUtilsTestApi.runTest(
    nonceAggTest,
    "Nonce Agg",
    onNative: _testNative,
  );
}

void _test() {
  test("MuSig2 nonce agg", () {
    final musigConst = Musig2Const();
    final List<List<int>> pubKeys =
        (nonceAggVectors["pnonces"] as List)
            .map((e) => BytesUtils.fromHexString(e))
            .toList();
    final validateTestCase = List<Map<String, dynamic>>.from(
      nonceAggVectors["valid_test_cases"]!,
    );
    for (final i in validateTestCase.shuffleTake()) {
      final indeces = List<int>.from(i["pnonce_indices"]);
      final keys = List.generate(indeces.length, (i) {
        return pubKeys.elementAt(indeces[i]);
      });
      List<int> key = musigConst.nonceAgg(keys);
      String keyHex = BytesUtils.toHexString(key, lowerCase: false);
      expect(keyHex, i["expected"]);
    }
  });
}

void _testNative(BlockchainUtilsApi api) {
  test("MuSig2 nonce agg native", () {
    final musig = api.muSig2;
    // final musigConst = Musig2Const();
    final List<List<int>> pubKeys =
        (nonceAggVectors["pnonces"] as List)
            .map((e) => BytesUtils.fromHexString(e))
            .toList();
    final validateTestCase = List<Map<String, dynamic>>.from(
      nonceAggVectors["valid_test_cases"]!,
    );
    for (final i in validateTestCase.shuffleTake()) {
      final indeces = List<int>.from(i["pnonce_indices"]);
      final keys = List.generate(indeces.length, (i) {
        return pubKeys.elementAt(indeces[i]);
      });
      List<int> key = musig.nonceAgg(keys);
      String keyHex = BytesUtils.toHexString(key, lowerCase: false);
      keyHex = BytesUtils.toHexString(key, lowerCase: false);
      expect(keyHex, i["expected"]);
    }
  });
}

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'nonce_agg_test_vector.dart';

void main() {
  _test();
}

void _test() {
  test("nonce agg", () {
    final List<List<int>> pubKeys = (nonceAggVectors["pnonces"] as List)
        .map((e) => BytesUtils.fromHexString(e))
        .toList();
    final validateTestCase =
        List<Map<String, dynamic>>.from(nonceAggVectors["valid_test_cases"]!);
    for (final i in validateTestCase) {
      final indeces = List<int>.from(i["pnonce_indices"]);
      final keys = List.generate(indeces.length, (i) {
        return pubKeys.elementAt(indeces[i]);
      });
      final key = MuSig2.nonceAgg(keys);
      final keyHex = BytesUtils.toHexString(key, lowerCase: false);
      expect(keyHex, i["expected"]);
    }
  });
}

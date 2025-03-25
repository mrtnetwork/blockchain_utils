import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

void main() {
  _test();
}

void _test() {
  test("generate agg key", () {
    final List<List<int>> pubKeys = (keyAggTestVector["pubkeys"] as List)
        .map((e) => BytesUtils.fromHexString(e))
        .toList();
    final validateTestCase =
        List<Map<String, dynamic>>.from(keyAggTestVector["valid_test_cases"]!);
    for (final i in validateTestCase) {
      final indeces = List<int>.from(i["key_indices"]);
      final keys = List.generate(indeces.length, (i) {
        return pubKeys.elementAt(indeces[i]);
      });
      final key = MuSig2.aggPublicKeys(keys: keys);
      final keyHex = BytesUtils.toHexString(key.xOnly(), lowerCase: false);
      expect(keyHex, i["expected"]);
    }
  });
}

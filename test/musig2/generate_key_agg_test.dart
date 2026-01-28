import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

void main() {
  _test();
}

void _test() {
  test("generate agg key", () {
    final musig = MuSig2();
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
      MuSig2KeyAggContext key = musig.aggPublicKeys(keys: keys);
      String keyHex = BytesUtils.toHexString(key.xOnly(), lowerCase: false);
      expect(keyHex, i["expected"]);
      key = musigConst.aggPublicKeys(keys: keys);
      keyHex = BytesUtils.toHexString(key.xOnly(), lowerCase: false);
      expect(keyHex, i["expected"]);
    }
  });

  test("Invalid public key", () {
    final musig = MuSig2();
    final musigConst = Musig2Const();
    List<List<int>> keys = List.generate(
      2,
      (i) =>
          (Curves.generatorSecp256k1 *
                  BigintUtils.fromBytes(QuickCrypto.generateRandom()))
              .toBytes(),
    );
    keys = [...keys, List<int>.filled(33, 0)..first = 0x2];
    expect(
      () => musig.aggPublicKeys(keys: keys),
      throwsA(isA<ArgumentException>()),
    );
    expect(
      () => musigConst.aggPublicKeys(keys: keys),
      throwsA(isA<ArgumentException>()),
    );
  });
}

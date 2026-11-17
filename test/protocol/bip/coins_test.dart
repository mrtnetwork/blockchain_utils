import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void coinsTest() {
  test("Coins identifier", () {
    final coins =
        CryptoCoins.values.clone()
          ..sort((a, b) => a.identifier.compareTo(b.identifier));
    List<int> k = [];
    for (final i in coins) {
      k.add(i.identifier);
    }
    expect(coins.map((e) => e.identifier).toSet().length, coins.length);
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(coinsTest, "Coins");
}

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("Coins identifier", () {
    final coins =
        CryptoCoins.values.clone()
          ..sort((a, b) => a.identifier.compareTo(b.identifier));
    final toBytse =
        coins
            .expand((e) => StringUtils.encode("${e.coinName}/${e.identifier}"))
            .toList();
    expect(coins.map((e) => e.identifier).toSet().length, coins.length);
    expect(Crc32().quickIntDigest(toBytse), 3932866308);
  });
}

import 'package:blockchain_utils/bip/bip/bip84/bip84.dart';
import 'package:blockchain_utils/bip/bip/conf/bip84/bip84_coins.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'test_vector.dart';

void bip84Test() {
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final coin = Bip84Coins.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (i["coin"] as String).replaceAll("_", "").toLowerCase());
    final b44 = Bip84.fromSeed(seed, coin);
    final coinInex = b44.purpose.coin;
    assert(b44.privateKey.toExtended == i["master"]);
    assert(b44.publicKey.toExtended == i["master_public"]);
    assert(coinInex.privateKey.toExtended == i["coin_private"]);
    assert(coinInex.publicKey.toExtended == i["coin_public"]);
    final accounts = (i["child"] as List);
    for (int i = 0; i < accounts.length; i++) {
      final accountInfo = accounts[i];
      final account = coinInex.account(i);
      assert(account.privateKey.toExtended == accountInfo["account"]);
      assert(account.publicKey.toExtended == accountInfo["account_public"]);
      assert(account.publicKey.toAddress == accountInfo["address"]);
    }
  }
}

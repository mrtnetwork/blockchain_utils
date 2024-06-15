import 'package:blockchain_utils/bip/bip/bip44/bip44.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/monero/monero_base.dart';

import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';

void bip44Test() {
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final coin = Bip44Coins.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (i["coin"] as String).replaceAll("_", "").toLowerCase());

    final b44 = Bip44.fromSeed(seed, coin);
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
      if (coin == Bip44Coins.moneroEd25519Slip ||
          coin == Bip44Coins.moneroSecp256k1) {
        final addrClass = Monero.fromBip44PrivateKey(account.privateKey.raw);
        assert(addrClass.primaryAddress == accountInfo["address"]);
        continue;
      }
      assert(account.publicKey.toAddress == accountInfo["address"]);
    }
  }
}

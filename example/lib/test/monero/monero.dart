import 'package:blockchain_utils/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/bip/monero/monero_base.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:example/test/quick_hex.dart';
import 'test_vector.dart';

void moneroTest() {
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final coin = MoneroCoins.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (i["coin"] as String).replaceAll("_", "").toLowerCase());
    final w = Monero.fromSeed(seed, coinType: coin);
    assert(w.privateSpendKey.raw.toHex() == i["private_sky"]);
    assert(w.privateViewKey.raw.toHex() == i["private_vkey"]);
    assert(w.publicSpendKey.compressed.toHex() == i["public_sky"]);
    assert(w.publicViewKey.compressed.toHex() == i["public_vsky"]);
    assert(w.primaryAddress == i["primary_address"]);
    final paymentId = BytesUtils.fromHexString(i["payment_id"]);
    assert(w.integratedAddress(paymentId) == i["integrated_address"]);
    final addresses = List.from(i["addresses"]);
    for (final a in addresses) {
      final minorIndex = a["minor_idx"];
      final majorIndex = a["major_idx"];
      final addr = w.subaddress(minorIndex, majorIndex: majorIndex);
      assert(a["address"] == addr);
    }
  }
}

import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/cip1852.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/bip/cardano/shelley/cardano_shelley.dart';
import 'test_vector.dart';

void cardanoShellyTest() {
  for (final i in testVector) {
    final cip =
        Cip1852.fromExtendedKey(i["private"], Cip1852Coins.cardanoLedger);
    final toShelly = CardanoShelley.fromCip1852Object(cip);
    assert(toShelly.privateKeys.addressKey.toExtended == i["account_private"]);
    assert(toShelly.publicKeys.addressKey.toExtended == i["account_public"]);
    final change = toShelly.change(Bip44Changes.chainExt);
    assert(change.privateKeys.addressKey.toExtended == i["change_private"]);
    assert(change.publicKeys.addressKey.toExtended == i["change_public"]);
    final addresses = (i["addresses"] as List);
    for (int b = 0; b < addresses.length; b++) {
      final addrIndex = change.addressIndex(b);
      final addrAddress = addrIndex.publicKeys.toAddress;
      final public = addrIndex.publicKeys.addressKey.toExtended;
      final private = addrIndex.privateKeys.addressKey.toExtended;
      assert(addresses[b]["address"] == addrAddress);
      assert(addresses[b]["public"] == public);
      assert(addresses[b]["private"] == private);
    }
  }
}

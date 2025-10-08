import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/cip1852.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/bip/cardano/shelley/cardano_shelley.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

void main() {
  test("cardano shelly", () {
    for (final i in testVector) {
      final cip =
          Cip1852.fromExtendedKey(i["private"], Cip1852Coins.cardanoLedger);
      final toShelly = CardanoShelley.fromCip1852Object(cip);
      expect(toShelly.privateKeys.addressKey.toExtended, i["account_private"]);
      expect(toShelly.publicKeys.addressKey.toExtended, i["account_public"]);
      final change = toShelly.change(Bip44Changes.chainExt);
      expect(change.privateKeys.addressKey.toExtended, i["change_private"]);
      expect(change.publicKeys.addressKey.toExtended, i["change_public"]);
      final addresses = (i["addresses"] as List);
      for (int b = 0; b < addresses.length; b++) {
        final addrIndex = change.addressIndex(b);
        final addrAddress = addrIndex.publicKeys.toAddress;
        final public = addrIndex.publicKeys.addressKey.toExtended;
        final private = addrIndex.privateKeys.addressKey.toExtended;
        expect(addresses[b]["address"], addrAddress);
        expect(addresses[b]["public"], public);
        expect(addresses[b]["private"], private);
      }
    }
  });
}

import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/cip1852.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/bip/cardano/shelley/cardano_shelley.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

void main() {
  test("cip1852", () {
    for (final i in testVector) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final cip = Cip1852.fromSeed(seed, Cip1852Coins.cardanoIcarus);
      final public = cip.publicKey.toExtended;
      final private = cip.privateKey.toExtended;
      expect(public, i["public"]);
      expect(private, i["private"]);
      final coin = cip.purpose.coin;
      expect(coin.publicKey.toExtended, i["coin_public"]);
      expect(coin.privateKey.toExtended, i["coin_private"]);
      final account = coin.account(0);
      expect(account.publicKey.toExtended, i["account_public"]);
      expect(account.privateKey.toExtended, i["account_private"]);
      final toCardanoShelly = CardanoShelley.fromCip1852Object(account);
      expect(toCardanoShelly.stakingKey.publicKey.toAddress, i["stacking"]);
      final addresses = List<String>.from(i["addresses"]);
      final change = toCardanoShelly.change(Bip44Changes.chainExt);
      for (int i = 0; i < addresses.length; i++) {
        final addr = change.addressIndex(i).publicKeys.toAddress;
        expect(addr, addresses[i]);
      }
    }
  });
}

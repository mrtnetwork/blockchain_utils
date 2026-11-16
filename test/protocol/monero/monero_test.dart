import 'package:blockchain_utils/protocol/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/protocol/bip/monero/monero_base.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void moneroTest() {
  test("monero account", () {
    final vector = testVector.shuffleTake();
    for (final i in vector) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final coin = MoneroCoins.values.firstWhere(
        (element) =>
            element.name.toLowerCase() ==
            (i["coin"] as String).replaceAll("_", "").toLowerCase(),
      );
      final w = MoneroAccount.fromSeed(seed, coinType: coin);
      expect(w.privateSpendKey.toBytes().toHex(), i["private_sky"]);
      expect(w.privateViewKey.toBytes().toHex(), i["private_vkey"]);
      expect(w.publicSpendKey.toBytes().toHex(), i["public_sky"]);
      expect(w.publicViewKey.toBytes().toHex(), i["public_vsky"]);
      expect(w.primaryAddress, i["primary_address"]);
      final paymentId = BytesUtils.fromHexString(i["payment_id"]);
      expect(w.integratedAddress(paymentId), i["integrated_address"]);
      final addresses = List.from(i["addresses"]);
      for (final a in addresses) {
        final minorIndex = a["minor_idx"];
        final majorIndex = a["major_idx"];
        final addr = w.subaddress(minorIndex, majorIndex: majorIndex);
        expect(a["address"], addr);
      }
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(moneroTest, "Monero");
}

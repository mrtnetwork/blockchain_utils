import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/electrum/electrum_v1.dart';
import 'package:blockchain_utils/bip/wif/wif.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vectors.dart';

void electrumV1Test() {
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final elc = ElectrumV1.fromSeed(seed);
    final prv = WifEncoder.encode(elc.privateKey!.raw,
        netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
        pubKeyMode: PubKeyModes.uncompressed);
    assert(prv == i["private"]);

    final public = elc.publicKey.uncompressed.toHex();
    assert(public == i["public"]);
    for (final c in (i["child"] as List)) {
      final changeIndex = c["change_index"];
      final addressIndex = c["address_index"];
      final cPrv = WifEncoder.encode(
          elc.getPrivateKey(changeIndex, addressIndex).raw,
          netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
          pubKeyMode: PubKeyModes.uncompressed);
      assert(cPrv == c["private"]);
      final cPub =
          elc.getPublicKey(changeIndex, addressIndex).uncompressed.toHex();
      assert(cPub == c["public"]);
      final cAddress = elc.getAddress(changeIndex, addressIndex);
      assert(cAddress == c["address"]);
    }
  }
}

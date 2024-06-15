import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/electrum/electrum_v2.dart';
import 'package:blockchain_utils/bip/wif/wif.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';
import 'segwit_test_vector.dart';

void electrumV2Test() {
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final elc = ElectrumV2Standard.fromSeed(seed);
    final prv = WifEncoder.encode(
      elc.masterPrivateKey.raw,
      netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
    );
    assert(prv == i["private"]);

    final public = elc.masterPublicKey.uncompressed.toHex();
    assert(public == i["public"]);
    for (final c in (i["child"] as List)) {
      final changeIndex = c["change_index"];
      final addressIndex = c["address_index"];
      final cPrv = WifEncoder.encode(
        elc.getPrivateKey(changeIndex, addressIndex).raw,
        netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
      );
      assert(cPrv == c["private"]);
      final cPub =
          elc.getPublicKey(changeIndex, addressIndex).uncompressed.toHex();
      assert(cPub == c["public"]);
      final cAddress = elc.getAddress(changeIndex, addressIndex);
      assert(cAddress == c["address"]);
    }
  }
  for (final i in segwitTestVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final elc = ElectrumV2Segwit.fromSeed(seed);
    final prv = WifEncoder.encode(
      elc.masterPrivateKey.raw,
      netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
    );
    assert(prv == i["private"]);

    final public = elc.masterPublicKey.uncompressed.toHex();
    assert(public == i["public"]);
    for (final c in (i["child"] as List)) {
      final changeIndex = c["change_index"];
      final addressIndex = c["address_index"];
      final cPrv = WifEncoder.encode(
        elc.getPrivateKey(changeIndex, addressIndex).raw,
        netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
      );
      assert(cPrv == c["private"]);
      final cPub =
          elc.getPublicKey(changeIndex, addressIndex).uncompressed.toHex();
      assert(cPub == c["public"]);
      final cAddress = elc.getAddress(changeIndex, addressIndex);
      assert(cAddress == c["address"]);
    }
  }
}

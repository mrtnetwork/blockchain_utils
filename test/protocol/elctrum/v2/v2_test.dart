import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/protocol/bip/electrum/electrum_v2.dart';
import 'package:blockchain_utils/protocol/wif/wif.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';
import 'segwit_test_vector.dart';

import '../../../utils.dart';

void v2Test() {
  test("test legacy", () {
    for (final i in testVector.shuffleTake()) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final elc = ElectrumV2Standard.fromSeed(seed);
      final prv = WifEncoder.encode(
        elc.masterPrivateKey.toBytes(),
        netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
      );
      expect(prv, i["private"]);

      final public =
          elc.masterPublicKey
              .toPublicKeyBytes(mode: CryptoKeyEncoding.uncompressed)
              .toHex();
      expect(public, i["public"]);
      for (final c in (i["child"] as List)) {
        final changeIndex = c["change_index"];
        final addressIndex = c["address_index"];
        final cPrv = WifEncoder.encode(
          elc.getPrivateKey(changeIndex, addressIndex).toBytes(),
          netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
        );
        expect(cPrv, c["private"]);
        final cPub =
            elc
                .getPublicKey(changeIndex, addressIndex)
                .toPublicKeyBytes(mode: CryptoKeyEncoding.uncompressed)
                .toHex();
        expect(cPub, c["public"]);
        final cAddress = elc.getAddress(changeIndex, addressIndex);
        expect(cAddress, c["address"]);
      }
    }
  });
  test("segwit", () {
    for (final i in segwitTestVector.shuffleTake()) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final elc = ElectrumV2Segwit.fromSeed(seed);
      final prv = WifEncoder.encode(
        elc.masterPrivateKey.toBytes(),
        netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
      );
      expect(prv, i["private"]);

      final public =
          elc.masterPublicKey
              .toPublicKeyBytes(mode: CryptoKeyEncoding.uncompressed)
              .toHex();
      expect(public, i["public"]);
      for (final c in (i["child"] as List)) {
        final changeIndex = c["change_index"];
        final addressIndex = c["address_index"];
        final cPrv = WifEncoder.encode(
          elc.getPrivateKey(changeIndex, addressIndex).toBytes(),
          netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
        );
        expect(cPrv, c["private"]);
        final cPub =
            elc
                .getPublicKey(changeIndex, addressIndex)
                .toPublicKeyBytes(mode: CryptoKeyEncoding.uncompressed)
                .toHex();
        expect(cPub, c["public"]);
        final cAddress = elc.getAddress(changeIndex, addressIndex);
        expect(cAddress, c["address"]);
      }
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(v2Test, "V2");
}

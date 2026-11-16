import 'package:test/test.dart';

import 'test_vectors.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../../../utils.dart';

void v1Test() {
  test("electrum v1", () {
    for (final i in testVector.shuffleTake()) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final elc = ElectrumV1.fromSeed(seed);
      final prv = WifEncoder.encode(
        elc.privateKey!.toBytes(),
        netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
        pubKeyMode: CryptoKeyEncoding.uncompressed,
      );
      expect(prv, i["private"]);

      final public =
          elc.publicKey.toBytes(mode: CryptoKeyEncoding.uncompressed).toHex();
      expect(public, i["public"]);
      for (final c in (i["child"] as List)) {
        final changeIndex = c["change_index"];
        final addressIndex = c["address_index"];
        final cPrv = WifEncoder.encode(
          elc.getPrivateKey(changeIndex, addressIndex).toBytes(),
          netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
          pubKeyMode: CryptoKeyEncoding.uncompressed,
        );
        expect(cPrv, c["private"]);
        final cPub =
            elc
                .getPublicKey(changeIndex, addressIndex)
                .toBytes(mode: CryptoKeyEncoding.uncompressed)
                .toHex();
        expect(cPub, c["public"]);
        final cAddress = elc.getAddress(changeIndex, addressIndex);
        expect(cAddress, c["address"]);
      }
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(v1Test, "V1");
}

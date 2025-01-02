import 'package:test/test.dart';

import '../../quick_hex.dart';
import 'test_vectors.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

void main() {
  test("electrum v1", () {
    for (final i in testVector) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final elc = ElectrumV1.fromSeed(seed);
      final prv = WifEncoder.encode(elc.privateKey!.raw,
          netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
          pubKeyMode: PubKeyModes.uncompressed);
      expect(prv, i["private"]);

      final public = elc.publicKey.uncompressed.toHex();
      expect(public, i["public"]);
      for (final c in (i["child"] as List)) {
        final changeIndex = c["change_index"];
        final addressIndex = c["address_index"];
        final cPrv = WifEncoder.encode(
            elc.getPrivateKey(changeIndex, addressIndex).raw,
            netVer: CoinsConf.bitcoinMainNet.params.wifNetVer!,
            pubKeyMode: PubKeyModes.uncompressed);
        expect(cPrv, c["private"]);
        final cPub =
            elc.getPublicKey(changeIndex, addressIndex).uncompressed.toHex();
        expect(cPub, c["public"]);
        final cAddress = elc.getAddress(changeIndex, addressIndex);
        expect(cAddress, c["address"]);
      }
    }
  });
}

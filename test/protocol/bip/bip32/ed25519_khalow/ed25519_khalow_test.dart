import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../../utils.dart';

void ed25519KhalowTest() {
  // final g = Bip32KholawEd25519.fromSeed(QuickCrypto.generateRandom());
  // // g.derivePath("m/0/1/2");
  // // return;
  test("ed25519 khalow", () {
    for (final i in testVector.shuffleTake()) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      var w = Bip32KholawEd25519.fromSeed(seed);
      expect(w.publicKey.toExtended, i["public"]);
      expect(w.privateKey.toExtended, i["private"]);
      expect(w.chainCode.toBytes().toHex(), i["chaincode"]);
      expect(w.fingerPrint.toBytes().toHex(), i["finger_print"]);

      for (final c in (i["child"] as List)) {
        final index = Bip32KeyIndex(c["index"]);
        if (!index.isHardened) {
          Bip32KholawEd25519 key = Bip32KholawEd25519.fromPrivateKey(
            w.privateKey.toBytes(),
            keyData: w.privateKey.keyData,
          );
          key.convertToPublic();
          key = key.childKey(index);
          expect(key.publicKey.toExtended, c["public"]);
          // expect(key.privateKey.toExtended, c["private"]);
          expect(key.chainCode.toBytes().toHex(), c["chaincode"]);
          expect(key.fingerPrint.toBytes().toHex(), c["finger_print"]);
          expect(
            key.parentFingerPrint.toBytes().toHex(),
            c["parent_finger_print"],
          );
          expect(key.depth.toInt(), c["depth"]);
        }
        w = w.childKey(index);
        expect(w.publicKey.toExtended, c["public"]);
        expect(w.privateKey.toExtended, c["private"]);
        expect(w.chainCode.toBytes().toHex(), c["chaincode"]);
        expect(w.fingerPrint.toBytes().toHex(), c["finger_print"]);
        expect(w.parentFingerPrint.toBytes().toHex(), c["parent_finger_print"]);
        expect(w.depth.toInt(), c["depth"]);
      }
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(ed25519KhalowTest, "Ed25519 Khalow");
}

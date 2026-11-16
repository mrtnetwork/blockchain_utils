import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_nist256p1.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../../utils.dart';

void nist256p1Test() {
  test("nist256p1", () {
    for (final i in testVector.shuffleTake()) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      var w = Bip32Slip10Nist256p1.fromSeed(seed);
      expect(w.publicKey.toExtended, i["public"]);
      expect(w.privateKey.toExtended, i["private"]);
      expect(w.chainCode.toBytes().toHex(), i["chaincode"]);
      expect(w.fingerPrint.toBytes().toHex(), i["finger_print"]);

      for (final c in (i["child"] as List)) {
        final index = Bip32KeyIndex(c["index"]);
        if (!index.isHardened) {
          Bip32Slip10Nist256p1 w2 = Bip32Slip10Nist256p1.fromPrivateKey(
            w.privateKey.toBytes(),
            keyData: w.publicKey.keyData,
          );
          w2.convertToPublic();
          w2 = w2.childKey(index);
          expect(w2.publicKey.toExtended, c["public"]);
          expect(w2.chainCode.toBytes().toHex(), c["chaincode"]);
          expect(w2.fingerPrint.toBytes().toHex(), c["finger_print"]);
          expect(
            w2.parentFingerPrint.toBytes().toHex(),
            c["parent_finger_print"],
          );
          expect(w2.depth.toInt(), c["depth"]);
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
  BlockchainUtilsTestApi.runTest(nist256p1Test, "Nist256p1");
}

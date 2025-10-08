import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("bip32 secp256k1", () {
    for (final i in testVector) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      Bip32Slip10Secp256k1 w = Bip32Slip10Secp256k1.fromSeed(seed);
      expect(w.publicKey.toExtended, i["public"]);
      expect(w.privateKey.toExtended, i["private"]);
      expect(w.chainCode.toHex(), i["chaincode"]);
      expect(w.fingerPrint.toHex(), i["finger_print"]);

      for (final c in (i["child"] as List)) {
        final index = Bip32KeyIndex(c["index"]);
        w = w.childKey(index);

        expect(w.publicKey.toExtended, c["public"]);

        expect(w.privateKey.toExtended, c["private"]);

        expect(w.chainCode.toHex(), c["chaincode"]);
        expect(w.fingerPrint.toHex(), c["finger_print"]);
        expect(w.parentFingerPrint.toHex(), c["parent_finger_print"]);
        expect(w.depth.toInt(), c["depth"]);
      }
    }
  });
}

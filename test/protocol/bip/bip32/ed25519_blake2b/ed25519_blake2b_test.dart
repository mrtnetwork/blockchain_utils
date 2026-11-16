import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_ed25519_blake2b.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../../utils.dart';

void ed25519Blake2bTest() {
  test("bip32 ed25519 blake2b", () {
    for (final i in testVector.shuffleTake()) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      var w = Bip32Slip10Ed25519Blake2b.fromSeed(seed);
      expect(w.publicKey.toExtended, i["public"]);
      expect(w.privateKey.toExtended, i["private"]);
      expect(w.chainCode.toBytes().toHex(), i["chaincode"]);
      expect(w.fingerPrint.toBytes().toHex(), i["finger_print"]);
      for (final c in (i["child"] as List)) {
        final index = Bip32KeyIndex(c["index"]);
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
  BlockchainUtilsTestApi.runTest(ed25519Blake2bTest, "Ed25519 Blake2b");
}

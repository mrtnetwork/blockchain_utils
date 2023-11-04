import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_icarus_bip32.dart';

import 'package:blockchain_utils/binary/utils.dart';

import 'icarus_test_vector.dart';

void cardanoIcarusTest() {
  for (final i in icarusTestVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final w = CardanoIcarusBip32.fromSeed(seed);
    String public = w.publicKey.toExtended;
    assert(public == i["public"]);
    String private = w.privateKey.toExtended;
    assert(private == i["private"]);
    String chainCode = w.chainCode.toHex();
    assert(chainCode == i["chaincode"]);
    String finger = w.parentFingerPrint.toHex();
    assert(finger == i["finger_print"]);
    for (final c in (i["child"] as List)) {
      final pathIndex = Bip32KeyIndex(c["index"]);
      CardanoIcarusBip32 child = w.childKey(pathIndex);
      String public = child.publicKey.toExtended;
      assert(public == c["public"]);
      String private = child.privateKey.toExtended;
      assert(private == c["private"]);
      int index = child.index.toInt();
      assert(index == c["index"]);
      String chainCode = child.chainCode.toHex();
      assert(chainCode == c["chaincode"]);
      String finger = child.parentFingerPrint.toHex();
      assert(finger == c["finger_print"]);
      for (final c2 in (c["child"] as List)) {
        final pathIndex = Bip32KeyIndex(c2["index"]);
        child = child.childKey(pathIndex);
        String public = child.publicKey.toExtended;
        assert(public == c2["public"]);
        String private = child.privateKey.toExtended;
        assert(private == c2["private"]);
        int index = child.index.toInt();
        assert(index == c2["index"]);
        String chainCode = child.chainCode.toHex();
        assert(chainCode == c2["chaincode"]);
        String finger = child.parentFingerPrint.toHex();
        assert(finger == c2["finger_print"]);
      }
    }
  }
}

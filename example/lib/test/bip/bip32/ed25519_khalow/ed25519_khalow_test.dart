import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_ed25519.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart';

void edKhalowTest() {
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    var w = Bip32KholawEd25519.fromSeed(seed);
    assert(w.publicKey.toExtended == i["public"]);
    assert(w.privateKey.toExtended == i["private"]);
    assert(w.chainCode.toHex() == i["chaincode"]);
    assert(w.fingerPrint.toHex() == i["finger_print"]);
    for (final c in (i["child"] as List)) {
      final index = Bip32KeyIndex(c["index"]);
      w = w.childKey(index);
      assert(w.publicKey.toExtended == c["public"]);
      assert(w.privateKey.toExtended == c["private"]);
      assert(w.chainCode.toHex() == c["chaincode"]);
      assert(w.fingerPrint.toHex() == c["finger_print"]);
      assert(w.parentFingerPrint.toHex() == c["parent_finger_print"]);
      assert(w.depth.toInt() == c["depth"]);
    }
  }
}

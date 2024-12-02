import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/cardano/bip32/cardano_icarus_bip32.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'icarus_test_vector.dart';

void main() {
  test("bip32 cardano", () {
    for (final i in icarusTestVector) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final w = CardanoIcarusBip32.fromSeed(seed);
      final String public = w.publicKey.toExtended;
      expect(public, i["public"]);
      final String private = w.privateKey.toExtended;
      expect(private, i["private"]);
      final String chainCode = w.chainCode.toHex();
      expect(chainCode, i["chaincode"]);
      final String finger = w.parentFingerPrint.toHex();
      expect(finger, i["finger_print"]);
      for (final c in (i["child"] as List)) {
        final pathIndex = Bip32KeyIndex(c["index"]);
        CardanoIcarusBip32 child = w.childKey(pathIndex);
        final String public = child.publicKey.toExtended;
        expect(public, c["public"]);
        final String private = child.privateKey.toExtended;
        expect(private, c["private"]);
        final int index = child.index.toInt();
        expect(index, c["index"]);
        final String chainCode = child.chainCode.toHex();
        expect(chainCode, c["chaincode"]);
        final String finger = child.parentFingerPrint.toHex();
        expect(finger, c["finger_print"]);
        for (final c2 in (c["child"] as List)) {
          final pathIndex = Bip32KeyIndex(c2["index"]);
          child = child.childKey(pathIndex);
          final String public = child.publicKey.toExtended;
          expect(public, c2["public"]);
          final String private = child.privateKey.toExtended;
          expect(private, c2["private"]);
          final int index = child.index.toInt();
          expect(index, c2["index"]);
          final String chainCode = child.chainCode.toHex();
          expect(chainCode, c2["chaincode"]);
          final String finger = child.parentFingerPrint.toHex();
          expect(finger, c2["finger_print"]);
        }
      }
    }
  });
}

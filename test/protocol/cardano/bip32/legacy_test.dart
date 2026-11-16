import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/cardano/bip32/cardano_byron_legacy_bip32.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../utils.dart';

void legacyTest() {
  test("bip32 cardano lagacy test", () {
    final vector = testVector.shuffleTake();
    for (final i in vector) {
      final seed = BytesUtils.fromHexString(i["seed"]);
      final w = CardanoByronLegacyBip32.fromSeed(seed);
      final String public = w.publicKey.toExtended;
      expect(public, i["public"]);
      final String private = w.privateKey.toExtended;
      expect(private, i["private"]);
      final String chainCode = w.chainCode.toBytes().toHex();
      expect(chainCode, i["chaincode"]);
      final String finger = w.parentFingerPrint.toBytes().toHex();
      expect(finger, i["finger_print"]);
      for (final c in (i["child"] as List)) {
        final pathIndex = Bip32KeyIndex(c["index"]);
        CardanoByronLegacyBip32 child = w.childKey(pathIndex);
        final String public = child.publicKey.toExtended;
        expect(public, c["public"]);
        final String private = child.privateKey.toExtended;
        expect(private, c["private"]);
        final int index = child.index.toInt();
        expect(index, c["index"]);
        final String chainCode = child.chainCode.toBytes().toHex();
        expect(chainCode, c["chaincode"]);
        final String finger = child.parentFingerPrint.toBytes().toHex();
        expect(finger, c["finger_print"]);
        for (final c2 in (c["child"] as List)) {
          final pathIndex = Bip32KeyIndex(c2["index"]);
          if (!pathIndex.isHardened) {
            final key = CardanoByronLegacyBip32.fromPrivateKey(
              child.privateKey.toBytes(),
              child.privateKey.keyData,
            );
            key.convertToPublic();
            final c = key.childKey(pathIndex);
            final String public = c.publicKey.toExtended;
            expect(public, c2["public"]);
            final int index = c.index.toInt();
            expect(index, c2["index"]);
            final String chainCode = c.chainCode.toBytes().toHex();
            expect(chainCode, c2["chaincode"]);
            final String finger = c.parentFingerPrint.toBytes().toHex();
            expect(finger, c2["finger_print"]);
          }

          child = child.childKey(pathIndex);
          final String public = child.publicKey.toExtended;
          expect(public, c2["public"]);
          final String private = child.privateKey.toExtended;
          expect(private, c2["private"]);
          final int index = child.index.toInt();
          expect(index, c2["index"]);
          final String chainCode = child.chainCode.toBytes().toHex();
          expect(chainCode, c2["chaincode"]);
          final String finger = child.parentFingerPrint.toBytes().toHex();
          expect(finger, c2["finger_print"]);
        }
      }
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(legacyTest, "Legacy");
}

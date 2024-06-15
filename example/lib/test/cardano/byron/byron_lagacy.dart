import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/cardano/byron/cardano_byron_legacy.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'test_vector.dart';

void byronLegacyTest() {
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final w = CardanoByronLegacy.fromSeed(seed);
    final masterPrivate = w.masterPrivateKey.raw.toHex();
    final masterPub = w.masterPublicKey.compressed.toHex();
    final chainCode = w.masterPrivateKey.chainCode.toHex();
    final hdKey = w.hdPathKey.toHex();
    assert(masterPrivate == i["private"]);
    assert(masterPub == i["public"]);
    assert(chainCode == i["chaincode"]);
    assert(hdKey == i["hd_key"]);
    for (final c in (i["child"] as List)) {
      final firstIndex = Bip32KeyIndex(c["first_index"]);
      final secondIndex = Bip32KeyIndex(c["second_index"]);
      final cPrivate = w
          .getPrivateKey(firstIndex: firstIndex, secondIndex: secondIndex)
          .toExtended;
      assert(cPrivate == c["private"]);
      final cPublic = w
          .getPublicKey(firstIndex: firstIndex, secondIndex: secondIndex)
          .toExtended;
      assert(cPublic == c["public"]);
      final addr = w.getAddress(firstIndex, secondIndex);
      assert(addr == c["address"]);
    }

    if (testVector.indexOf(i) > 2 && kIsWeb) {
      break;
    }
  }
}

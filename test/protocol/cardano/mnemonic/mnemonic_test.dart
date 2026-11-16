import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../utils.dart';

void cardanoMnemonicMnemonicTest() {
  test("mnemonic", () {
    for (final i in testVector.shuffleTake()) {
      final Mnemonic mnemonic = Mnemonic.fromString(i["mnemonic"]);
      final legacy = CardanoByronLegacySeedGenerator(mnemonic).generate();
      final icarus = CardanoIcarusSeedGenerator(mnemonic).generate();
      expect(legacy.toHex(), i["legacy"]);
      expect(icarus.toHex(), i["icarus"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(cardanoMnemonicMnemonicTest, "Mnemonic");
}

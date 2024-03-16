import 'package:blockchain_utils/bip/cardano/mnemonic/cardano_byron_legacy_seed_generator.dart';
import 'package:blockchain_utils/bip/cardano/mnemonic/cardano_icarus_seed_generator.dart';
import 'package:example/test/quick_hex.dart';

import 'test_vector.dart';

void cardanoMnemonicTest() {
  for (final i in testVector) {
    final String mnemonic = i["mnemonic"];
    final legacy = CardanoByronLegacySeedGenerator(mnemonic).generate();
    final icarus = CardanoIcarusSeedGenerator(mnemonic).generate();
    assert(legacy.toHex() == i["legacy"]);
    assert(icarus.toHex() == i["icarus"]);
  }
}

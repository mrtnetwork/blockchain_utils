import 'package:blockchain_utils/bip/cardano/mnemonic/cardano_byron_legacy_seed_generator.dart';
import 'package:blockchain_utils/bip/cardano/mnemonic/cardano_icarus_seed_generator.dart';
import 'package:test/test.dart';
import '../../quick_hex.dart';
import 'test_vector.dart';

void main() {
  test("mnemonic", () {
    for (final i in testVector) {
      final String mnemonic = i["mnemonic"];
      final legacy = CardanoByronLegacySeedGenerator(mnemonic).generate();
      final icarus = CardanoIcarusSeedGenerator(mnemonic).generate();
      expect(legacy.toHex(), i["legacy"]);
      expect(icarus.toHex(), i["icarus"]);
    }
  });
}

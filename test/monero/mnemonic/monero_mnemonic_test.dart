import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_seed_generator.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import "test_vector.dart";

void main() {
  test("monero mnemonic", () {
    for (final i in testVector) {
      final lang = MoneroLanguages.values.firstWhere((element) =>
          element.name.toLowerCase() ==
          (i["lang"] as String).replaceAll("_", "").toLowerCase());
      final entropy = BytesUtils.fromHexString(i["entropy"]);
      final mn = MoneroMnemonicGenerator(lang).fromEntropyWithChecksum(entropy);
      expect(mn.toStr(), i["mnemonic"]);
      final mnNc = MoneroMnemonicGenerator(lang).fromEntropyNoChecksum(entropy);
      expect(mnNc.toStr(), i["no_checksum"]);
      final entropyResult = MoneroMnemonicDecoder(lang).decode(mn.toStr());
      expect(BytesUtils.bytesEqual(entropyResult, entropy), true);
      final seed = MoneroSeedGenerator(mn).generate();
      expect(BytesUtils.bytesEqual(seed, entropy), true);
    }
  });
}

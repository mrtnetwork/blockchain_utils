import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import '../../quick_hex.dart';
import "test_vector.dart";

void main() {
  test("monero mnemonic", () {
    for (final i in testVector.shuffleTake()) {
      final lang = MoneroLanguages.values.firstWhere(
        (element) =>
            element.name.toLowerCase() ==
            (i["lang"] as String).replaceAll("_", "").toLowerCase(),
      );
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

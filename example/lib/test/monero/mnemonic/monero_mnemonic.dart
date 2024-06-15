import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_seed_generator.dart';
import 'package:blockchain_utils/utils/utils.dart';
import "test_vector.dart";

void moneroMnemonucTest() {
  for (final i in testVector) {
    final lang = MoneroLanguages.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (i["lang"] as String).replaceAll("_", "").toLowerCase());
    final entropy = BytesUtils.fromHexString(i["entropy"]);
    final mn = MoneroMnemonicGenerator(lang).fromEntropyWithChecksum(entropy);
    assert(mn.toStr() == i["mnemonic"]);
    final mnNc = MoneroMnemonicGenerator(lang).fromEntropyNoChecksum(entropy);
    assert(mnNc.toStr() == i["no_checksum"]);
    final entropyResult = MoneroMnemonicDecoder(lang).decode(mn.toStr());
    assert(BytesUtils.bytesEqual(entropyResult, entropy));
    final seed = MoneroSeedGenerator(mn).generate();
    assert(BytesUtils.bytesEqual(seed, entropy));
  }
}

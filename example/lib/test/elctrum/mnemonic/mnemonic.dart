import 'package:blockchain_utils/bip/electrum/electrum_v1.dart';
import 'package:blockchain_utils/bip/electrum/electrum_v2.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_seed_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_seed_generator.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'test_vector_v1.dart';
import 'test_vector_v2.dart';

void electrumMnemonicTest() {
  for (final i in testVectorV2) {
    final type = ElectrumV2MnemonicTypes.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (i["type"] as String).replaceAll("_", "").toLowerCase());
    final lang = ElectrumV2Languages.values.firstWhere((element) =>
        element.name.toLowerCase() ==
        (i["lang"] as String).replaceAll("_", "").toLowerCase());
    final entropy = BytesUtils.fromHexString(i["entropy"]);
    final mn =
        ElectrumV2MnemonicGenerator(type, language: lang).fromEntropy(entropy);
    assert(mn.toStr() == i["mnemonic"]);
    final decode = ElectrumV2MnemonicDecoder(mnemonicType: type, language: lang)
        .decode(mn.toStr());

    assert(bytesEqual(decode, entropy));
    final seed = ElectrumV2SeedGenerator(mn, lang).generate("MRT");
    assert(bytesEqual(seed, BytesUtils.fromHexString(i["seed"])));
    if (i["address"] != null) {
      String addr;
      if (type.name.startsWith("segwit")) {
        addr = ElectrumV2Segwit.fromSeed(seed).getAddress(0, 0);
      } else {
        addr = ElectrumV2Standard.fromSeed(seed).getAddress(0, 0);
      }
      assert(addr == i["address"], "type ${type.name}");
    }
  }
  for (final i in testVectorV1) {
    final entropy = BytesUtils.fromHexString(i["entropy"]);
    final toMnemonic = ElectrumV1MnemonicGenerator().fromEntropy(entropy);
    assert(toMnemonic.toStr() == i["mnemonic"]);
    final seed = ElectrumV1SeedGenerator(toMnemonic.toStr()).generate();
    assert(seed.toHex() == i["seed"]);
    final en = ElectrumV1MnemonicDecoder().decode(toMnemonic.toStr());
    assert(bytesEqual(en, entropy));
    final addr = ElectrumV1.fromSeed(seed).getAddress(0, 0);
    assert(addr == i["address"]);
  }
}

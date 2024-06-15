import 'package:blockchain_utils/bip/electrum/electrum_v1.dart';
import 'package:blockchain_utils/bip/electrum/electrum_v2.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_seed_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_seed_generator.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import '../../quick_hex.dart';
import 'test_vector_v1.dart';
import 'test_vector_v2.dart';

void main() {
  test("electrum mnemonic v2", () {
    for (final i in testVectorV2) {
      final type = ElectrumV2MnemonicTypes.values.firstWhere((element) =>
          element.name.toLowerCase() ==
          (i["type"] as String).replaceAll("_", "").toLowerCase());
      final lang = ElectrumV2Languages.values.firstWhere((element) =>
          element.name.toLowerCase() ==
          (i["lang"] as String).replaceAll("_", "").toLowerCase());
      final entropy = BytesUtils.fromHexString(i["entropy"]);
      final mn = ElectrumV2MnemonicGenerator(type, language: lang)
          .fromEntropy(entropy);
      expect(mn.toStr(), i["mnemonic"]);
      final decode =
          ElectrumV2MnemonicDecoder(mnemonicType: type, language: lang)
              .decode(mn.toStr());
      expect(BytesUtils.bytesEqual(decode, entropy), true);
      final seed = ElectrumV2SeedGenerator(mn, lang).generate("MRT");
      expect(BytesUtils.bytesEqual(seed, BytesUtils.fromHexString(i["seed"])),
          true);
      if (i["address"] != null) {
        String addr;
        if (type.name.startsWith("segwit")) {
          addr = ElectrumV2Segwit.fromSeed(seed).getAddress(0, 0);
        } else {
          addr = ElectrumV2Standard.fromSeed(seed).getAddress(0, 0);
        }
        expect(addr, i["address"]);
      }
    }
  });
  test("electrum mnemonic v1", () {
    for (final i in testVectorV1) {
      final entropy = BytesUtils.fromHexString(i["entropy"]);
      final toMnemonic = ElectrumV1MnemonicGenerator().fromEntropy(entropy);
      expect(toMnemonic.toStr(), i["mnemonic"]);
      final seed = ElectrumV1SeedGenerator(toMnemonic.toStr()).generate();
      expect(seed.toHex(), i["seed"]);
      final en = ElectrumV1MnemonicDecoder().decode(toMnemonic.toStr());
      expect(BytesUtils.bytesEqual(en, entropy), true);
      final addr = ElectrumV1.fromSeed(seed).getAddress(0, 0);
      expect(addr, i["address"]);
    }
  });
}

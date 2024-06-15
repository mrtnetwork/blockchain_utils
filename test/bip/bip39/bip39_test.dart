import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_seed_generator.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import '../../quick_hex.dart';
import 'test_vector.dart' show testVector;

const String _passphrase = "MRT";
void main() {
  test("bip39", () {
    for (final i in testVector) {
      final lower = (i["lang"] as String).replaceAll("_", "").toLowerCase();
      final lang = Bip39Languages.values
          .firstWhere((element) => element.name.toLowerCase() == lower);
      final mn = Bip39MnemonicGenerator(lang)
          .fromEntropy(BytesUtils.fromHexString(i["entropy"]));
      expect(mn.toStr(), i["mnemonic"]);
      final decode = Bip39MnemonicDecoder(lang).decode(mn.toStr());
      expect(decode.toHex(), i["entropy"]);
      final decodeWithChecksum =
          Bip39MnemonicDecoder(lang).decodeWithChecksum(mn.toStr());
      expect(decodeWithChecksum.toHex(), i["checksum"]);
      final seed = Bip39SeedGenerator(mn).generate(_passphrase);
      expect(seed.toHex(), i["seed"]);
    }
  });
}

import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_validator.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_seed_generator.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import '../quick_hex.dart';
import 'test_vector.dart';

void main() {
  test("algorand", () {
    for (final i in testVector) {
      final mn = AlgorandMnemonicGenerator()
          .fromEntropy(BytesUtils.fromHexString(i["entropy"]));
      final valid = AlgorandMnemonicValidator().isValid(mn.toStr());
      expect(valid, true);
      final entropy = AlgorandMnemonicDecoder().decode(mn.toStr());
      expect(entropy.toHex(), i["entropy"]);
      final seed = AlgorandSeedGenerator(mn).generate();
      expect(seed.toHex(), i["entropy"]);
      final bip44 = Bip44.fromPrivateKey(seed, Bip44Coins.algorand);
      final address = bip44.publicKey.toAddress;
      expect(address, i["address"]);
    }
  });
}

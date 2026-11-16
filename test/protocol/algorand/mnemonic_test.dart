import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_mnemonic_decoder.dart';
import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_mnemonic_generator.dart';
import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_mnemonic_validator.dart';
import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_seed_generator.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/bip44_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void mnemonicTest() {
  test("algorand", () {
    for (final i in testVector.shuffleTake()) {
      final mn = AlgorandMnemonicGenerator().fromEntropy(
        BytesUtils.fromHexString(i["entropy"]),
      );
      final valid = AlgorandMnemonicValidator().isValid(mn);
      expect(valid, true);
      final entropy = AlgorandMnemonicDecoder().decode(mn);
      expect(entropy.toHex(), i["entropy"]);
      final seed = AlgorandSeedGenerator(mn).generate();
      expect(seed.toHex(), i["entropy"]);
      final bip44 = Bip44.fromPrivateKey(seed, Bip44Coins.algorand);
      final address = bip44.publicKey.toAddress;
      expect(address, i["address"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(mnemonicTest, "Mnemonic");
}

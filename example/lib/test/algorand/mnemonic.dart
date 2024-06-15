import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_generator.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_validator.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_seed_generator.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'test_vector.dart';

void algorandMnemonicAndAddressTest() {
  for (final i in testVector) {
    final mn = AlgorandMnemonicGenerator()
        .fromEntropy(BytesUtils.fromHexString(i["entropy"]));
    final valid = AlgorandMnemonicValidator().isValid(mn.toStr());
    assert(valid);
    final entropy = AlgorandMnemonicDecoder().decode(mn.toStr());
    assert(entropy.toHex() == i["entropy"]);
    final seed = AlgorandSeedGenerator(mn).generate();
    assert(seed.toHex() == i["entropy"]);
    final bip44 = Bip44.fromPrivateKey(seed, Bip44Coins.algorand);
    final address = bip44.publicKey.toAddress;
    assert(address == i["address"]);
  }
}

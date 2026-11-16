import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_mnemonic_decoder.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Algorand seed generator class.
class AlgorandSeedGenerator with SecretState {
  final Mnemonic mnemonic;
  final AlgorandLanguages? language;

  /// The [AlgorandSeedGenerator] class is used to generate an Algorand seed
  /// from a mnemonic phrase.
  AlgorandSeedGenerator(
    this.mnemonic, [
    this.language = AlgorandLanguages.english,
  ]);

  SecretBytes generate() {
    return AlgorandMnemonicDecoder(language).decode(mnemonic);
  }

  @override
  void dispose() {
    mnemonic.dispose();
  }
}

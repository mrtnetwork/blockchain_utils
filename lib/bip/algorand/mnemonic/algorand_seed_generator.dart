import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';

/// Algorand seed generator class.
class AlgorandSeedGenerator {
  final List<int> _entropyBytes;

  /// The [AlgorandSeedGenerator] class is used to generate an Algorand seed
  /// from a mnemonic phrase.
  AlgorandSeedGenerator(
    Mnemonic mnemonic, [
    AlgorandLanguages? language = AlgorandLanguages.english,
  ]) : _entropyBytes = AlgorandMnemonicDecoder(
         language,
       ).decode(mnemonic.toStr());

  /// Generate seed. The seed is simply the entropy bytes in Algorand case.
  List<int> generate() {
    return List<int>.from(_entropyBytes);
  }
}

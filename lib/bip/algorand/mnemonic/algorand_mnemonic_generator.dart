import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_entropy_generator.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_encoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';

/// A generator for Algorand mnemonics.
class AlgorandMnemonicGenerator {
  final AlgorandMnemonicEncoder _mnemonicEncoder;

  /// Creates an [AlgorandMnemonicGenerator] with an optional [language].
  AlgorandMnemonicGenerator([
    AlgorandLanguages language = AlgorandLanguages.english,
  ]) : _mnemonicEncoder = AlgorandMnemonicEncoder(language);

  /// Generate an Algorand mnemonic with the specified number of words.
  Mnemonic fromWordsNumber(AlgorandWordsNum wordsNum) {
    final entropyBitLen = wordsNum.bitlen;
    final entropyBytes = AlgorandEntropyGenerator(entropyBitLen).generate();

    return fromEntropy(entropyBytes);
  }

  /// Generate an Algorand mnemonic from entropy bytes.
  Mnemonic fromEntropy(List<int> entropyBytes) {
    return _mnemonicEncoder.encode(entropyBytes);
  }
}

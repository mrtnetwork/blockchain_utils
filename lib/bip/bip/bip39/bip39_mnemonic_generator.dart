import 'package:blockchain_utils/bip/bip/bip39/bip39_entropy_generator.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_encoder.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';

/// BIP39 Mnemonic Generator for generating mnemonic phrases.
class Bip39MnemonicGenerator {
  final Bip39MnemonicEncoder _mnemonicEncoder;

  /// Create a new instance of the BIP39 Mnemonic Generator.
  ///
  /// Parameters:
  /// - [language]: The language used for generating the mnemonic phrase.
  ///
  Bip39MnemonicGenerator([Bip39Languages language = Bip39Languages.english])
    : _mnemonicEncoder = Bip39MnemonicEncoder(language);

  /// Generate a BIP39 mnemonic phrase from the specified number of words.
  ///
  /// Parameters:
  /// - [wordsNum]: The number of words to use in the mnemonic (e.g., Bip39WordsNum.wordsNum12).
  ///
  Mnemonic fromWordsNumber(Bip39WordsNum wordsNum) {
    final Bip39EntropyBitLen entropyBitLen = _entropyBitLenFromWordsNum(
      wordsNum.value,
    );
    final List<int> entropyBytes =
        Bip39EntropyGenerator(entropyBitLen).generate();

    return fromEntropy(entropyBytes);
  }

  /// Generate a BIP39 mnemonic phrase from the provided entropy bytes.
  ///
  /// Parameters:
  /// - [entropyBytes]: The entropy bytes to encode into a mnemonic phrase.
  ///
  Mnemonic fromEntropy(List<int> entropyBytes) {
    return _mnemonicEncoder.encode(entropyBytes);
  }

  /// Calculate the entropy bit length from the number of words.
  ///
  /// Parameters:
  /// - [wordsNum]: The number of words for the mnemonic.
  ///
  Bip39EntropyBitLen _entropyBitLenFromWordsNum(int wordsNum) {
    final bitLen = (wordsNum * Bip39MnemonicConst.wordBitLen) - (wordsNum ~/ 3);

    return Bip39EntropyBitLen.values.firstWhere(
      (element) => element.value == bitLen,
    );
  }
}

import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_entropy_generator.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_encoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// Constants related to Algorand mnemonic generation.
///
/// This class defines a mapping between the number of words in an Algorand mnemonic
/// and the corresponding entropy bit length, ensuring consistent mnemonic generation.
class AlgorandMnemonicGeneratorConst {
  static final Map<AlgorandWordsNum, AlgorandEntropyBitLen>
      wordsNumToEntropyLen = {
    AlgorandWordsNum.wordsNum25: AlgorandEntropyBitLen.bitLen256
  };
}

/// A generator for Algorand mnemonics.
///
/// This class allows you to generate Algorand mnemonics from either a specified
/// number of words or directly from entropy bytes. It ensures that the number
/// of words and entropy bit length are consistent during mnemonic generation.
class AlgorandMnemonicGenerator {
  final AlgorandMnemonicEncoder _mnemonicEncoder;

  /// Creates an [AlgorandMnemonicGenerator] with an optional [language].
  ///
  /// The [language] parameter allows you to specify the language to use when
  /// generating Algorand mnemonics. It defaults to [AlgorandLanguages.english].
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final generator = AlgorandMnemonicGenerator(); // Default language is English.
  /// ```
  ///
  /// You can also specify a different language if needed:
  ///
  /// ```dart
  /// final generator = AlgorandMnemonicGenerator(AlgorandLanguages.spanish);
  /// ```
  AlgorandMnemonicGenerator(
      [AlgorandLanguages language = AlgorandLanguages.english])
      : _mnemonicEncoder = AlgorandMnemonicEncoder(language);

  /// Generate an Algorand mnemonic with the specified number of words.
  ///
  /// [wordsNum] can be either the number of words or an [AlgorandWordsNum] enum value.
  /// It ensures that the number of words is valid and consistent with the entropy bit length.
  Mnemonic fromWordsNumber(AlgorandWordsNum wordsNum) {
    if (!AlgorandMnemonicConst.mnemonicWordNum.contains(wordsNum)) {
      throw ArgumentException(
          'Words number for mnemonic ($wordsNum) is not valid');
    }

    final entropyBitLen =
        AlgorandMnemonicGeneratorConst.wordsNumToEntropyLen[wordsNum]!;
    final entropyBytes = AlgorandEntropyGenerator(entropyBitLen).generate();

    return fromEntropy(entropyBytes);
  }

  /// Generate an Algorand mnemonic from entropy bytes.
  Mnemonic fromEntropy(List<int> entropyBytes) {
    return _mnemonicEncoder.encode(entropyBytes);
  }
}

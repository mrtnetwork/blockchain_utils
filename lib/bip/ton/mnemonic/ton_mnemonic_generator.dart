import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';
import 'ton_entropy_generator.dart';
import 'ton_mnemonic_encoder.dart';
import 'ton_mnemonic_language.dart';
import 'ton_mnemonic_validator.dart';

/// The TonMnemonicGeneratorUtils class provides utility methods for validating
/// the number of mnemonic words and calculating the corresponding bit length.
class TonMnemonicGeneratorUtils {
  /// Validates that the number of mnemonic words is within the acceptable range (8 to 48).
  static void validateWordsNum(int wordsNum) {
    if (wordsNum < 8 || wordsNum > 48) {
      throw const MnemonicException(
          "Invalid mnemonic words count. Words number must be between 8 and 48");
    }
  }

  /// Returns the bit length corresponding to the number of mnemonic words.
  static int getBitlength(int wordsNum) {
    validateWordsNum(wordsNum);
    return (wordsNum * Bip39MnemonicConst.wordBitLen);
  }
}

/// The TonMnemonicGenerator class is responsible for generating BIP-39 mnemonic phrases
/// either from a specified number of words or directly from entropy bytes.
class TonMnemonicGenerator {
  final TonMnemonicEncoder _mnemonicEncoder;

  /// Constructor initializes the mnemonic encoder with the specified language.
  /// Defaults to English if no language is specified.
  TonMnemonicGenerator(
      [TonMnemonicLanguages language = TonMnemonicLanguages.english])
      : _mnemonicEncoder = TonMnemonicEncoder(language);

  /// Generates a mnemonic phrase from a specified number of words, ensuring it is valid
  /// according to the TOM mnemonic validator.
  Mnemonic fromWordsNumber(int wordsNum, {String password = ""}) {
    final validator = TomMnemonicValidator();
    Mnemonic mnemonic;
    while (true) {
      final int entropyBitLen = _entropyBitLenFromWordsNum(wordsNum);
      final List<int> entropyBytes =
          TonMnemonicEntropyGenerator(entropyBitLen).generate();
      mnemonic = fromEntropy(entropyBytes);
      if (!validator.isValid(mnemonic, password: password)) {
        continue;
      }
      break;
    }
    return mnemonic;
  }

  /// Encodes the given entropy bytes into a mnemonic phrase using the encoder.
  Mnemonic fromEntropy(List<int> entropyBytes) {
    return _mnemonicEncoder.encode(entropyBytes);
  }

  /// Calculates the bit length of entropy required for the specified number of words.
  int _entropyBitLenFromWordsNum(int wordsNum) {
    return TonMnemonicGeneratorUtils.getBitlength(wordsNum);
  }
}

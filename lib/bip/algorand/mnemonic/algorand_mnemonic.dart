import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_entropy_generator.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/word_list/word_list.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';

/// Enum representing the number of words in an Algorand mnemonic phrase.
class AlgorandWordsNum {
  /// Represents a 25-word Algorand mnemonic.
  static const AlgorandWordsNum wordsNum25 = AlgorandWordsNum._(
    25,
    AlgorandEntropyBitLen.bitLen256,
  );

  /// The value representing the number of words in the mnemonic phrase.
  final int value;

  final AlgorandEntropyBitLen bitlen;

  /// Constructor to create an AlgorandWordsNum enum value with the specified word count.
  const AlgorandWordsNum._(this.value, this.bitlen);

  static const List<AlgorandWordsNum> values = [wordsNum25];
}

/// Enum representing languages for Algorand mnemonic phrases.
class AlgorandLanguages implements Bip39LanguagesBase {
  /// English language.
  static const AlgorandLanguages english = AlgorandLanguages._();

  const AlgorandLanguages._();

  static const List<AlgorandLanguages> values = [english];

  /// Access to word list.
  @override
  List<String> get wordList {
    switch (this) {
      case AlgorandLanguages.english:
        return Bip32WorList.bip39WordList(Bip39Languages.english);
      default:
        throw UnimplementedError("AlgorandLanguages only support english");
    }
  }

  /// Access to languages.
  @override
  List<MnemonicLanguages> get languageValues => AlgorandLanguages.values;
}

/// Constants related to Algorand mnemonic phrases.
class AlgorandMnemonicConst {
  /// The length of the checksum in bytes.
  static const checksumByteLen = 2;
}

/// Represents Algorand mnemonic phrases, extending the Bip39Mnemonic class.
class AlgorandMnemonic extends Bip39Mnemonic {
  /// Constructs an AlgorandMnemonic instance from a string mnemonic.
  AlgorandMnemonic.fromString(super.mnemonic) : super.fromString();

  /// Constructs an AlgorandMnemonic instance from a list of mnemonic words.
  AlgorandMnemonic.fromList(super.mnemonic) : super.fromList();
}

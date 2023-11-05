import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/word_list/languages.dart'
    as languages;

/// Enum representing the number of words in an Algorand mnemonic phrase.
enum AlgorandWordsNum {
  wordsNum25(25);

  /// The value representing the number of words in the mnemonic phrase.
  final int value;

  /// Constructor to create an AlgorandWordsNum enum value with the specified word count.
  const AlgorandWordsNum(this.value);
}

/// Enum representing languages for Algorand mnemonic phrases.
enum AlgorandLanguages implements MnemonicLanguages {
  /// English language.
  english;

  /// acsess to word list
  @override
  List<String> get wordList {
    switch (this) {
      case AlgorandLanguages.english:
        return languages.bip39WordList(Bip39Languages.english);
    }
  }

  /// acsess to languages
  @override
  List<MnemonicLanguages> get languageValues => AlgorandLanguages.values;
}

/// Constants related to Algorand mnemonic phrases.
class AlgorandMnemonicConst {
  /// List of supported word number options for Algorand mnemonic phrases.
  static const mnemonicWordNum = [AlgorandWordsNum.wordsNum25];

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

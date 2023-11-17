import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'word_list/languages.dart' as languages;

/// Enumeration representing the number of words in a BIP-39 mnemonic phrase.
///
/// BIP-39 defines standard word lengths of 12, 15, 18, 21, and 24 words for
/// mnemonic phrases used in mnemonic-based seed generation.
enum Bip39WordsNum {
  /// 12 words
  wordsNum12(12),

  /// 15 words
  wordsNum15(15),

  /// 18 words
  wordsNum18(18),

  /// 21 words
  wordsNum21(21),

  /// 24 words
  wordsNum24(24);

  final int value;

  /// Create an instance of the Bip39WordsNum with the specified numeric value.
  const Bip39WordsNum(this.value);

  static Bip39WordsNum? fromValue(int value) {
    try {
      return values.firstWhere((element) => element.value == value);
    } on StateError {
      return null;
    }
  }
}

/// Enumeration representing the supported languages for BIP-39 mnemonic phrases.
///
/// BIP-39 allows mnemonic phrases to be generated in various languages.
enum Bip39Languages implements MnemonicLanguages {
  /// Chinese (Simplified)
  chineseSimplified,

  /// Chinese (Traditional)
  chineseTraditional,

  /// Czech
  czech,

  /// English
  english,

  /// French
  french,

  /// Italian
  italian,

  /// Korean
  korean,

  /// Portuguese
  portuguese,

  /// Japanese
  japanese,

  /// Spanish
  spanish;

  /// accsess to language list
  @override
  List<MnemonicLanguages> get languageValues => values;

  /// accsess to words list
  @override
  List<String> get wordList {
    return languages.bip39WordList(this);
  }
}

/// Constants related to BIP-39 mnemonics, including word counts and word list properties.
class Bip39MnemonicConst {
  static final List<Bip39WordsNum> mnemonicWordNum = [
    /// 12 words
    Bip39WordsNum.wordsNum12,

    /// 15 words
    Bip39WordsNum.wordsNum15,

    /// 18 words
    Bip39WordsNum.wordsNum18,

    /// 21 words
    Bip39WordsNum.wordsNum21,

    /// 24 words
    Bip39WordsNum.wordsNum24,
  ];

  /// Number of words in the BIP-39 word list.
  static const int wordsListNum = 2048;

  /// Bit length for each BIP-39 word.
  static const int wordBitLen = 11;
}

/// BIP-39 mnemonic phrase representation.
///
/// This class provides methods for creating BIP-39 mnemonics from strings and lists of words.
class Bip39Mnemonic extends Mnemonic {
  /// Constructs a BIP-39 mnemonic from a mnemonic phrase provided as a string.
  /// This constructor initializes a BIP-39 mnemonic object by parsing the input string.
  Bip39Mnemonic.fromString(super.mnemonic) : super.fromString();

  /// Constructs a BIP-39 mnemonic from a list of words.
  /// This constructor initializes a BIP-39 mnemonic object using a list of BIP-39 words.
  Bip39Mnemonic.fromList(super.mnemonic) : super.fromList();
}

import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'word_list/languages.dart' as languages;

/// Enumeration representing the number of words in a BIP-39 mnemonic phrase.
///
/// BIP-39 defines standard word lengths of 12, 15, 18, 21, and 24 words for
/// mnemonic phrases used in mnemonic-based seed generation.
// Class representing different numbers of words for BIP39.
class Bip39WordsNum {
  // Named constants representing each number of words
  static const int _wordsNum12 = 12;
  static const int _wordsNum15 = 15;
  static const int _wordsNum18 = 18;
  static const int _wordsNum21 = 21;
  static const int _wordsNum24 = 24;

  // Named constants with instances of the class
  static const wordsNum12 = Bip39WordsNum(_wordsNum12);
  static const wordsNum15 = Bip39WordsNum(_wordsNum15);
  static const wordsNum18 = Bip39WordsNum(_wordsNum18);
  static const wordsNum21 = Bip39WordsNum(_wordsNum21);
  static const wordsNum24 = Bip39WordsNum(_wordsNum24);

  // The numeric value associated with each instance
  final int value;

  /// Create an instance of Bip39WordsNum with the specified numeric value.
  const Bip39WordsNum(this.value);

  /// Retrieve an instance of Bip39WordsNum based on the provided numeric value.
  static Bip39WordsNum? fromValue(int value) {
    try {
      return values.firstWhere((element) => element.value == value);
    } on StateError {
      return null;
    }
  }

  // List of all instances of Bip39WordsNum
  static const List<Bip39WordsNum> values = [
    wordsNum12,
    wordsNum15,
    wordsNum18,
    wordsNum21,
    wordsNum24,
  ];
}

/// Enumeration representing the supported languages for BIP-39 mnemonic phrases.
///
/// BIP-39 allows mnemonic phrases to be generated in various languages.
// Class representing different languages for BIP39.
class Bip39Languages implements MnemonicLanguages {
  // Named constants representing each language

  /// Chinese (Simplified)
  static const chineseSimplified = Bip39Languages._('chineseSimplified');

  /// Chinese (Traditional)
  static const chineseTraditional = Bip39Languages._('chineseTraditional');

  /// Czech
  static const czech = Bip39Languages._('czech');

  /// English
  static const english = Bip39Languages._('english');

  /// French
  static const french = Bip39Languages._('french');

  /// Italian
  static const italian = Bip39Languages._('italian');

  /// Korean
  static const korean = Bip39Languages._('korean');

  /// Portuguese
  static const portuguese = Bip39Languages._('portuguese');

  /// Japanese
  static const japanese = Bip39Languages._('japanese');

  /// Spanish
  static const spanish = Bip39Languages._('spanish');

  // The language identifier associated with each instance

  /// Constructor to associate a language identifier with each instance
  final String name;
  const Bip39Languages._(this.name);

  // Access to language list
  @override
  List<MnemonicLanguages> get languageValues => values;

  // Access to words list
  @override
  List<String> get wordList {
    return languages.bip39WordList(this);
  }

  // List of all instances of Bip39Languages
  static const List<Bip39Languages> values = [
    chineseSimplified,
    chineseTraditional,
    czech,
    english,
    french,
    italian,
    korean,
    portuguese,
    japanese,
    spanish,
  ];
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

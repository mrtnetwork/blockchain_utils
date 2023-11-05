import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'words_list/languages.dart' as languages;

/// An enumeration representing the number of words in a Monero mnemonic.
///
/// This enum defines the possible word counts for Monero mnemonics, along with an
/// associated integer value for each word count. Some word counts include a checksum
/// for enhanced error detection and correction.
enum MoneroWordsNum {
  wordsNum12(12), // No checksum
  wordsNum13(13), // With checksum
  wordsNum24(24), // No checksum
  wordsNum25(25); // With checksum

  /// The integer value associated with each word count.
  final int value;

  /// Constructs a MoneroWordsNum with the specified integer value.
  const MoneroWordsNum(this.value);
}

/// An enumeration of Monero-supported languages for mnemonics.
///
/// This enum lists the Monero-supported languages for generating Monero mnemonics.
/// Each language is associated with a specific word list that is used during the
/// mnemonic generation process.
enum MoneroLanguages implements MnemonicLanguages {
  chineseSimplified,
  dutch,
  english,
  french,
  german,
  italian,
  japanese,
  portuguese,
  spanish,
  russian;

  /// Retrieves the word list associated with each Monero language.
  @override
  List<String> get wordList {
    return languages.moneroMnemonicWorsList(this);
  }

  /// list of all supported languages
  @override
  List<MnemonicLanguages> get languageValues => MoneroLanguages.values;
}

/// A class containing constants related to Monero mnemonics.
///
/// This class defines various constants used in Monero mnemonic generation and validation.
/// It includes lists of valid Monero word counts, word counts that include checksums, unique
/// prefix lengths for different Monero languages, and the total number of words in the Monero
/// word list.
class MoneroMnemonicConst {
  /// List of valid Monero word counts for mnemonics.
  static const List<MoneroWordsNum> mnemonicWordNum = [
    MoneroWordsNum.wordsNum12,
    MoneroWordsNum.wordsNum13,
    MoneroWordsNum.wordsNum24,
    MoneroWordsNum.wordsNum25,
  ];

  /// List of Monero word counts that include checksums.
  static const List<MoneroWordsNum> mnemonicWordNumChecksum = [
    MoneroWordsNum.wordsNum13,
    MoneroWordsNum.wordsNum25,
  ];

  /// Mapping of unique prefix lengths for Monero languages.
  static const Map<MnemonicLanguages, int> languageUniquePrefixLen = {
    MoneroLanguages.chineseSimplified: 1,
    MoneroLanguages.dutch: 4,
    MoneroLanguages.english: 3,
    MoneroLanguages.french: 4,
    MoneroLanguages.german: 4,
    MoneroLanguages.italian: 4,
    MoneroLanguages.japanese: 4,
    MoneroLanguages.portuguese: 4,
    MoneroLanguages.spanish: 4,
    MoneroLanguages.russian: 4,
  };

  /// Total number of words in the Monero word list.
  static const int wordsListNum = 1626;
}

/// A class representing a Monero mnemonic.
///
/// This class extends the base `Mnemonic` class and provides specialized
/// constructors for creating Monero mnemonics. It allows the creation of a
/// Monero mnemonic from a list of words, a mnemonic string, or an existing
/// list of mnemonic words.
class MoneroMnemonic extends Mnemonic {
  /// Constructs a MoneroMnemonic from a mnemonic string.
  MoneroMnemonic.fromString(super.mnemonicStr) : super.fromString();

  /// Constructs a MoneroMnemonic from a list of mnemonic words.
  MoneroMnemonic.fromList(super.mnemonicList) : super.fromList();
}

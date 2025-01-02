import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/const/const.dart';
import 'words_list/languages.dart' as languages;

/// An enumeration representing the number of words in a Monero mnemonic.
///
/// This class defines the possible word counts for Monero mnemonics, along with an
/// associated integer value for each word count. Some word counts include a checksum
/// for enhanced error detection and correction.
/// An class representing the number of words in a Monero mnemonic.
class MoneroWordsNum {
  /// No checksum, 12 words
  static const MoneroWordsNum wordsNum12 = MoneroWordsNum._(12);

  /// With checksum, 13 words
  static const MoneroWordsNum wordsNum13 = MoneroWordsNum._(13);

  /// No checksum, 24 words
  static const MoneroWordsNum wordsNum24 = MoneroWordsNum._(24);

  /// With checksum, 25 words
  static const MoneroWordsNum wordsNum25 = MoneroWordsNum._(25);

  /// The integer value associated with each word count.
  final int value;

  /// Constructs a MoneroWordsNum with the specified integer value.
  const MoneroWordsNum._(this.value);

  static const List<MoneroWordsNum> values = [
    wordsNum12,
    wordsNum13,
    wordsNum24,
    wordsNum25
  ];

  static MoneroWordsNum fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () =>
            throw ExceptionConst.itemNotFound(item: "Monero words number"));
  }
}

/// An enumeration of Monero-supported languages for mnemonics.
///
/// This enum lists the Monero-supported languages for generating Monero mnemonics.
/// Each language is associated with a specific word list that is used during the
/// mnemonic generation process.
class MoneroLanguages implements MnemonicLanguages {
  /// Chinese Simplified language
  static const MoneroLanguages chineseSimplified =
      MoneroLanguages._('chineseSimplified');

  /// Dutch language
  static const MoneroLanguages dutch = MoneroLanguages._('dutch');

  /// English language
  static const MoneroLanguages english = MoneroLanguages._('english');

  /// French language
  static const MoneroLanguages french = MoneroLanguages._('french');

  /// German language
  static const MoneroLanguages german = MoneroLanguages._('german');

  /// Italian language
  static const MoneroLanguages italian = MoneroLanguages._('italian');

  /// Japanese language
  static const MoneroLanguages japanese = MoneroLanguages._('japanese');

  /// Portuguese language
  static const MoneroLanguages portuguese = MoneroLanguages._('portuguese');

  /// Spanish language
  static const MoneroLanguages spanish = MoneroLanguages._('spanish');

  /// Russian language
  static const MoneroLanguages russian = MoneroLanguages._('russian');

  final String name;

  /// Constructor for creating a MoneroLanguages enum value with the specified string value.
  const MoneroLanguages._(this.name);

  /// Retrieves the word list associated with each Monero language.
  @override
  List<String> get wordList {
    return languages.moneroMnemonicWorsList(this);
  }

  /// List of all supported languages
  @override
  List<MnemonicLanguages> get languageValues => MoneroLanguages.values;

  /// Represents the available language values for Monero mnemonics.
  static const List<MoneroLanguages> values = [
    chineseSimplified,
    dutch,
    english,
    french,
    german,
    italian,
    japanese,
    portuguese,
    spanish,
    russian,
  ];

  static MoneroLanguages fromValue(String? value) {
    return values.firstWhere((e) => e.name == value,
        orElse: () => throw ExceptionConst.itemNotFound(
            item: "Monero ${value ?? ''} language"));
  }
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
  MoneroMnemonic.fromString(super.mnemonic) : super.fromString();

  /// Constructs a MoneroMnemonic from a list of mnemonic words.
  MoneroMnemonic.fromList(super.mnemonic) : super.fromList();
}

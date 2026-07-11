import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'words_list/languages.dart' as languages;

/// An enumeration representing the number of words in a Monero mnemonic.
class MoneroWordsNum {
  /// No checksum, 12 words
  static const MoneroWordsNum wordsNum12 = MoneroWordsNum._(12, 128);

  /// With checksum, 13 words
  static const MoneroWordsNum wordsNum13 = MoneroWordsNum._(13, 128);

  /// No checksum, 24 words
  static const MoneroWordsNum wordsNum24 = MoneroWordsNum._(24, 256);

  /// With checksum, 25 words
  static const MoneroWordsNum wordsNum25 = MoneroWordsNum._(25, 256);

  /// The integer value associated with each word count.
  final int value;
  final int bitlen;

  bool get withChecksum => this == wordsNum13 || this == wordsNum25;

  /// Constructs a MoneroWordsNum with the specified integer value.
  const MoneroWordsNum._(this.value, this.bitlen);

  static const List<MoneroWordsNum> values = [
    wordsNum12,
    wordsNum13,
    wordsNum24,
    wordsNum25,
  ];

  static MoneroWordsNum fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(value: value),
    );
  }
}

/// An enumeration of Monero-supported languages for mnemonics.
class MoneroLanguages implements MnemonicLanguages {
  /// Chinese Simplified language
  static const MoneroLanguages chineseSimplified = MoneroLanguages._(
    'chineseSimplified',
    prefixLen: 1,
  );

  /// Dutch language
  static const MoneroLanguages dutch = MoneroLanguages._('dutch');

  /// English language
  static const MoneroLanguages english = MoneroLanguages._(
    'english',
    prefixLen: 3,
  );

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

  final int prefixLen;

  /// Constructor for creating a MoneroLanguages enum value with the specified string value.
  const MoneroLanguages._(this.name, {this.prefixLen = 4});

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
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ItemNotFoundException(value: value),
    );
  }

  @override
  String toString() {
    return "MoneroLanguages.$name";
  }
}

/// A class containing constants related to Monero mnemonics.
class MoneroMnemonicConst {
  /// Total number of words in the Monero word list.
  static const int wordsListNum = 1626;
}

/// A class representing a Monero mnemonic.
class MoneroMnemonic extends Mnemonic {
  /// Constructs a MoneroMnemonic from a mnemonic string.
  MoneroMnemonic.fromString(super.mnemonic) : super.fromString();

  /// Constructs a MoneroMnemonic from a list of mnemonic words.
  MoneroMnemonic.fromList(super.mnemonic) : super.fromList();
}

import 'dart:core';

import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'wrodlist/languages.dart' as languages;

/// An enumeration representing the number of words in an Electrum V1 mnemonic.
enum ElectrumV1WordsNum {
  /// Represents a 12-word Electrum V1 mnemonic
  wordsNum12(12);

  final int value;

  /// Constructs an ElectrumV1WordsNum enum value with the specified integer value.
  const ElectrumV1WordsNum(this.value);
}

/// An enumeration representing the languages supported by Electrum V1 mnemonics.
enum ElectrumV1Languages implements MnemonicLanguages {
  /// Represents the English language
  english;

  /// accsess to language list
  @override
  List<MnemonicLanguages> get languageValues => ElectrumV1Languages.values;

  /// accsess to words list
  @override
  List<String> get wordList {
    switch (this) {
      case ElectrumV1Languages.english:
        return languages.elctrumMnemonicWordsList;
    }
  }
}

/// Constants and class definitions related to Electrum V1 mnemonics.
class ElectrumV1MnemonicConst {
  /// List of supported word numbers for Electrum V1 mnemonics
  static const List<ElectrumV1WordsNum> mnemonicWordNum = [
    ElectrumV1WordsNum.wordsNum12
  ];

  /// The number associated with the word list used for Electrum V1 mnemonics
  static const int wordsListNum = 1626;
}

/// A class representing Electrum V1 mnemonics, extending the Bip39Mnemonic class.
class ElectrumV1Mnemonic extends Bip39Mnemonic {
  /// Constructs an Electrum V1 mnemonic from a string representation.
  ElectrumV1Mnemonic.fromString(super.mnemonic) : super.fromString();

  /// Constructs an Electrum V1 mnemonic from a list of words.
  ElectrumV1Mnemonic.fromList(super.mnemonic) : super.fromList();
}

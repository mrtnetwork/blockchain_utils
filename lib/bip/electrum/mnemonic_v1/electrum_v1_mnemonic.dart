import 'dart:core';

import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'wrodlist/languages.dart' as languages;

/// An enumeration representing the number of words in an Electrum V1 mnemonic.
/// An enumeration representing the number of words in an Electrum V1 mnemonic.
class ElectrumV1WordsNum {
  /// Represents a 12-word Electrum V1 mnemonic
  static const ElectrumV1WordsNum wordsNum12 = ElectrumV1WordsNum._(12);

  final int value;

  /// Constructs an ElectrumV1WordsNum enum value with the specified integer value.
  const ElectrumV1WordsNum._(this.value);

  static const List<ElectrumV1WordsNum> values = [wordsNum12];
}

/// An enumeration representing the languages supported by Electrum V1 mnemonics.
class ElectrumV1Languages implements MnemonicLanguages {
  /// Represents the English language
  static const ElectrumV1Languages english = ElectrumV1Languages._('english');

  final String name;

  /// Constructs an ElectrumV1Languages enum value with the specified string value.
  const ElectrumV1Languages._(this.name);

  /// Access to language list
  @override
  List<MnemonicLanguages> get languageValues => ElectrumV1Languages.values;

  /// Access to words list
  @override
  List<String> get wordList {
    switch (this) {
      case ElectrumV1Languages.english:
        return languages.elctrumMnemonicWordsList;
      default:
        throw UnimplementedError(
            "ElectrumV1Languages only support english word list");
    }
  }

  /// Represents the available language values for Electrum V1 mnemonics.
  static const List<ElectrumV1Languages> values = [
    english,
  ];
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

import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/word_list/languages.dart'
    as languages;

/// Enumeration of word counts for Electrum V2 mnemonics.
enum ElectrumV2WordsNum {
  /// Represents a 12-word Electrum V2 mnemonic.
  wordsNum12(12),

  /// Represents a 24-word Electrum V2 mnemonic.
  wordsNum24(24);

  /// The numeric value associated with each word count.
  final int value;

  /// Creates an instance of ElectrumV2WordsNum with the given numeric value.
  const ElectrumV2WordsNum(this.value);
}

/// Enumeration of languages supported by Electrum V2 mnemonics.
enum ElectrumV2Languages implements MnemonicLanguages {
  /// Represents the Chinese Simplified language.
  chineseSimplified,

  /// Represents the English language.
  english,

  /// Represents the Portuguese language.
  portuguese,

  /// Represents the Spanish language.
  spanish;

  /// accsess to words list
  @override
  List<String> get wordList {
    switch (this) {
      case ElectrumV2Languages.chineseSimplified:
        return languages.bip39WordList(Bip39Languages.chineseSimplified);
      case ElectrumV2Languages.english:
        return languages.bip39WordList(Bip39Languages.english);
      case ElectrumV2Languages.portuguese:
        return languages.bip39WordList(Bip39Languages.portuguese);
      case ElectrumV2Languages.spanish:
        return languages.bip39WordList(Bip39Languages.spanish);
    }
  }

  /// accsess to all supported languagess
  @override
  List<MnemonicLanguages> get languageValues => ElectrumV2Languages.values;
}

/// Enumeration of Electrum V2 mnemonic types, representing different mnemonic modes.
enum ElectrumV2MnemonicTypes {
  /// Standard mnemonic type.
  standard(0),

  /// SegWit mnemonic type.
  segwit(1),

  /// Standard 2FA (Two-Factor Authentication) mnemonic type.
  standard2FA(2),

  /// SegWit 2FA (Two-Factor Authentication) mnemonic type.
  segwit2FA(3);

  /// The integer value associated with each mnemonic type.
  final int value;

  /// Constructor for creating an Electrum V2 mnemonic type.
  const ElectrumV2MnemonicTypes(this.value);
}

/// Constants and configurations related to Electrum V2 mnemonics.
class ElectrumV2MnemonicConst {
  /// List of Electrum V2 supported word numbers.
  static const List<ElectrumV2WordsNum> mnemonicWordNum = [
    ElectrumV2WordsNum.wordsNum12,
    ElectrumV2WordsNum.wordsNum24,
  ];

  /// A mapping from Electrum V2 mnemonic types to their corresponding prefixes.
  static const Map<ElectrumV2MnemonicTypes, String> typeToPrefix = {
    ElectrumV2MnemonicTypes.standard: '01',
    ElectrumV2MnemonicTypes.segwit: '100',
    ElectrumV2MnemonicTypes.standard2FA: '101',
    ElectrumV2MnemonicTypes.segwit2FA: '102',
  };

  /// Bit length of a single word in the Electrum V2 mnemonic.
  static const int wordBitLen = Bip39MnemonicConst.wordBitLen;
}

/// Electrum V2 mnemonic class, extending the Bip39Mnemonic class.
class ElectrumV2Mnemonic extends Bip39Mnemonic {
  /// Constructs an Electrum V2 mnemonic from a string.
  ElectrumV2Mnemonic.fromString(super.mnemonic) : super.fromString();

  /// Constructs an Electrum V2 mnemonic from a list of words.
  ElectrumV2Mnemonic.fromList(super.mnemonic) : super.fromList();
}

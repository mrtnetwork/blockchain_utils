import 'package:blockchain_utils/bip/bip/bip39/bip39.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/word_list/languages.dart'
    as languages;

/// The TonMnemonicLanguages class implements the Bip39Languages interface to
/// provide support for BIP-39 mnemonic languages, specifically tailored for TON (The Open Network).
class TonMnemonicLanguages implements Bip39Languages {
  @override
  final String name;

  /// Predefined constant for the English language.
  static const TonMnemonicLanguages english = TonMnemonicLanguages._("English");

  /// Private constructor for defining language instances.
  const TonMnemonicLanguages._(this.name);

  /// List of all supported TonMnemonicLanguages instances.
  static const List<TonMnemonicLanguages> values = [english];

  // Retrieves the word list associated with the language instance.
  @override
  List<String> get wordList {
    switch (this) {
      case TonMnemonicLanguages.english:
        return languages.bip39WordList(Bip39Languages.english);
      default:
        throw const MnemonicException(
            "TonMnemonicLanguages only support english");
    }
  }

  /// Provides a list of all mnemonic language values.
  @override
  List<MnemonicLanguages> get languageValues => TonMnemonicLanguages.values;
}

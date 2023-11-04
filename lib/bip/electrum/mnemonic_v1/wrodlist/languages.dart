/// Library for Electrum V1 mnemonic language support.

library elctrum_v1_mnemonic_languages;

/// Part for the English Electrum V1 mnemonic language.
part 'english.dart';

/// A list of Electrum V1 mnemonic words, specifically for the English language.
List<String> get elctrumMnemonicWordsList => _english;

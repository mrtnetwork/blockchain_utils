import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A class responsible for fetching Electrum V1 mnemonic word lists based on language.
class ElectrumV1WordsListGetter extends MnemonicWordsListGetterBase {
  /// Retrieves an Electrum V1 mnemonic word list for a specific language.
  ///
  /// This method is responsible for fetching the Electrum V1 mnemonic word list based on the specified language.
  /// It validates that the provided language is an instance of `ElectrumV1Languages`, ensuring that the language
  /// is compatible with Electrum V1 mnemonics. It then uses the `loadWordsList` function to load the appropriate
  /// word list based on the language and the predefined words list number.
  ///
  /// Throws an ArgumentException if the provided language is not compatible with Electrum V1 mnemonics.
  ///
  /// Returns the Electrum V1 mnemonic word list for the specified language.
  ///
  /// [language]: The language for which to retrieve the word list.
  @override
  MnemonicWordsList getByLanguage(MnemonicLanguages language) {
    if (language is! ElectrumV1Languages) {
      throw const ArgumentException(
          "Language is not an enumerative of Bip39Languages");
    }
    return loadWordsList(language, ElectrumV1MnemonicConst.wordsListNum);
  }
}

/// A class responsible for finding the Electrum V1 mnemonic word list for a given language.
class ElectrumV1WordsListFinder extends MnemonicWordsListFinderBase {
  /// Finds the language and associated word list for an Electrum V1 mnemonic.
  ///
  /// This method is responsible for determining the language and associated word list used to create
  /// a given Electrum V1 mnemonic. It iterates through all possible Electrum V1 languages and attempts to
  /// match the mnemonic words with each language's word list. If a match is found, it returns the matching
  /// word list and language as a tuple.
  ///
  /// Throws a StateError if the language for the mnemonic cannot be determined.
  ///
  /// Returns a tuple containing the matching word list and the determined language.
  ///
  /// [mnemonic]: The Electrum V1 mnemonic for which to find the language and word list.
  @override
  Tuple<MnemonicWordsList, MnemonicLanguages> findLanguage(Mnemonic mnemonic) {
    for (final lang in ElectrumV1Languages.values) {
      final wordsList = MnemonicWordsList(lang.wordList);
      try {
        for (final word in mnemonic.toList()) {
          wordsList.getWordIdx(word);
        }
        return Tuple(wordsList, lang);
      } on MessageException {
        continue;
      }
    }
    throw MessageException("cannot find language for $mnemonic");
  }
}

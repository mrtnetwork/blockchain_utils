import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_ex.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';

/// A class responsible for fetching Electrum V1 mnemonic word lists based on language.
class ElectrumV1WordsListGetter
    extends MnemonicWordsListGetterBase<ElectrumV1Languages> {
  /// Retrieves an Electrum V1 mnemonic word list for a specific language.
  ///
  /// [language]: The language for which to retrieve the word list.
  ///
  @override
  MnemonicWordsList getByLanguage(ElectrumV1Languages language) {
    return loadWordsList(language, ElectrumV1MnemonicConst.wordsListNum);
  }
}

/// A class responsible for finding the Electrum V1 mnemonic word list for a given language.
class ElectrumV1WordsListFinder
    extends MnemonicWordsListFinderBase<ElectrumV1Languages> {
  /// Finds the language and associated word list for an Electrum V1 mnemonic.
  ///
  /// -[mnemonic]: The Electrum V1 mnemonic for which to find the language and word list.
  ///
  @override
  (MnemonicWordsList, ElectrumV1Languages) findLanguage(Mnemonic mnemonic) {
    for (final lang in ElectrumV1Languages.values) {
      final wordsList = MnemonicWordsList(lang.wordList);
      try {
        for (final word in mnemonic.toList()) {
          wordsList.getWordIdx(word);
        }
        return (wordsList, lang);
      } on MnemonicException {
        continue;
      }
    }
    throw MnemonicException("Unsuported mnemonic language.");
  }
}

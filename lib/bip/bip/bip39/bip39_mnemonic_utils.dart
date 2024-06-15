import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'bip39_mnemonic.dart';

/// Retrieves a list of BIP39 words based on the specified language.
///
/// This class is responsible for fetching the list of BIP39 words for a given
/// language, such as Bip39Languages. It implements the [MnemonicWordsListGetterBase]
/// interface and provides a way to retrieve the word list based on the selected language.
class Bip39WordsListGetter extends MnemonicWordsListGetterBase {
  /// get menemonic language words list
  @override
  MnemonicWordsList getByLanguage(MnemonicLanguages language) {
    if (language is! Bip39Languages &&
        language is! AlgorandLanguages &&
        language is! ElectrumV2Languages) {
      throw const ArgumentException(
          "Language is not an enumerative of Bip39Languages");
    }
    return loadWordsList(language, Bip39MnemonicConst.wordsListNum);
  }
}

/// Finds the language of a BIP39 mnemonic based on the words used.
///
/// This class is responsible for identifying the language of a BIP39 mnemonic
/// based on the words it contains. It implements the [MnemonicWordsListFinderBase]
/// interface. It iterates through supported languages and checks if the words
/// in the mnemonic match any of the languages' word lists.
class Bip39WordsListFinder extends MnemonicWordsListFinderBase {
  /// find language by mnemonic
  @override
  Tuple<MnemonicWordsList, MnemonicLanguages> findLanguage(Mnemonic mnemonic) {
    for (final lang in Bip39Languages.values) {
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

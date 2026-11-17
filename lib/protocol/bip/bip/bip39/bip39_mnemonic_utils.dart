import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Retrieves a list of BIP39 words based on the specified language.
class Bip39WordsListGetter<BIP39LANG extends Bip39LanguagesBase>
    extends MnemonicWordsListGetterBase<BIP39LANG> {
  /// get menemonic language words list
  @override
  MnemonicWordsList getByLanguage(BIP39LANG language) {
    return loadWordsList(language, Bip39MnemonicConst.wordsListNum);
  }
}

/// Finds the language of a BIP39 mnemonic based on the words used.
class Bip39WordsListFinder<BIP39LANG extends Bip39LanguagesBase>
    extends MnemonicWordsListFinderBase<BIP39LANG> {
  final List<BIP39LANG> laguages;
  Bip39WordsListFinder(this.laguages);

  /// find language by mnemonic
  @override
  (MnemonicWordsList, BIP39LANG) findLanguage(Mnemonic mnemonic) {
    for (final lang in laguages) {
      final wordsList = MnemonicWordsList(lang.wordList);
      try {
        for (final word in mnemonic.toList()) {
          wordsList.getWordIdx(word);
        }
        return (wordsList, lang);
      } on BuError catch (e) {
        if (e.type != DefaultErrorType.invalidMnemonic) rethrow;
        continue;
      }
    }
    throw BuError(
      DefaultErrorType.invalidMnemonic,
      "Unsuported mnemonic language.",
    );
  }
}

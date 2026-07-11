import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';

/// An abstract base class for mnemonic phrase decoding in various languages and word lists.
abstract class MnemonicDecoderBase<LANG extends MnemonicLanguages> {
  final LANG? language;
  final MnemonicWordsList? wordsList;
  final MnemonicWordsListFinderBase<LANG> wordsListFinder;

  /// Creates a [MnemonicDecoderBase] instance with optional language and required components.
  MnemonicDecoderBase({
    this.language,
    required this.wordsListFinder,
    required MnemonicWordsListGetterBase wordsListGetter,
  }) : wordsList =
           (language != null ? wordsListGetter.getByLanguage(language) : null);

  /// Decodes the provided mnemonic phrase into binary data.
  List<int> decode(String mnemonic);

  /// Finds the language and word list for a given mnemonic phrase.
  (MnemonicWordsList, LANG) findLanguage(Mnemonic mnemonic) {
    final language = this.language;
    final wordsList = this.wordsList;
    if (language == null || wordsList == null) {
      return wordsListFinder.findLanguage(mnemonic);
    }
    return (wordsList, language);
  }
}

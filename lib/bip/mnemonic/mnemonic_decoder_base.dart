import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// An abstract base class for mnemonic phrase decoding in various languages and word lists.
///
/// This class provides the foundation for decoding mnemonic phrases into binary data.
/// It allows you to specify a language, a word list, and a words list finder to find the appropriate
/// language and word list when decoding.
abstract class MnemonicDecoderBase {
  final MnemonicLanguages? language;
  final MnemonicWordsList? wordsList;
  final MnemonicWordsListFinderBase wordsListFinder;

  /// Creates a [MnemonicDecoderBase] instance with optional language and required components.
  ///
  /// The [language] parameter specifies the language to use for decoding. If null, the language
  /// will be determined using the [wordsListFinder]. The [wordsListFinder] is used to find
  /// the appropriate language and word list.
  ///
  /// The [wordsListGetter] parameter is used to retrieve word lists by language.
  MnemonicDecoderBase({
    this.language,
    required this.wordsListFinder,
    required MnemonicWordsListGetterBase wordsListGetter,
  }) : wordsList =
            (language != null ? wordsListGetter.getByLanguage(language) : null);

  /// Decodes the provided mnemonic phrase into binary data.
  List<int> decode(String mnemonic);

  /// Finds the language and word list for a given mnemonic phrase.
  ///
  /// If a language is specified, it is used. Otherwise, the [wordsListFinder] is used to determine
  /// the appropriate language and word list for decoding.
  Tuple<MnemonicWordsList, MnemonicLanguages> findLanguage(Mnemonic mnemonic) {
    if (language == null || wordsList == null) {
      return wordsListFinder.findLanguage(mnemonic);
    }
    return Tuple(wordsList!, language!);
  }
}

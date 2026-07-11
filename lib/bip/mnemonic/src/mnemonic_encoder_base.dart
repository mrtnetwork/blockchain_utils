import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';

/// An abstract class for encoding binary entropy data into human-readable mnemonic phrases.
abstract class MnemonicEncoderBase {
  /// The list of words used for encoding.
  final MnemonicWordsList wordsList;

  /// Creates an instance of MnemonicEncoderBase.
  ///
  /// The [language] parameter specifies the language used for the mnemonic words.
  /// The [wordsListGetter] is a helper class to retrieve the appropriate words list.
  ///
  MnemonicEncoderBase(
    MnemonicLanguages language,
    MnemonicWordsListGetterBase wordsListGetter,
  ) : wordsList = wordsListGetter.getByLanguage(language);

  /// Encodes the provided binary entropy data into a human-readable mnemonic phrase.
  ///
  /// The [entropyBytes] parameter is the binary entropy data to be encoded.
  Mnemonic encode(List<int> entropyBytes);
}

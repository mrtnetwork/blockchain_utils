import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A class that retrieves Monero mnemonic word lists by language.
///
/// This class extends `MnemonicWordsListGetterBase` and is specifically designed to
/// retrieve Monero mnemonic word lists based on the specified Monero language.
class MoneroWordsListGetter extends MnemonicWordsListGetterBase {
  /// Retrieves a MnemonicWordsList based on the specified language.
  ///
  /// This method takes a `MnemonicLanguages` object as input and attempts to convert
  /// it into a `MoneroLanguages` object to ensure it is a valid Monero language.
  /// Then, it loads the Monero mnemonic word list corresponding to the specified language
  /// using `loadWordsList` and the number of word lists defined in `MoneroMnemonicConst`.
  ///
  /// Throws an `ArgumentException` if the language is not a valid Monero language.
  ///
  /// [language]: The Monero language for which to retrieve the word list.
  @override
  MnemonicWordsList getByLanguage(MnemonicLanguages language) {
    if (language is! MoneroLanguages) {
      throw const ArgumentException(
          "Language is not an enumerative of MoneroLanguages");
    }
    return loadWordsList(language, MoneroMnemonicConst.wordsListNum);
  }
}

/// A class responsible for finding Monero mnemonic word lists.
///
/// This class extends `MnemonicWordsListFinderBase` and provides specific
/// functionality for locating Monero mnemonic word lists. It facilitates
/// the retrieval of word lists based on the provided parameters.
class MoneroWordsListFinder extends MnemonicWordsListFinderBase {
  /// This method attempts to determine the language of a Monero mnemonic by iterating
  /// through the available MoneroLanguages and checking if the words in the mnemonic
  /// match the word list of each language. It returns the matching MnemonicWordsList
  /// and the associated MoneroLanguages if a match is found.
  ///
  /// Throws a StateError if the language for the mnemonic cannot be determined.
  ///
  /// [mnemonic]: The Monero mnemonic from which to identify the language.
  /// Returns a tuple containing the MnemonicWordsList and the identified MoneroLanguages.
  @override
  Tuple<MnemonicWordsList, MnemonicLanguages> findLanguage(Mnemonic mnemonic) {
    for (final lang in MoneroLanguages.values) {
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

/// A utility class for handling Monero mnemonic-related operations.
///
/// This class provides utility methods for working with Monero mnemonics, including
/// the computation of checksums for error detection and correction.
class MoneroMnemonicUtils {
  /// Computes the checksum word for a list of Monero mnemonic words.
  ///
  /// This method takes a list of Monero mnemonic words and a specified Monero language.
  /// It computes a checksum word for the given mnemonic words to enhance error detection
  /// and correction.
  ///
  /// [mnemonic]: The list of Monero mnemonic words for which to compute the checksum.
  /// [language]: The Monero language used in the mnemonic.
  /// Returns the computed checksum word.
  static String computeChecksum(
      List<String> mnemonic, MnemonicLanguages language) {
    final uniqueLen = MoneroMnemonicConst.languageUniquePrefixLen[language]!;
    String prefixes = mnemonic.map((word) {
      final len = word.length >= uniqueLen ? uniqueLen : word.length;
      return word.substring(0, len);
    }).join();

    int index =
        Crc32.quickIntDigest(StringUtils.encode(prefixes)) % mnemonic.length;
    return mnemonic[index];
  }
}

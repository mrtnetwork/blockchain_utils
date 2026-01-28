import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// A class that retrieves Monero mnemonic word lists by language.
class MoneroWordsListGetter
    extends MnemonicWordsListGetterBase<MoneroLanguages> {
  /// Retrieves a MnemonicWordsList based on the specified language.
  /// -[language]: The Monero language for which to retrieve the word list.
  ///
  @override
  MnemonicWordsList getByLanguage(MoneroLanguages language) {
    return loadWordsList(language, MoneroMnemonicConst.wordsListNum);
  }
}

/// A class responsible for finding Monero mnemonic word lists.
class MoneroWordsListFinder
    extends MnemonicWordsListFinderBase<MoneroLanguages> {
  /// This method attempts to determine the language of a Monero mnemonic by iterating
  /// through the available MoneroLanguages and checking if the words in the mnemonic
  /// match the word list of each language. It returns the matching MnemonicWordsList
  /// and the associated MoneroLanguages if a match is found.
  ///
  /// Throws a StateError if the language for the mnemonic cannot be determined.
  ///
  /// -[mnemonic]: The Monero mnemonic from which to identify the language.
  ///
  @override
  (MnemonicWordsList, MoneroLanguages) findLanguage(Mnemonic mnemonic) {
    for (final lang in MoneroLanguages.values) {
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

/// A utility class for handling Monero mnemonic-related operations.
class MoneroMnemonicUtils {
  /// Computes the checksum word for a list of Monero mnemonic words.
  ///
  /// -[mnemonic]: The list of Monero mnemonic words for which to compute the checksum.
  /// -[language]: The Monero language used in the mnemonic.
  ///
  static String computeChecksum(
    List<String> mnemonic,
    MoneroLanguages language,
  ) {
    final uniqueLen = language.prefixLen;
    final String prefixes =
        mnemonic.map((word) {
          final len = word.length >= uniqueLen ? uniqueLen : word.length;
          return word.substring(0, len);
        }).join();

    final int index =
        Crc32().quickIntDigest(StringUtils.encode(prefixes)) % mnemonic.length;
    return mnemonic[index];
  }

  /// check if the string is valid mnemonic and has correct words length.
  static bool isValidMnemonicLength(String? mnemonic) {
    if (mnemonic == null) return false;
    try {
      final lenght = Mnemonic.fromString(mnemonic).toList().length;
      return MoneroWordsNum.values.any((e) => e.value == lenght);
    } catch (_) {
      return false;
    }
  }
}

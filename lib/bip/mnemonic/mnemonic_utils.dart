import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

/// An abstract class representing different languages for mnemonic phrases.
/// Classes implementing this interface must provide word lists and language values.
abstract class MnemonicLanguages {
  /// Returns a list of words that correspond to the language.
  List<String> get wordList;

  /// Returns a list of language values, typically containing all available languages.
  List<MnemonicLanguages> get languageValues;
}

/// A utility class for handling operations related to mnemonics.
class MnemonicUtils {
  /// Converts a chunk of bytes into a list of three words using a provided word list.
  static List<String> bytesChunkToWords(
    List<int> bytesChunk,
    MnemonicWordsList wordsList, {
    Endian endian = Endian.big,
  }) {
    final n = wordsList.length();

    final intChunk = IntUtils.fromBytes(bytesChunk, byteOrder: endian);
    final word1Idx = intChunk % n;
    final word2Idx = ((intChunk ~/ n) + word1Idx) % n;
    final word3Idx = ((intChunk ~/ (n * n) + word2Idx)) % n;

    return [
      wordsList.getWordAtIdx(word1Idx),
      wordsList.getWordAtIdx(word2Idx),
      wordsList.getWordAtIdx(word3Idx),
    ];
  }

  /// Converts a sequence of three words into a byte chunk using a specified word list.
  static List<int> wordsToBytesChunk(
    String word1,
    String word2,
    String word3,
    MnemonicWordsList wordsList, {
    Endian endian = Endian.big,
  }) {
    final n = wordsList.length();
    final word1Idx = wordsList.getWordIdx(word1);
    final word2Idx = wordsList.getWordIdx(word2) % n;
    final word3Idx = wordsList.getWordIdx(word3) % n;

    final intChunk =
        word1Idx +
        (n * ((word2Idx - word1Idx) % n)) +
        (n * n * ((word3Idx - word2Idx) % n));

    return IntUtils.toBytes(intChunk, byteOrder: endian, length: 4);
  }
}

/// A class that represents a list of words used in a mnemonic system.
class MnemonicWordsList {
  final List<String> _idxToWords;
  MnemonicWordsList(List<String> wordsList) : _idxToWords = wordsList;

  /// Returns the total number of words in the list.
  int length() {
    return _idxToWords.length;
  }

  /// Retrieves the index of a word within the list.
  ///
  /// Throws a [MnemonicException] if the word is not found in the list.
  int getWordIdx(String word) {
    final index = _idxToWords.indexOf(word);
    if (index < 0) {
      throw MnemonicException("Invalid mnemonic index.");
    }
    return index;
  }

  /// Returns the word located at the specified index.
  String getWordAtIdx(int wordIdx) {
    return _idxToWords[wordIdx];
  }
}

/// An abstract class for retrieving a list of words based on a specified language.
abstract class MnemonicWordsListGetterBase<LANG extends MnemonicLanguages> {
  /// Gets a list of words for a given language.
  MnemonicWordsList getByLanguage(LANG language);

  /// Loads the words list for a given language and verifies its length.
  MnemonicWordsList loadWordsList(LANG language, int wordsNum) {
    if (language.wordList.length != wordsNum) {
      throw MnemonicException("Invalid mnemonic word list.");
    }
    return MnemonicWordsList(language.wordList);
  }
}

/// An abstract class for finding the language of a mnemonic based on its words.
abstract class MnemonicWordsListFinderBase<LANG extends MnemonicLanguages> {
  /// Finds the language of a mnemonic based on its words.
  (MnemonicWordsList, LANG) findLanguage(Mnemonic mnemonic);
}

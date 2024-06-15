import 'dart:typed_data';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

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
  ///
  /// The [bytesChunk] is converted into an integer and then divided into three
  /// indices within the specified [wordsList]. The resulting words are returned
  /// as a list.
  ///
  /// You can also specify the [endian] order for interpreting the bytes.
  ///
  /// Example usage:
  /// ```dart
  /// final words = MnemonicUtils.bytesChunkToWords(List<int>.from([0, 1, 2, 3]), wordsList);
  /// ```
  static List<String> bytesChunkToWords(
      List<int> bytesChunk, MnemonicWordsList wordsList,
      {Endian endian = Endian.big}) {
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
  ///
  /// The three input words are mapped to their respective indices within the [wordsList].
  /// These indices are used to calculate an integer value that is then transformed into
  /// a byte chunk. The resulting byte chunk is returned.
  ///
  /// You can also specify the [endian] order for byte interpretation (default is little-endian).
  ///
  /// Example usage:
  /// ```dart
  /// final chunk = MnemonicUtils.wordsToBytesChunk('word1', 'word2', 'word3', wordsList);
  /// ```
  ///
  /// The method allows for encoding three words as a chunk of bytes for various mnemonic systems.
  static List<int> wordsToBytesChunk(
      String word1, String word2, String word3, MnemonicWordsList wordsList,
      {Endian endian = Endian.big}) {
    final n = wordsList.length();
    final word1Idx = wordsList.getWordIdx(word1);
    final word2Idx = wordsList.getWordIdx(word2) % n;
    final word3Idx = wordsList.getWordIdx(word3) % n;

    final intChunk = word1Idx +
        (n * ((word2Idx - word1Idx) % n)) +
        (n * n * ((word3Idx - word2Idx) % n));

    return IntUtils.toBytes(intChunk, byteOrder: endian, length: 4);
  }
}

/// A class that represents a list of words used in a mnemonic system.
///
/// This class provides methods for working with a list of words, such as retrieving
/// a word's index, obtaining a word by its index, and getting the total number of words.
///
/// Example usage:
/// ```dart
/// final wordsList = MnemonicWordsList(['word1', 'word2', 'word3']);
/// final index = wordsList.getWordIdx('word2');
/// final word = wordsList.getWordAtIdx(1);
/// final totalWords = wordsList.length();
/// ```
class MnemonicWordsList {
  final List<String> _idxToWords;
  MnemonicWordsList(List<String> wordsList) : _idxToWords = wordsList;

  /// Returns the total number of words in the list.
  int length() {
    return _idxToWords.length;
  }

  /// Retrieves the index of a word within the list.
  ///
  /// Throws a [StateError] if the word is not found in the list.
  int getWordIdx(String word) {
    final index = _idxToWords.indexOf(word);
    if (index < 0) {
      throw MessageException("Unable to find word $word");
    }
    return index;
  }

  /// Returns the word located at the specified index.
  String getWordAtIdx(int wordIdx) {
    return _idxToWords[wordIdx];
  }
}

/// An abstract class for retrieving a list of words based on a specified language.
///
/// Subclasses of this class must implement the `getByLanguage` method to return
/// the corresponding words list based on the provided language.
abstract class MnemonicWordsListGetterBase {
  /// Gets a list of words for a given language.
  ///
  /// Subclasses must implement this method to return a [MnemonicWordsList] based on
  /// the specified language.
  ///
  /// Example usage:
  /// ```dart
  /// final wordsListGetter = SomeMnemonicWordsListGetter();
  /// final wordsList = wordsListGetter.getByLanguage(MnemonicLanguages.english);
  /// ```
  MnemonicWordsList getByLanguage(MnemonicLanguages language);

  /// Loads the words list for a given language and verifies its length.
  ///
  /// This method is used to load a words list for the specified language and
  /// ensures that the loaded list contains the expected number of words.
  /// Subclasses may use this method when implementing `getByLanguage`.
  MnemonicWordsList loadWordsList(MnemonicLanguages language, int wordsNum) {
    if (language.wordList.length != wordsNum) {
      throw ArgumentException(
          "Number of loaded words list (${language.wordList.length}) is not valid");
    }
    return MnemonicWordsList(language.wordList);
  }
}

/// An abstract class for finding the language of a mnemonic based on its words.
///
/// Subclasses of this class must implement the `findLanguage` method to determine
/// the language of a mnemonic based on its word content.
abstract class MnemonicWordsListFinderBase {
  /// Finds the language of a mnemonic based on its words.
  ///
  /// Subclasses must implement this method to discover the language of a mnemonic
  /// based on the provided mnemonic's words. It should return both the found
  /// [MnemonicWordsList] and the identified [MnemonicLanguages].
  ///
  /// Example usage:
  /// ```dart
  /// final finder = SomeMnemonicWordsListFinder();
  /// final result = finder.findLanguage(Mnemonic(['word1', 'word2']),);
  /// final foundList = result.item1;
  /// final foundLanguage = result.item2;
  /// ```
  Tuple<MnemonicWordsList, MnemonicLanguages> findLanguage(Mnemonic mnemonic);
}

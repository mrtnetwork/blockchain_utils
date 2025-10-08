import 'dart:typed_data';

import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import '../../mnemonic/mnemonic_ex.dart';

/// Decoder for Monero-style mnemonics with language support.
class MoneroMnemonicDecoder extends MnemonicDecoderBase {
  /// Creates a Monero mnemonic decoder with an optional language parameter.
  /// Defaults to the English language.
  MoneroMnemonicDecoder([MoneroLanguages? language = MoneroLanguages.english])
      : super(
            language: language,
            wordsListFinder: MoneroWordsListFinder(),
            wordsListGetter: MoneroWordsListGetter());

  /// Decodes a Monero mnemonic string into a `List<int>` representing entropy.
  ///
  /// This method takes a Monero mnemonic string as input and processes it to obtain
  /// the corresponding entropy bytes. It validates the mnemonic's word count and detects
  /// the language if it was not specified during construction. Then, it converts the mnemonic
  /// words into entropy bytes by considering 3 words at a time, where 3 words represent 4 bytes.
  ///
  /// Throws a StateError if the mnemonic words count is not valid.
  ///
  /// Returns a `List<int>` containing the decoded entropy bytes.
  ///
  /// [mnemonic]: The Monero mnemonic string to decode.
  @override
  List<int> decode(String mnemonic) {
    final mn = MoneroMnemonic.fromString(mnemonic);
    final wcount = mn.wordsCount();
    try {
      MoneroMnemonicConst.mnemonicWordNum
          .where((element) => element.value == wcount);
    } on StateError {
      throw ArgumentException("Mnemonic words count is not valid ($wcount)");
    }
    final lang = findLanguage(mn);
    final words = mn.toList();
    validateCheckSum(words, lang.item2 as MoneroLanguages);
    List<int> entropyBytes = List.empty();
    for (int i = 0; i < words.length ~/ 3; i++) {
      final String word1 = words[i * 3];
      final String word2 = words[i * 3 + 1];
      final String word3 = words[i * 3 + 2];
      final List<int> chunkBytes = MnemonicUtils.wordsToBytesChunk(
          word1, word2, word3, lang.item1,
          endian: Endian.little);
      entropyBytes = List<int>.from([...entropyBytes, ...chunkBytes]);
    }
    return entropyBytes;
  }

  /// Validates the checksum of a list of Monero mnemonic words.
  ///
  /// This method checks whether the provided Monero mnemonic words have a valid checksum
  /// by comparing them to the expected checksum. If the checksum is invalid, it throws
  /// a MnemonicException.
  ///
  /// [words]: The list of Monero mnemonic words to validate.
  /// [language]: The Monero language used in the mnemonic.
  void validateCheckSum(List<String> words, MoneroLanguages language) {
    try {
      MoneroMnemonicConst.mnemonicWordNumChecksum
          .firstWhere((element) => element.value == words.length);
      final checkSum = MoneroMnemonicUtils.computeChecksum(
          words.sublist(0, words.length - 1), language);
      if (words.last != checkSum) {
        throw MnemonicException(
            'Invalid checksum (expected $checkSum, got ${words.last})');
      }
      // ignore: empty_catches
    } on StateError {}
  }
}

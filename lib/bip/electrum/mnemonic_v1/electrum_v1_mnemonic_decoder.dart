import 'dart:core';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// A class for decoding Electrum V1 mnemonics, extending the MnemonicDecoderBase class.
class ElectrumV1MnemonicDecoder extends MnemonicDecoderBase {
  /// Constructs an ElectrumV1MnemonicDecoder with an optional language specification.
  ElectrumV1MnemonicDecoder(
      [ElectrumV1Languages? language = ElectrumV1Languages.english])
      : super(
          language: language,
          wordsListFinder: ElectrumV1WordsListFinder(),
          wordsListGetter: ElectrumV1WordsListGetter(),
        );

  /// Decodes an Electrum V1 mnemonic string into a `List<int>` representing entropy.
  ///
  /// This method takes an Electrum V1 mnemonic string as input and processes it to obtain
  /// the corresponding entropy bytes. It validates the mnemonic's word count and detects
  /// the language if it was not specified during construction. Then, it converts the mnemonic
  /// words into entropy bytes by considering 3 words at a time, where 3 words represent 4 bytes.
  ///
  /// Throws an ArgumentException if the mnemonic words count is not valid.
  ///
  /// Returns a `List<int>` containing the decoded entropy bytes.
  ///
  /// [mnemonic]: The Electrum V1 mnemonic string to decode.
  @override
  List<int> decode(String mnemonic) {
    /// Parse the mnemonic into an Electrum V1 mnemonic object
    final mnemonicObj = ElectrumV1Mnemonic.fromString(mnemonic);

    /// Get the number of words in the mnemonic
    final wCount = mnemonicObj.wordsCount();

    /// Validate the words count against a predefined list
    try {
      ElectrumV1MnemonicConst.mnemonicWordNum
          .firstWhere((element) => element.value == wCount);
    } on StateError {
      throw ArgumentException('Mnemonic words count is not valid ($wCount)');
    }

    // Detect language if it was not specified at construction
    final wordsList = findLanguage(mnemonicObj).item1;

    // Get words from the mnemonic
    final words = mnemonicObj.toList();

    // Consider 3 words at a time, 3 words represent 4 bytes
    List<int> entropyBytes = List.empty();
    for (int i = 0; i < words.length ~/ 3; i++) {
      final word1 = words[i * 3];
      final word2 = words[i * 3 + 1];
      final word3 = words[i * 3 + 2];
      entropyBytes = List<int>.from([
        ...entropyBytes,
        ...MnemonicUtils.wordsToBytesChunk(
          word1,
          word2,
          word3,
          wordsList,
        )
      ]);
    }

    return entropyBytes;
  }
}

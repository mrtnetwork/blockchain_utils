import 'dart:core';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_utils.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class for decoding Electrum V1 mnemonics, extending the MnemonicDecoderBase class.
class ElectrumV1MnemonicDecoder
    extends MnemonicDecoderBase<ElectrumV1Languages> {
  /// Constructs an ElectrumV1MnemonicDecoder with an optional language specification.
  ElectrumV1MnemonicDecoder([
    ElectrumV1Languages? language = ElectrumV1Languages.english,
  ]) : super(
         language: language,
         wordsListFinder: ElectrumV1WordsListFinder(),
         wordsListGetter: ElectrumV1WordsListGetter(),
       );

  /// Decodes an Electrum V1 mnemonic string into a `List<int>` representing entropy.
  ///
  /// -[mnemonic]: The Electrum V1 mnemonic string to decode.
  ///
  @override
  SecretBytes decode(Mnemonic mnemonic) {
    // Get words from the mnemonic
    final words = mnemonic.toList();

    /// Get the number of words in the mnemonic
    final wCount = mnemonic.wordsCount();

    if (wCount != ElectrumV1WordsNum.wordsNum12.value) {
      throw CoreErrors.invalidOperationArguments(
        "decode",
        name: "mnemonic",
        reason: "Invalid mnemonic length.",
      );
    }
    // Detect language if it was not specified at construction
    final wordsList = findLanguage(mnemonic).$1;

    // Consider 3 words at a time, 3 words represent 4 bytes
    BuBytes entropyBytes = BuBytes.empty();
    for (int i = 0; i < words.length ~/ 3; i++) {
      final word1 = words[i * 3];
      final word2 = words[i * 3 + 1];
      final word3 = words[i * 3 + 2];
      entropyBytes.addAll(
        MnemonicUtils.wordsToBytesChunk(word1, word2, word3, wordsList),
      );
    }

    return SecretBytes.take(entropyBytes);
  }
}

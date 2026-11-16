import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic_utils.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decoder for Monero-style mnemonics with language support.
class MoneroMnemonicDecoder extends MnemonicDecoderBase<MoneroLanguages> {
  /// Creates a Monero mnemonic decoder with an optional language parameter.
  /// Defaults to the English language.
  MoneroMnemonicDecoder([MoneroLanguages? language = MoneroLanguages.english])
    : super(
        language: language,
        wordsListFinder: MoneroWordsListFinder(),
        wordsListGetter: MoneroWordsListGetter(),
      );

  /// Decodes a Monero mnemonic string into entropy.
  ///
  /// -[mnemonic]: The Monero mnemonic string to decode.
  ///
  @override
  SecretBytes decode(Mnemonic mnemonic) {
    // final mn = MoneroMnemonic.fromString(mnemonic);
    final wcount = mnemonic.wordsCount();
    MoneroWordsNum.values.firstWhere(
      (element) => element.value == wcount,
      orElse:
          () =>
              throw CoreErrors.invalidOperationArguments(
                "decode",
                name: "mnemonic",
                reason: "Invalid mnemonic length.",
              ),
    );
    final lang = findLanguage(mnemonic);
    final words = mnemonic.toList();
    validateCheckSum(words, lang.$2);
    BuBytes entropyBytes = BuBytes.empty();
    for (int i = 0; i < words.length ~/ 3; i++) {
      final String word1 = words[i * 3];
      final String word2 = words[i * 3 + 1];
      final String word3 = words[i * 3 + 2];
      final List<int> chunkBytes = MnemonicUtils.wordsToBytesChunk(
        word1,
        word2,
        word3,
        lang.$1,
        endian: Endian.little,
      );
      entropyBytes.addAll(chunkBytes);
    }
    return SecretBytes.take(entropyBytes);
  }

  /// Validates the checksum of a list of Monero mnemonic words.
  ///
  /// -[words]: The list of Monero mnemonic words to validate.
  /// -[language]: The Monero language used in the mnemonic.
  ///
  void validateCheckSum(List<String> words, MoneroLanguages language) {
    final w = MoneroWordsNum.values.firstWhere(
      (element) => element.value == words.length,
      orElse:
          () =>
              throw CoreErrors.invalidOperationArguments(
                "decode",
                name: "mnemonic",
                reason: "Invalid mnemonic length.",
              ),
    );
    if (!w.withChecksum) return;
    final checkSum = MoneroMnemonicUtils.computeChecksum(
      words.sublist(0, words.length - 1),
      language,
    );
    if (words.last != checkSum) {
      throw CoreErrors.mnemonicInvalidChecksum;
    }
  }
}

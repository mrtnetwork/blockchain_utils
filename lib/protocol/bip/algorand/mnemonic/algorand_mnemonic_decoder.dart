import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/algorand/mnemonic/algorand_mnemonic_utils.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes Algorand mnemonics to obtain the corresponding entropy.
class AlgorandMnemonicDecoder extends MnemonicDecoderBase<AlgorandLanguages> {
  /// Creates an instance of AlgorandMnemonicDecoder with an optional language setting.
  ///
  /// The [language] parameter specifies the language used for the mnemonic words. The default is English.
  AlgorandMnemonicDecoder([
    AlgorandLanguages? language = AlgorandLanguages.english,
  ]) : super(
         language: language,
         wordsListFinder: Bip39WordsListFinder(AlgorandLanguages.values),
         wordsListGetter: Bip39WordsListGetter(),
       );

  /// Decodes an Algorand mnemonic phrase and returns the corresponding entropy as [SecretBytes].
  ///
  /// The [mnemonic] parameter is the Algorand mnemonic phrase to decode.
  @override
  SecretBytes decode(Mnemonic mnemonic) {
    final wLength = mnemonic.wordsCount();
    AlgorandWordsNum.values.firstWhere(
      (element) => element.value == wLength,
      orElse:
          () =>
              throw CoreErrors.invalidOperationArguments(
                "decode",
                name: "mnemonic",
                reason: "Invalid mnemonic length.",
              ),
    );

    final words = mnemonic.toList();
    final wordsList = findLanguage(mnemonic).$1;
    final wordIndexes = [for (final w in words) wordsList.getWordIdx(w)];
    final entropyList = AlgorandMnemonicUtils.convertBits(
      wordIndexes.getRange(0, words.length - 1).toList(),
      11,
      8,
    );
    final entropyBytes = entropyList!.sublist(0, entropyList.length - 1);

    _validateChecksum(entropyBytes, wordIndexes.last, wordsList);

    return SecretBytes.take(entropyBytes);
  }

  /// Validates the checksum of the decoded entropy.
  void _validateChecksum(
    List<int> entropyBytes,
    int chksumWordIdxExp,
    MnemonicWordsList wordsList,
  ) {
    final chksumWordIdx = AlgorandMnemonicUtils.computeChecksumWordIndex(
      entropyBytes,
    );
    if (chksumWordIdx != chksumWordIdxExp) {
      throw CoreErrors.mnemonicInvalidChecksum;
    }
  }
}

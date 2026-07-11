import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_ex.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

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

  /// Decodes an Algorand mnemonic phrase and returns the corresponding entropy as a byte list.
  ///
  /// The [mnemonic] parameter is the Algorand mnemonic phrase to decode.
  @override
  List<int> decode(String mnemonic) {
    final mnemonicObj = AlgorandMnemonic.fromString(mnemonic);
    final wLength = mnemonicObj.wordsCount();
    AlgorandWordsNum.values.firstWhere(
      (element) => element.value == wLength,
      orElse:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "decode",
                name: "mnemonic",
                reason: "Invalid mnemonic length.",
              ),
    );

    final words = mnemonicObj.toList();
    final wordsList = findLanguage(mnemonicObj).$1;
    final wordIndexes = [for (final w in words) wordsList.getWordIdx(w)];
    final entropyList = AlgorandMnemonicUtils.convertBits(
      wordIndexes.getRange(0, words.length - 1).toList(),
      11,
      8,
    );
    assert(entropyList != null);
    final entropyBytes = entropyList!.sublist(0, entropyList.length - 1);

    _validateChecksum(entropyBytes, wordIndexes.last, wordsList);

    return entropyBytes;
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
      throw MnemonicException.invalidChecksum;
    }
  }
}

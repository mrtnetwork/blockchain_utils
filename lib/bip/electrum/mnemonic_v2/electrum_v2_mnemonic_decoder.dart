import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// A class for decoding Electrum V2 mnemonics, extending the MnemonicDecoderBase class.
class ElectrumV2MnemonicDecoder
    extends MnemonicDecoderBase<ElectrumV2Languages> {
  final ElectrumV2MnemonicTypes? mnemonicType;

  /// Constructs an Electrum V2 mnemonic decoder with optional parameters.
  ///
  /// - [mnemonicType]: The type of Electrum V2 mnemonic (optional).
  /// - [language]: The language used for mnemonic decoding (default: English).
  ///
  ElectrumV2MnemonicDecoder({this.mnemonicType, super.language})
    : super(
        wordsListFinder: Bip39WordsListFinder<ElectrumV2Languages>(
          ElectrumV2Languages.values,
        ),
        wordsListGetter: Bip39WordsListGetter(),
      );

  /// Decodes an Electrum V2 mnemonic string into entropy bytes.
  /// -[mnemonic]: The Electrum V2 mnemonic to decode into entropy bytes.
  ///
  @override
  List<int> decode(String mnemonic) {
    /// Parse the mnemonic string
    final mnemonicObj = ElectrumV2Mnemonic.fromString(mnemonic);
    final wCount = mnemonicObj.wordsCount();
    ElectrumV2MnemonicConst.mnemonicWordNum.firstWhere(
      (element) => element.value == wCount,
      orElse:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "decode",
                name: "mnemonic",
                reason: "Invalid mnemonic length.",
              ),
    );

    /// Check the validity of the mnemonic for the specified mnemonic type
    if (!ElectrumV2MnemonicUtils.isValidMnemonic(mnemonicObj, mnemonicType)) {
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "mnemonic",
        reason: "Invalid mnemonic.",
      );
    }

    /// Get the list of words from the mnemonic
    final words = mnemonicObj.toList();

    /// Detect the language if it was not specified during construction
    final wordsList = findLanguage(mnemonicObj).$1;

    /// Decode the words into entropy as a BigInt
    final n = BigInt.from(wordsList.length());
    BigInt entropyInt = BigInt.zero;
    for (final word in words.reversed) {
      entropyInt = (entropyInt * n) + BigInt.from(wordsList.getWordIdx(word));
    }

    /// Convert the BigInt to bytes and return the result
    return BigintUtils.toBytes(entropyInt);
  }
}

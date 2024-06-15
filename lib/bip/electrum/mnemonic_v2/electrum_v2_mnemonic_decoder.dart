import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A class for decoding Electrum V2 mnemonics, extending the MnemonicDecoderBase class.
class ElectrumV2MnemonicDecoder extends MnemonicDecoderBase {
  final ElectrumV2MnemonicTypes? mnemonicType;

  /// Constructs an Electrum V2 mnemonic decoder with optional parameters.
  ///
  /// The decoder is used to decode Electrum V2 mnemonics. It accepts an optional [mnemonicType] parameter
  /// to specify the type of Electrum V2 mnemonic, and an optional [language] parameter to specify the language
  /// for mnemonic decoding (default: English).
  ///
  /// [mnemonicType]: The type of Electrum V2 mnemonic (optional).
  /// [language]: The language used for mnemonic decoding (default: English).
  ElectrumV2MnemonicDecoder({
    this.mnemonicType,
    ElectrumV2Languages? language,
  }) : super(
          language: language,
          wordsListFinder: Bip39WordsListFinder(),
          wordsListGetter: Bip39WordsListGetter(),
        );

  /// Decodes an Electrum V2 mnemonic string into entropy bytes.
  ///
  /// This method takes an Electrum V2 mnemonic string as input and decodes it into entropy bytes. It performs several checks
  /// to ensure the validity of the mnemonic, including verifying the word count, checking if the mnemonic is valid for the specified
  /// mnemonic type, and detecting the language if it was not specified during construction.
  ///
  /// [mnemonic]: The Electrum V2 mnemonic to decode into entropy bytes.
  /// Returns a List<int> containing the decoded entropy bytes.
  @override
  List<int> decode(String mnemonic) {
    /// Parse the mnemonic string
    final mnemonicObj = ElectrumV2Mnemonic.fromString(mnemonic);
    final wCount = mnemonicObj.wordsCount();

    /// Check if the word count matches a valid Electrum V2 word count
    try {
      ElectrumV2MnemonicConst.mnemonicWordNum
          .firstWhere((element) => element.value == wCount);
    } on StateError {
      throw ArgumentException('Mnemonic words count is not valid ($wCount)');
    }

    /// Check the validity of the mnemonic for the specified mnemonic type
    if (!ElectrumV2MnemonicUtils.isValidMnemonic(mnemonicObj, mnemonicType)) {
      throw const ArgumentException('Invalid mnemonic');
    }

    /// Get the list of words from the mnemonic
    final words = mnemonicObj.toList();

    /// Detect the language if it was not specified during construction
    final wordsList = findLanguage(mnemonicObj).item1;

    /// Decode the words into entropy as a BigInt
    final n = BigInt.from(wordsList.length());
    BigInt entropyInt = BigInt.zero;
    for (final word in words.reversed) {
      entropyInt = (entropyInt * n) + BigInt.from(wordsList.getWordIdx(word));
    }

    /// Convert the BigInt to bytes and return the result
    return BigintUtils.toBytes(entropyInt,
        length: BigintUtils.orderLen(entropyInt));
  }
}

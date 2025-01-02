import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// BIP39 (Bitcoin Improvement Proposal 39) mnemonic decoder class.
///
/// The [Bip39MnemonicDecoder] class is responsible for decoding a BIP39 mnemonic
/// phrase into its original binary entropy form. It extends the abstract
/// [MnemonicDecoderBase] class and provides an implementation specific to BIP39.
///
/// To use this class, create an instance with the desired [language] and then
/// call the [decode] method with a BIP39 mnemonic phrase as input. It returns
/// the decoded binary entropy as a [List<int>].
///
/// Example usage:
///
/// ```dart
/// final mnemonic = Bip39Mnemonic.fromString("your BIP39 mnemonic phrase here");
/// final decoder = Bip39MnemonicDecoder(Bip39Languages.english);
/// final entropy = decoder.decode(mnemonic.toStr());
/// ```
class Bip39MnemonicDecoder extends MnemonicDecoderBase {
  /// Constructor for [Bip39MnemonicDecoder] class.
  ///
  /// Creates an instance of the [Bip39MnemonicDecoder] class with an optional
  /// [language] parameter, which specifies the language used for BIP39 mnemonics.
  /// If no [language] is provided, it defaults to [Bip39Languages.english].
  ///
  /// The constructor initializes the decoder with the appropriate [language],
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final decoder = Bip39MnemonicDecoder(Bip39Languages.spanish);
  /// final entropy = decoder.decode("your BIP39 mnemonic phrase here");
  /// ```
  ///
  /// Parameters:
  /// - [language]: The language for BIP39 mnemonics)
  Bip39MnemonicDecoder([Bip39Languages? language])
      : super(
            language: language,
            wordsListFinder: Bip39WordsListFinder(),
            wordsListGetter: Bip39WordsListGetter());

  /// Decode a BIP39 mnemonic phrase to obtain the entropy bytes.
  ///
  /// This method takes a BIP39 [mnemonic] phrase, decodes it into binary form,
  /// and returns the corresponding entropy bytes as a [List<int>].
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP39 mnemonic phrase to decode.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final decoder = Bip39MnemonicDecoder();
  /// final entropy = decoder.decode("your BIP39 mnemonic phrase here");
  /// ```
  ///
  /// Returns:
  /// A [List<int>] containing the decoded entropy bytes.
  @override
  List<int> decode(String mnemonic) {
    final mnemonicBinStr = _decodeAndVerifyBinaryStr(mnemonic);
    return _entropyBytesFromBinaryStr(mnemonicBinStr);
  }

  /// Decode a BIP39 mnemonic phrase to obtain the entropy bytes with checksum.
  ///
  /// This method is similar to [decode], but it ensures that the mnemonic bit length is a multiple
  /// of 8 by zero-padding. It then returns the corresponding entropy bytes as a [List<int>].
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP39 mnemonic phrase to decode.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final decoder = Bip39MnemonicDecoder();
  /// final entropy = decoder.decodeWithChecksum("your BIP39 mnemonic phrase here");
  /// ```
  ///
  /// Returns:
  /// A [List<int>] containing the decoded entropy bytes with zero-padding.
  List<int> decodeWithChecksum(String mnemonic) {
    final mnemonicBinStr = _decodeAndVerifyBinaryStr(mnemonic);
    final mnemonicBitLen = mnemonicBinStr.length;
    final padBitLen = mnemonicBitLen % 8 == 0
        ? mnemonicBitLen
        : mnemonicBitLen + (8 - mnemonicBitLen % 8);
    return BytesUtils.fromBinary(mnemonicBinStr,
        zeroPadByteLen: padBitLen ~/ 4);
  }

  /// decode and verify mnemonic
  String _decodeAndVerifyBinaryStr(String mnemonic) {
    final mnemonicObj = Bip39Mnemonic.fromString(mnemonic);
    final wCount = mnemonicObj.wordsCount();
    try {
      Bip39MnemonicConst.mnemonicWordNum
          .firstWhere((element) => element.value == wCount);
    } on StateError {
      throw ArgumentException('Mnemonic words count is not valid ($wCount)');
    }
    final wordsList = findLanguage(mnemonicObj).item1;
    final mnemonicBinStr = mnemonicToBinaryStr(mnemonicObj, wordsList);
    final checksumBinStr = mnemonicBinStr
        .substring(mnemonicBinStr.length - _getChecksumLen(mnemonicBinStr));
    final checksumBinStrGot = _computeChecksumBinaryStr(mnemonicBinStr);
    if (checksumBinStr != checksumBinStrGot) {
      throw MnemonicException(
          'Invalid checksum (expected $checksumBinStr, got $checksumBinStrGot)');
    }

    return mnemonicBinStr;
  }

  /// compute checksum
  String _computeChecksumBinaryStr(String mnemonicBinStr) {
    final entropyBytes = _entropyBytesFromBinaryStr(mnemonicBinStr);
    final entropyHashBinStr = BytesUtils.toBinary(
        QuickCrypto.sha256Hash(entropyBytes),
        zeroPadBitLen: QuickCrypto.sha256DigestSize * 8);
    return entropyHashBinStr.substring(0, _getChecksumLen(mnemonicBinStr));
  }

  /// entropy from binary
  List<int> _entropyBytesFromBinaryStr(String mnemonicBinStr) {
    final checksumLen = _getChecksumLen(mnemonicBinStr);
    final entropyBinStr =
        mnemonicBinStr.substring(0, mnemonicBinStr.length - checksumLen);

    final re =
        BytesUtils.fromBinary(entropyBinStr, zeroPadByteLen: checksumLen * 8);
    return re;
  }

  /// mnemonic to binary
  String mnemonicToBinaryStr(Mnemonic mnemonic, MnemonicWordsList wordsList) {
    final mnemonicBinStr = mnemonic.toList().map((word) {
      final wordIdx = wordsList.getWordIdx(word);
      return BigintUtils.toBinary(
          BigInt.from(wordIdx), Bip39MnemonicConst.wordBitLen);
    }).join();
    return mnemonicBinStr;
  }

  /// checksum length
  int _getChecksumLen(String mnemonicBinStr) {
    return mnemonicBinStr.length ~/ 33;
  }
}

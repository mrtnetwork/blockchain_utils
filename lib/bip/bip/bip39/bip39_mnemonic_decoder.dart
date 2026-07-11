import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_decoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_ex.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// BIP39 (Bitcoin Improvement Proposal 39) mnemonic decoder class.
class Bip39MnemonicDecoder extends MnemonicDecoderBase<Bip39Languages> {
  /// Constructor for [Bip39MnemonicDecoder] class.
  ///
  /// Parameters:
  /// - [language]: The language for BIP39 mnemonics)
  ///
  Bip39MnemonicDecoder([Bip39Languages? language])
    : super(
        language: language,
        wordsListFinder: Bip39WordsListFinder(Bip39Languages.values),
        wordsListGetter: Bip39WordsListGetter(),
      );

  /// Decode a BIP39 mnemonic phrase to obtain the entropy bytes.
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP39 mnemonic phrase to decode.
  ///
  @override
  List<int> decode(String mnemonic) {
    final mnemonicBinStr = _decodeAndVerifyBinaryStr(mnemonic);
    return _entropyBytesFromBinaryStr(mnemonicBinStr);
  }

  /// Decode a BIP39 mnemonic phrase to obtain the entropy bytes with checksum.
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP39 mnemonic phrase to decode.
  ///
  List<int> decodeWithChecksum(String mnemonic) {
    final mnemonicBinStr = _decodeAndVerifyBinaryStr(mnemonic);
    final mnemonicBitLen = mnemonicBinStr.length;
    final padBitLen =
        mnemonicBitLen % 8 == 0
            ? mnemonicBitLen
            : mnemonicBitLen + (8 - mnemonicBitLen % 8);
    return BytesUtils.fromBinary(
      mnemonicBinStr,
      zeroPadByteLen: padBitLen ~/ 4,
    );
  }

  /// decode and verify mnemonic
  String _decodeAndVerifyBinaryStr(String mnemonic) {
    final mnemonicObj = Bip39Mnemonic.fromString(mnemonic);
    final wCount = mnemonicObj.wordsCount();
    Bip39WordsNum.values.firstWhere(
      (element) => element.value == wCount,
      orElse:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "decode",
                name: "mnemonic",
                reason: "Invalid mnemonic length.",
              ),
    );
    final wordsList = findLanguage(mnemonicObj).$1;
    final mnemonicBinStr = mnemonicToBinaryStr(mnemonicObj, wordsList);
    final checksumBinStr = mnemonicBinStr.substring(
      mnemonicBinStr.length - _getChecksumLen(mnemonicBinStr),
    );
    final checksumBinStrGot = _computeChecksumBinaryStr(mnemonicBinStr);
    if (checksumBinStr != checksumBinStrGot) {
      throw MnemonicException.invalidChecksum;
    }

    return mnemonicBinStr;
  }

  /// compute checksum
  String _computeChecksumBinaryStr(String mnemonicBinStr) {
    final entropyBytes = _entropyBytesFromBinaryStr(mnemonicBinStr);
    final entropyHashBinStr = BytesUtils.toBinary(
      QuickCrypto.sha256Hash(entropyBytes),
      zeroPadBitLen: QuickCrypto.sha256DigestSize * 8,
    );
    return entropyHashBinStr.substring(0, _getChecksumLen(mnemonicBinStr));
  }

  /// entropy from binary
  List<int> _entropyBytesFromBinaryStr(String mnemonicBinStr) {
    final checksumLen = _getChecksumLen(mnemonicBinStr);
    final entropyBinStr = mnemonicBinStr.substring(
      0,
      mnemonicBinStr.length - checksumLen,
    );

    final re = BytesUtils.fromBinary(
      entropyBinStr,
      zeroPadByteLen: checksumLen * 8,
    );
    return re;
  }

  /// mnemonic to binary
  String mnemonicToBinaryStr(Mnemonic mnemonic, MnemonicWordsList wordsList) {
    final mnemonicBinStr =
        mnemonic.toList().map((word) {
          final wordIdx = wordsList.getWordIdx(word);
          return BigintUtils.toBinary(
            BigInt.from(wordIdx),
            zeroPadBitLen: Bip39MnemonicConst.wordBitLen,
          );
        }).join();
    return mnemonicBinStr;
  }

  /// checksum length
  int _getChecksumLen(String mnemonicBinStr) {
    return mnemonicBinStr.length ~/ 33;
  }
}

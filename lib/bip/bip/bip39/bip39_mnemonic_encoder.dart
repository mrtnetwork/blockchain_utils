import 'package:blockchain_utils/bip/bip/bip39/bip39_entropy_generator.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// BIP39 Mnemonic Encoder for generating mnemonic phrases.
class Bip39MnemonicEncoder extends MnemonicEncoderBase {
  /// Create a new instance of the BIP39 Mnemonic Encoder.
  ///
  /// Parameters:
  /// - [language]: The language used for generating the mnemonic phrase.
  ///
  Bip39MnemonicEncoder([Bip39Languages language = Bip39Languages.english])
    : super(language, Bip39WordsListGetter());

  /// Encode the provided entropy bytes into a BIP39 mnemonic phrase.
  ///
  /// Parameters:
  /// - [entropyBytes]: The entropy bytes to encode into a mnemonic phrase.
  ///
  @override
  Bip39Mnemonic encode(List<int> entropyBytes) {
    entropyBytes = entropyBytes.asImmutableBytes;
    final entropyByteLen = entropyBytes.length;
    if (!Bip39EntropyGenerator.isValidEntropyByteLen(entropyByteLen)) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        name: "entropyBytes",
        reason: "Invalid entropy length.",
      );
    }

    final entropyBinStr = BytesUtils.toBinary(
      entropyBytes,
      zeroPadBitLen: entropyByteLen * 8,
    );
    final entropyHash = QuickCrypto.sha256Hash(entropyBytes);
    final entropyHashBinStr = BytesUtils.toBinary(
      entropyHash,
      zeroPadBitLen: QuickCrypto.sha256DigestSize * 8,
    );
    final mnemonicBinStr =
        entropyBinStr + entropyHashBinStr.substring(0, entropyByteLen ~/ 4);
    final mnemonic = <String>[];
    for (
      var i = 0;
      i < mnemonicBinStr.length;
      i += Bip39MnemonicConst.wordBitLen
    ) {
      final wordBinStr = mnemonicBinStr.substring(
        i,
        i + Bip39MnemonicConst.wordBitLen,
      );

      final wordIdx = int.parse(wordBinStr, radix: 2);
      mnemonic.add(wordsList.getWordAtIdx(wordIdx));
    }

    return Bip39Mnemonic.fromList(mnemonic);
  }
}

import 'package:blockchain_utils/bip/bip/bip39/bip39_entropy_generator.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// BIP39 Mnemonic Encoder for generating mnemonic phrases.
///
/// This class is responsible for encoding entropy bytes into a BIP39 mnemonic phrase.
/// It implements the [MnemonicEncoderBase] abstract class.
///
/// Example usage:
///
/// ```dart
/// final entropy = List<int>.from([/* your entropy bytes here */]);
/// final encoder = Bip39MnemonicEncoder(Bip39Languages.english);
/// final mnemonic = encoder.encode(entropy);
/// print("Generated BIP39 mnemonic phrase: $mnemonic");
/// ```
class Bip39MnemonicEncoder extends MnemonicEncoderBase {
  /// Create a new instance of the BIP39 Mnemonic Encoder.
  ///
  /// Parameters:
  /// - [language]: The language used for generating the mnemonic phrase.
  Bip39MnemonicEncoder([Bip39Languages language = Bip39Languages.english])
      : super(language, Bip39WordsListGetter());

  /// Encode the provided entropy bytes into a BIP39 mnemonic phrase.
  ///
  /// Parameters:
  /// - [entropyBytes]: The entropy bytes to encode into a mnemonic phrase.
  ///
  /// Returns:
  /// A BIP39 mnemonic phrase representing the given entropy.
  @override
  Bip39Mnemonic encode(List<int> entropyBytes) {
    final entropyByteLen = entropyBytes.length;
    if (!Bip39EntropyGenerator.isValidEntropyByteLen(entropyByteLen)) {
      throw ArgumentException(
          'Entropy byte length ($entropyByteLen) is not valid');
    }

    final entropyBinStr =
        BytesUtils.toBinary(entropyBytes, zeroPadBitLen: entropyByteLen * 8);
    final entropyHash = QuickCrypto.sha256Hash(entropyBytes);
    final entropyHashBinStr = BytesUtils.toBinary(entropyHash,
        zeroPadBitLen: QuickCrypto.sha256DigestSize * 8);
    final mnemonicBinStr =
        entropyBinStr + entropyHashBinStr.substring(0, entropyByteLen ~/ 4);
    final mnemonic = <String>[];
    for (var i = 0;
        i < mnemonicBinStr.length;
        i += Bip39MnemonicConst.wordBitLen) {
      final wordBinStr =
          mnemonicBinStr.substring(i, i + Bip39MnemonicConst.wordBitLen);

      final wordIdx = int.parse(wordBinStr, radix: 2);
      mnemonic.add(wordsList.getWordAtIdx(wordIdx));
    }

    return Bip39Mnemonic.fromList(mnemonic);
  }
}

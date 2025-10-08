import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';
import 'ton_entropy_generator.dart';
import 'ton_mnemonic_language.dart';

/// The TonMnemonicEncoder class extends MnemonicEncoderBase to provide functionality
/// for encoding entropy bytes into a BIP-39 mnemonic phrase, specifically tailored for
/// the TON (The Open Network) blockchain.
class TonMnemonicEncoder extends MnemonicEncoderBase {
  /// Constructor initializes the encoder with a specified language for the mnemonic.
  /// Defaults to English if no language is specified.
  TonMnemonicEncoder(
      [TonMnemonicLanguages language = TonMnemonicLanguages.english])
      : super(language, Bip39WordsListGetter());

  /// Overrides the encode method to convert entropy bytes into a BIP-39 mnemonic phrase.
  @override
  Bip39Mnemonic encode(List<int> entropyBytes) {
    /// Validates the length of the entropy bytes.
    final entropyByteLen = entropyBytes.length;
    if (!TonMnemonicEntropyGenerator.isValidEntropyByteLen(entropyByteLen)) {
      throw MnemonicException(
          'Entropy byte length ($entropyByteLen) is not valid');
    }

    /// Converts entropy bytes to a binary string with zero padding.
    final entropyBinStr =
        BytesUtils.toBinary(entropyBytes, zeroPadBitLen: entropyByteLen * 8);

    /// Converts the binary string to a list of mnemonic words.
    final List<String> mnemonic = [];
    for (int i = 0;
        i < entropyBinStr.length;
        i += Bip39MnemonicConst.wordBitLen) {
      if (i + Bip39MnemonicConst.wordBitLen > entropyBinStr.length) break;
      final wordBinStr =
          entropyBinStr.substring(i, i + Bip39MnemonicConst.wordBitLen);
      final wordIdx = int.parse(wordBinStr, radix: 2);
      mnemonic.add(wordsList.getWordAtIdx(wordIdx));
    }

    /// Returns a BIP-39 mnemonic phrase constructed from the list of words.
    return Bip39Mnemonic.fromList(mnemonic);
  }
}

import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_entropy_generator.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

/// Algorand mnemonic encoder class.
///
/// This class is responsible for encoding binary data into a human-readable mnemonic phrase
/// following the Algorand mnemonic standard. It extends the [MnemonicEncoderBase] class.
class AlgorandMnemonicEncoder extends MnemonicEncoderBase {
  /// Creates an instance of the AlgorandMnemonicEncoder.
  ///
  /// The [language] parameter specifies the language used for the mnemonic words, with English as the default.
  AlgorandMnemonicEncoder(
      [AlgorandLanguages language = AlgorandLanguages.english])
      : super(language, Bip39WordsListGetter());

  /// Encode bytes to a mnemonic phrase following the Algorand standard.
  @override
  Mnemonic encode(List<int> entropyBytes) {
    entropyBytes = entropyBytes.asImmutableBytes;
    final entropyByteLen = entropyBytes.length;
    if (!AlgorandEntropyGenerator.isValidEntropyByteLen(entropyByteLen)) {
      throw ArgumentException(
          'Entropy byte length ($entropyByteLen) is not valid');
    }

    final chksumWordIdx =
        AlgorandMnemonicUtils.computeChecksumWordIndex(entropyBytes);
    final wordIndexes = AlgorandMnemonicUtils.convertBits(entropyBytes, 8, 11);
    assert(wordIndexes != null);
    return AlgorandMnemonic.fromList(
        _indexesToWords([...wordIndexes!, chksumWordIdx]));
  }

  /// find words at index
  List<String> _indexesToWords(List<int> indexes) {
    return [for (final idx in indexes) wordsList.getWordAtIdx(idx)];
  }
}

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A class for encoding data into Electrum V2 mnemonics, extending the MnemonicEncoderBase class.
class ElectrumV2MnemonicEncoder extends MnemonicEncoderBase {
  final ElectrumV2MnemonicTypes mnemonicType;

  /// Constructs an Electrum V2 mnemonic encoder with a specified mnemonic type and optional language.
  ///
  /// The encoder is used to encode data into Electrum V2 mnemonics. It requires a [mnemonicType] to determine the
  /// type of Electrum V2 mnemonic to use, and an optional [language] parameter to specify the language for encoding (default: English).
  ///
  /// [mnemonicType]: The type of Electrum V2 mnemonic to use for encoding.
  /// [language]: The language used for mnemonic encoding (default: English).
  ElectrumV2MnemonicEncoder(this.mnemonicType,
      {ElectrumV2Languages language = ElectrumV2Languages.english})
      : super(language, Bip39WordsListGetter());

  /// Encodes entropy bytes into an Electrum V2 mnemonic.
  ///
  /// This method takes a List<int> of entropy bytes as input and encodes them into an Electrum V2 mnemonic. It ensures
  /// that the entropy bits are sufficient for generating a valid mnemonic, and that the resulting mnemonic is valid for
  /// the specified mnemonic type. The method performs the encoding by repeatedly dividing the entropy value by the number
  /// of words in the word list and adding the corresponding words to the mnemonic.
  ///
  /// [entropyBytes]: The entropy bytes to be encoded into an Electrum V2 mnemonic.
  /// Returns an Electrum V2 mnemonic representing the encoded data.
  @override
  Mnemonic encode(List<int> entropyBytes) {
    final entropyInt = BigintUtils.fromBytes(entropyBytes);

    /// Check if the entropy bits are sufficient for a valid mnemonic
    if (!ElectrumV2EntropyGenerator.areEntropyBitsEnough(entropyInt)) {
      throw const ArgumentException(
          'Entropy bit length is not enough for generating a valid mnemonic');
    }

    final n = BigInt.from(wordsList.length());
    final mnemonic = <String>[];
    BigInt tempEntropy = entropyInt;

    /// Generate the mnemonic words from the entropy bytes
    while (tempEntropy > BigInt.zero) {
      final wordIdx = tempEntropy % n;
      tempEntropy ~/= n;
      mnemonic.add(wordsList.getWordAtIdx(wordIdx.toInt()));
    }

    /// Create an Electrum V2 mnemonic object from the generated words
    final mnemonicObj = ElectrumV2Mnemonic.fromList(mnemonic);

    /// Check if the resulting mnemonic is valid for the specified mnemonic type
    if (!ElectrumV2MnemonicUtils.isValidMnemonic(mnemonicObj, mnemonicType)) {
      throw const ArgumentException(
          'Entropy bytes are not suitable for generating a valid mnemonic');
    }
    return mnemonicObj;
  }
}

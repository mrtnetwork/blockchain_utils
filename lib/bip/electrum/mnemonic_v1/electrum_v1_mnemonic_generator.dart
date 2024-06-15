import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_encoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Constants related to Electrum V1 mnemonic generation, mapping the number of words to entropy length.
class ElectrumV1MnemonicGeneratorConst {
  /// Mapping of the number of words to their corresponding entropy length.
  static Map<ElectrumV1WordsNum, int> wordsNumToEntropyLen = {
    ElectrumV1WordsNum.wordsNum12: ElectrumV1EntropyBitLen.bitLen128,
  };
}

/// A class for generating Electrum V1 mnemonics, providing the ability to encode data into mnemonics.
class ElectrumV1MnemonicGenerator {
  final ElectrumV1MnemonicEncoder encoder;

  /// Constructs an ElectrumV1MnemonicGenerator with an optional language specification.
  ///
  /// The generator uses an `ElectrumV1MnemonicEncoder` with the specified language (default: English)
  /// for encoding data into Electrum V1 mnemonics.
  ///
  /// [language]: The language to use for mnemonic encoding (default: English).
  ElectrumV1MnemonicGenerator(
      [ElectrumV1Languages language = ElectrumV1Languages.english])
      : encoder = ElectrumV1MnemonicEncoder(language);

  /// Generates an Electrum V1 mnemonic with a specified number of words.
  ///
  /// This method takes the desired number of words as input and generates an Electrum V1 mnemonic with
  /// the corresponding entropy length. It validates the words number and then uses an `ElectrumV1EntropyGenerator`
  /// to generate the required entropy bytes. Finally, it creates an Electrum V1 mnemonic from the generated entropy.
  ///
  /// Throws an ArgumentException if the words number is invalid.
  ///
  /// Returns an Electrum V1 mnemonic with the specified number of words.
  ///
  /// [wordsNum]: The number of words to use in the mnemonic.
  Mnemonic fromWordsNumber(int wordsNum) {
    /// Validate the provided words number against predefined values
    try {
      ElectrumV1WordsNum.values
          .firstWhere((element) => element.value == wordsNum);
    } on StateError {
      throw const ArgumentException("invalid words num");
    }
    final wNum = ElectrumV1WordsNum.values
        .firstWhere((element) => element.value == wordsNum);

    /// Get the corresponding entropy bit length
    int entropyBitLen =
        ElectrumV1MnemonicGeneratorConst.wordsNumToEntropyLen[wNum]!;

    /// Generate entropy bytes with the specified bit length
    final entropyBytes =
        ElectrumV1EntropyGenerator(bitLength: entropyBitLen).generate();

    /// Create an Electrum V1 mnemonic from the generated entropy bytes
    return fromEntropy(entropyBytes);
  }

  /// Generates an Electrum V1 mnemonic from a List<int> of entropy bytes.
  ///
  /// This method takes a List<int> of entropy bytes as input and encodes it into an Electrum V1 mnemonic
  /// using the associated `ElectrumV1MnemonicEncoder`. It essentially converts the raw entropy into a human-readable
  /// mnemonic for secure storage and recovery of data.
  ///
  /// Returns an Electrum V1 mnemonic generated from the provided entropy bytes.
  ///
  /// [entropyBytes]: The List<int> of entropy bytes to use for mnemonic generation.
  Mnemonic fromEntropy(List<int> entropyBytes) {
    return encoder.encode(entropyBytes);
  }
}

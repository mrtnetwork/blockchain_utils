import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_encoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';

/// A class for generating Electrum V1 mnemonics, providing the ability to encode data into mnemonics.
class ElectrumV1MnemonicGenerator {
  final ElectrumV1MnemonicEncoder encoder;

  /// Constructs an ElectrumV1MnemonicGenerator with an optional language specification.
  ///
  /// [language]: The language to use for mnemonic encoding (default: English).
  ///
  ElectrumV1MnemonicGenerator([
    ElectrumV1Languages language = ElectrumV1Languages.english,
  ]) : encoder = ElectrumV1MnemonicEncoder(language);

  /// Generates an Electrum V1 mnemonic with a specified number of words.
  ///
  /// - [wordsNum]: The number of words to use in the mnemonic.
  ///
  Mnemonic fromWordsNumber({
    ElectrumV1WordsNum wordsNum = ElectrumV1WordsNum.wordsNum12,
  }) {
    /// Generate entropy bytes with the specified bit length
    final entropyBytes = ElectrumV1EntropyGenerator();

    /// Create an Electrum V1 mnemonic from the generated entropy bytes
    return fromEntropy(entropyBytes.generate());
  }

  /// Generates an Electrum V1 mnemonic from entropy bytes.
  ///
  /// -[entropyBytes]: The `List<int>` of entropy bytes to use for mnemonic generation.
  ///
  Mnemonic fromEntropy(List<int> entropyBytes) {
    return encoder.encode(entropyBytes);
  }
}

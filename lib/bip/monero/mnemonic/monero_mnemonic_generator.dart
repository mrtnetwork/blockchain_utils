import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'monero_entropy_generator.dart';
import 'monero_mnemonic.dart';
import 'monero_mnemonic_encoder.dart';

/// A class responsible for generating Monero mnemonics from entropy.
class MoneroMnemonicGenerator {
  final MoneroMnemonicEncoder encoder;

  /// Constructs a MoneroMnemonicGenerator with an optional language parameter.
  ///
  /// [language]: The Monero language to use for encoding. Defaults to English.
  MoneroMnemonicGenerator([MoneroLanguages language = MoneroLanguages.english])
    : encoder = MoneroMnemonicEncoder(language);

  /// Generates a Monero mnemonic of a specified word count.
  ///
  /// -[wordsNum]: The desired word count for the mnemonic.
  ///
  Mnemonic fromWordsNumber(MoneroWordsNum wordsNum) {
    final int entropyBitLen = wordsNum.bitlen;
    final List<int> entropyBytes =
        MoneroEntropyGenerator(entropyBitLen).generate();

    return wordsNum == MoneroWordsNum.wordsNum13 ||
            wordsNum == MoneroWordsNum.wordsNum25
        ? fromEntropyWithChecksum(entropyBytes)
        : fromEntropyNoChecksum(entropyBytes);
  }

  /// Generates a Monero mnemonic from entropy without a checksum.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  ///
  Mnemonic fromEntropyNoChecksum(List<int> entropyBytes) {
    return encoder.encodeNoChecksum(entropyBytes);
  }

  /// Generates a Monero mnemonic from entropy with a checksum.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  ///
  Mnemonic fromEntropyWithChecksum(List<int> entropyBytes) {
    return encoder.encodeWithChecksum(entropyBytes);
  }
}

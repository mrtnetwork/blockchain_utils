import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'monero_entropy_generator.dart';
import 'monero_mnemonic.dart';
import 'monero_mnemonic_encoder.dart';

/// A class containing constants related to Monero mnemonic generation.
///
/// This class holds a set of constant mappings that associate the number of words
/// in a Monero mnemonic with the corresponding entropy bit length. It is used to
/// determine the entropy bit length based on the word count.
class MoneroMnemonicGeneratorConst {
  /// Maps MoneroWordsNum to their corresponding entropy bit length.
  static final Map<MoneroWordsNum, int> wordsNumToEntropyLen = {
    MoneroWordsNum.wordsNum12: MoneroEntropyBitLen.bitLen128,
    MoneroWordsNum.wordsNum13: MoneroEntropyBitLen.bitLen128,
    MoneroWordsNum.wordsNum24: MoneroEntropyBitLen.bitLen256,
    MoneroWordsNum.wordsNum25: MoneroEntropyBitLen.bitLen256,
  };
}

/// A class responsible for generating Monero mnemonics from entropy.
///
/// This class simplifies the process of generating Monero mnemonics from entropy.
/// It uses an instance of `MoneroMnemonicEncoder` to encode entropy into mnemonics,
/// allowing you to choose whether to include a checksum in the generated mnemonic.
class MoneroMnemonicGenerator {
  final MoneroMnemonicEncoder encoder;

  /// Constructs a MoneroMnemonicGenerator with an optional language parameter.
  ///
  /// [language]: The Monero language to use for encoding. Defaults to English.
  MoneroMnemonicGenerator([MoneroLanguages language = MoneroLanguages.english])
      : encoder = MoneroMnemonicEncoder(language);

  /// Generates a Monero mnemonic of a specified word count.
  ///
  /// This method generates a Monero mnemonic with the given word count. It validates
  /// the word count's validity and generates entropy based on the corresponding
  /// entropy bit length. The choice of including a checksum depends on the word count.
  ///
  /// Throws an Exception if the word count is not valid.
  ///
  /// [wordsNum]: The desired word count for the mnemonic.
  Mnemonic fromWordsNumber(MoneroWordsNum wordsNum) {
    if (!MoneroMnemonicConst.mnemonicWordNum.contains(wordsNum)) {
      throw ArgumentException(
          'Words number for mnemonic ($wordsNum) is not valid');
    }

    final int entropyBitLen =
        MoneroMnemonicGeneratorConst.wordsNumToEntropyLen[wordsNum]!;
    final List<int> entropyBytes =
        MoneroEntropyGenerator(entropyBitLen).generate();

    return wordsNum == MoneroWordsNum.wordsNum13 ||
            wordsNum == MoneroWordsNum.wordsNum25
        ? fromEntropyWithChecksum(entropyBytes)
        : fromEntropyNoChecksum(entropyBytes);
  }

  /// Generates a Monero mnemonic from entropy without a checksum.
  ///
  /// This method generates a Monero mnemonic from the provided entropy bytes without
  /// including a checksum.
  ///
  /// [entropyBytes]: The entropy bytes to encode.
  Mnemonic fromEntropyNoChecksum(List<int> entropyBytes) {
    return encoder.encodeNoChecksum(entropyBytes);
  }

  /// Generates a Monero mnemonic from entropy with a checksum.
  ///
  /// This method generates a Monero mnemonic from the provided entropy bytes with an
  /// included checksum for enhanced error detection and correction.
  ///
  /// [entropyBytes]: The entropy bytes to encode.
  Mnemonic fromEntropyWithChecksum(List<int> entropyBytes) {
    return encoder.encodeWithChecksum(entropyBytes);
  }
}

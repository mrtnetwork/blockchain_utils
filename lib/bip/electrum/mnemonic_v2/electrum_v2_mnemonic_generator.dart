import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_encoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Constants related to Electrum V2 mnemonic generation.
class ElectrumV2MnemonicGeneratorConst {
  /// Maps the number of words to the corresponding entropy bit length for Electrum V2 mnemonics.
  static const wordsNumToEntropyLen = {
    ElectrumV2WordsNum.wordsNum12: ElectrumV2EntropyBitLen.bitLen132,
    ElectrumV2WordsNum.wordsNum24: ElectrumV2EntropyBitLen.bitLen264,
  };

  /// The maximum number of attempts for generating an Electrum V2 mnemonic.
  static const maxAttempts = 1000000;
}

/// A class for generating Electrum V2 mnemonics, using a specified mnemonic type and language.
class ElectrumV2MnemonicGenerator {
  final ElectrumV2MnemonicEncoder encoder;

  /// Constructs an Electrum V2 mnemonic generator with a specified mnemonic type and optional language.
  ///
  /// The generator is used to create Electrum V2 mnemonics. It requires a [mnemonicType] to determine the type of Electrum V2
  /// mnemonic to generate, and an optional [language] parameter to specify the language for encoding (default: English).
  ///
  /// [mnemonicType]: The type of Electrum V2 mnemonic to generate.
  /// [language]: The language used for mnemonic generation (default: English
  ElectrumV2MnemonicGenerator(ElectrumV2MnemonicTypes mnemonicType,
      {ElectrumV2Languages language = ElectrumV2Languages.english})
      : encoder = ElectrumV2MnemonicEncoder(mnemonicType, language: language);

  /// Creates an Electrum V2 mnemonic from a specified number of words.
  ///
  /// This method generates an Electrum V2 mnemonic with the given [wordsNum] by first determining the entropy length in bits
  /// based on the words number. It then generates the entropy bytes and constructs an Electrum V2 mnemonic from the generated entropy.
  ///
  /// [wordsNum]: The number of words to use for the Electrum V2 mnemonic.
  /// Returns an Electrum V2 mnemonic with the specified number of words.
  Mnemonic fromWordsNumber(int wordsNum) {
    try {
      ElectrumV2MnemonicConst.mnemonicWordNum
          .firstWhere((element) => element.value == wordsNum);
    } on StateError {
      throw ArgumentException(
          'Words number for mnemonic ($wordsNum) is not valid');
    }
    final wNum = ElectrumV2WordsNum.values
        .firstWhere((element) => element.value == wordsNum);
    // Get entropy length in bit from words number
    final entropyBitLen =
        ElectrumV2MnemonicGeneratorConst.wordsNumToEntropyLen[wNum]!;
    // Generate entropy
    final entropyBytes = ElectrumV2EntropyGenerator(entropyBitLen).generate();

    return fromEntropy(entropyBytes);
  }

  /// Creates an Electrum V2 mnemonic from the provided entropy bytes.
  ///
  /// This method generates an Electrum V2 mnemonic from the given [entropyBytes]. It first checks if the entropy bits are sufficient
  /// for generating a valid mnemonic. If so, it iterates through attempts to find a valid mnemonic by adding a small integer to
  /// the entropy and encoding it. It continues attempts until a valid mnemonic is found or the maximum number of attempts is reached.
  ///
  /// [entropyBytes]: The entropy bytes used to generate the Electrum V2 mnemonic.
  /// Returns an Electrum V2 mnemonic generated from the entropy bytes.
  Mnemonic fromEntropy(List<int> entropyBytes) {
    final entropyInt = BigintUtils.fromBytes(entropyBytes);

    if (ElectrumV2EntropyGenerator.areEntropyBitsEnough(entropyInt)) {
      for (int i = 0; i < ElectrumV2MnemonicGeneratorConst.maxAttempts; i++) {
        final newEntropyInt = entropyInt + BigInt.from(i);
        final toBytes = BigintUtils.toBytes(newEntropyInt,
            length: BigintUtils.orderLen(newEntropyInt));

        try {
          final encode = encoder.encode(toBytes);

          return encode;
        } on ArgumentException {
          /// Continue to the next attempt if encoding fails
          continue;
        }
      }
    }

    throw const ArgumentException('Unable to generate a valid mnemonic');
  }
}

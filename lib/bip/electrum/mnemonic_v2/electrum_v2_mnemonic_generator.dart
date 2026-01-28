import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';

import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_encoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Constants related to Electrum V2 mnemonic generation.
class ElectrumV2MnemonicGeneratorConst {
  /// The maximum number of attempts for generating an Electrum V2 mnemonic.
  static const maxAttempts = 1000000;
}

/// A class for generating Electrum V2 mnemonics, using a specified mnemonic type and language.
class ElectrumV2MnemonicGenerator {
  final ElectrumV2MnemonicEncoder encoder;

  /// Constructs an Electrum V2 mnemonic generator with a specified mnemonic type and optional language.
  ///
  /// - [mnemonicType]: The type of Electrum V2 mnemonic to generate.
  /// - [language]: The language used for mnemonic generation (default: English)
  ///
  ElectrumV2MnemonicGenerator(
    ElectrumV2MnemonicTypes mnemonicType, {
    ElectrumV2Languages language = ElectrumV2Languages.english,
  }) : encoder = ElectrumV2MnemonicEncoder(mnemonicType, language: language);

  /// Creates an Electrum V2 mnemonic from a specified number of words.
  ///
  /// - [wordsNum]: The number of words to use for the Electrum V2 mnemonic.
  ///
  Mnemonic fromWordsNumber(ElectrumV2WordsNum wordsNum) {
    // Generate entropy
    final entropyBytes = ElectrumV2EntropyGenerator(wordsNum.bitlen).generate();

    return fromEntropy(entropyBytes);
  }

  /// Creates an Electrum V2 mnemonic from the provided entropy bytes.
  ///
  /// - [entropyBytes]: The entropy bytes used to generate the Electrum V2 mnemonic.
  ///
  Mnemonic fromEntropy(List<int> entropyBytes) {
    final entropyInt = BigintUtils.fromBytes(entropyBytes);

    if (ElectrumV2EntropyGenerator.areEntropyBitsEnough(entropyInt)) {
      for (int i = 0; i < ElectrumV2MnemonicGeneratorConst.maxAttempts; i++) {
        final newEntropyInt = entropyInt + BigInt.from(i);
        final toBytes = BigintUtils.toBytes(newEntropyInt);

        try {
          final encode = encoder.encode(toBytes);

          return encode;
        } on ArgumentException {
          /// Continue to the next attempt if encoding fails
          continue;
        }
      }
    }

    throw const MnemonicException('Unable to generate a valid mnemonic.');
  }
}

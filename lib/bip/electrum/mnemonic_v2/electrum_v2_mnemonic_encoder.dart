import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// A class for encoding data into Electrum V2 mnemonics, extending the MnemonicEncoderBase class.
class ElectrumV2MnemonicEncoder extends MnemonicEncoderBase {
  final ElectrumV2MnemonicTypes mnemonicType;

  /// Constructs an Electrum V2 mnemonic encoder with a specified mnemonic type and optional language.
  ///
  /// -[mnemonicType]: The type of Electrum V2 mnemonic to use for encoding.
  /// - [language]: The language used for mnemonic encoding (default: English).
  ///
  ElectrumV2MnemonicEncoder(
    this.mnemonicType, {
    ElectrumV2Languages language = ElectrumV2Languages.english,
  }) : super(language, Bip39WordsListGetter());

  /// Encodes entropy bytes into an Electrum V2 mnemonic.
  ///
  /// -[entropyBytes]: The entropy bytes to be encoded into an Electrum V2 mnemonic.
  ///
  @override
  Mnemonic encode(List<int> entropyBytes) {
    final entropyInt = BigintUtils.fromBytes(entropyBytes);

    /// Check if the entropy bits are sufficient for a valid mnemonic
    if (!ElectrumV2EntropyGenerator.areEntropyBitsEnough(entropyInt)) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        name: "entropyBytes",
        reason: "Invalid entropy length",
      );
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
      throw ArgumentException.invalidOperationArguments(
        "encode",
        name: "entropyBytes",
        reason: "Invalid entropy.",
      );
    }
    return mnemonicObj;
  }
}

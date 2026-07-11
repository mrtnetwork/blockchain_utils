import 'dart:typed_data';

import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// A class for encoding data into Electrum V1 mnemonics, extending the MnemonicEncoderBase class.
class ElectrumV1MnemonicEncoder extends MnemonicEncoderBase {
  /// Constructs an ElectrumV1MnemonicEncoder with an optional language specification.
  ///
  /// [language]: The language to use for encoding (default: English).
  ///
  ElectrumV1MnemonicEncoder([
    ElectrumV1Languages language = ElectrumV1Languages.english,
  ]) : super(language, ElectrumV1WordsListGetter());

  /// Encodes entropy bytes into an Electrum V1 mnemonic.
  ///
  /// -[entropyBytes]: The entropy bytes to encode.
  ///
  @override
  Mnemonic encode(List<int> entropyBytes) {
    // Check entropy length
    final int entropyByteLen = entropyBytes.length;
    if (!ElectrumV1EntropyGenerator.isValidEntropyByteLength(entropyByteLen)) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        name: "entropyBytes",
        reason: "Invalid entropy bytes length.",
      );
    }

    // Build mnemonic
    final List<String> mnemonic = [];
    for (int i = 0; i < entropyBytes.length ~/ 4; i++) {
      mnemonic.addAll(
        MnemonicUtils.bytesChunkToWords(
          entropyBytes.sublist(i * 4, (i * 4) + 4),
          wordsList,
          endian: Endian.big,
        ),
      );
    }

    return ElectrumV1Mnemonic.fromList(mnemonic);
  }
}

import 'dart:typed_data';

import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_entropy_generator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_utils.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_encoder_base.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// A class for encoding data into Electrum V1 mnemonics, extending the MnemonicEncoderBase class.
class ElectrumV1MnemonicEncoder extends MnemonicEncoderBase {
  /// Constructs an ElectrumV1MnemonicEncoder with an optional language specification.
  ///
  /// The encoder is initialized with the specified language (default: English) and an Electrum V1
  /// words list getter to retrieve the list of valid words for the selected language.
  ///
  /// [language]: The language to use for encoding (default: English).
  ElectrumV1MnemonicEncoder(
      [ElectrumV1Languages language = ElectrumV1Languages.english])
      : super(language, ElectrumV1WordsListGetter());

  /// Encodes a `List<int>` of entropy bytes into an Electrum V1 mnemonic.
  ///
  /// This method takes a `List<int>` of entropy bytes as input and generates an Electrum V1 mnemonic by
  /// dividing the entropy into 4-byte chunks and converting each chunk into a list of mnemonic words.
  /// It checks the validity of the entropy byte length and throws an ArgumentException if it's not valid.
  ///
  /// Returns an Electrum V1 mnemonic representing the encoded data.
  ///
  /// [entropyBytes]: The `List<int>` of entropy bytes to encode.
  @override
  Mnemonic encode(List<int> entropyBytes) {
    // Check entropy length
    final int entropyByteLen = entropyBytes.length;
    if (!ElectrumV1EntropyGenerator.isValidEntropyByteLength(entropyByteLen)) {
      throw ArgumentException(
          'Entropy byte length ($entropyByteLen) is not valid');
    }

    // Build mnemonic
    final List<String> mnemonic = [];
    for (int i = 0; i < entropyBytes.length ~/ 4; i++) {
      mnemonic.addAll(MnemonicUtils.bytesChunkToWords(
          entropyBytes.sublist(i * 4, (i * 4) + 4), wordsList,
          endian: Endian.big));
    }

    return ElectrumV1Mnemonic.fromList(mnemonic);
  }
}

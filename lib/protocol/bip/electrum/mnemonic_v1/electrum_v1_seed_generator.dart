import 'dart:core';

import 'package:blockchain_utils/protocol/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_decoder.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';

import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Constants related to the generation of Electrum V1 seeds.
class ElectrumV1SeedGeneratorConst {
  /// The number of hash iterations to derive an Electrum V1 seed
  static const int hashIterationNum = 100000;
}

/// A class for generating Electrum V1 seeds from mnemonics.
class ElectrumV1SeedGenerator with SecretState {
  final Mnemonic mnemonic;
  final ElectrumV1Languages? language;

  /// Constructs an Electrum V1 seed generator from a mnemonic and an optional language specification.
  ///
  /// The generator uses the provided mnemonic to derive an Electrum V1 seed. An optional language specification
  /// can be provided (default: English) for mnemonic decoding.
  ///
  /// [mnemonic]: The Electrum V1 mnemonic used to generate the seed.
  /// [language]: The language used for mnemonic decoding (default: English).
  ElectrumV1SeedGenerator(
    this.mnemonic, [
    this.language = ElectrumV1Languages.english,
  ]);

  /// Generates the Electrum V1 seed.
  /// Returns the generated Electrum V1 seed as [SecretBytes].
  SecretBytes generate() {
    final decode = ElectrumV1MnemonicDecoder(language).decode(mnemonic);
    return decode.useValue((plaintext) {
      return SecretBytes.take(_generateSeed(plaintext));
    }, zero: true);
  }

  /// Generates an Electrum V1 seed from entropy bytes using a specified number of hash iterations.
  ///
  /// [entropyBytes]: The entropy bytes used as the initial source for seed generation.
  static List<int> _generateSeed(List<int> entropyBytes) {
    final entropy = StringUtils.encode(BytesUtils.toHexString(entropyBytes));
    try {
      List<int> h = entropy;
      for (int i = 0; i < ElectrumV1SeedGeneratorConst.hashIterationNum; i++) {
        h = QuickCrypto.sha256Hash([...h, ...entropy]);
      }
      return h;
    } finally {
      entropy.forceZero();
    }
  }

  @override
  void dispose() {
    mnemonic.dispose();
  }
}

import 'dart:core';

import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_decoder.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Constants related to the generation of Electrum V1 seeds.
class ElectrumV1SeedGeneratorConst {
  /// The number of hash iterations to derive an Electrum V1 seed
  static const int hashIterationNum = 100000;
}

/// A class for generating Electrum V1 seeds from mnemonics.
class ElectrumV1SeedGenerator {
  final List<int> _seed;

  /// Constructs an Electrum V1 seed generator from a mnemonic and an optional language specification.
  ///
  /// The generator uses the provided mnemonic to derive an Electrum V1 seed. An optional language specification
  /// can be provided (default: English) for mnemonic decoding.
  ///
  /// [mnemonic]: The Electrum V1 mnemonic used to generate the seed.
  /// [language]: The language used for mnemonic decoding (default: English).
  ElectrumV1SeedGenerator(String mnemonic,
      [ElectrumV1Languages? language = ElectrumV1Languages.english])
      : _seed =
            _generateSeed(ElectrumV1MnemonicDecoder(language).decode(mnemonic));

  /// Generates the Electrum V1 seed.
  ///
  /// Returns the generated Electrum V1 seed as a List<int>.
  List<int> generate() {
    return List<int>.from(_seed);
  }

  /// Generates an Electrum V1 seed from entropy bytes using a specified number of hash iterations.
  ///
  /// [entropyBytes]: The entropy bytes used as the initial source for seed generation.
  static List<int> _generateSeed(List<int> entropyBytes) {
    final entropy = StringUtils.encode(BytesUtils.toHexString(entropyBytes));
    List<int> h = entropy;
    for (int i = 0; i < ElectrumV1SeedGeneratorConst.hashIterationNum; i++) {
      h = QuickCrypto.sha256Hash(List<int>.from([...h, ...entropy]));
    }
    return h;
  }
}

import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic_decoder.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/encoding/cbor/types/bytes.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class responsible for generating Cardano Byron Legacy seeds from mnemonics.
class CardanoByronLegacySeedGenerator {
  final Mnemonic mnemonic;
  final Bip39Languages? language;

  /// Constructor to create a seed generator for Cardano Byron Legacy wallets.
  ///
  /// It takes a mnemonic string as input, decodes it, and generates the seed.
  ///
  /// Parameters:
  /// - `mnemonic`: The mnemonic string used to generate the seed.
  /// - `language`: An optional parameter to specify the language used in the mnemonic.
  CardanoByronLegacySeedGenerator(this.mnemonic, {this.language});

  /// Generates and returns the Cardano Byron Legacy seed as [SecretBytes].
  SecretBytes generate() {
    final decodedMnemonic = Bip39MnemonicDecoder(language).decode(mnemonic);
    final cborData = CborBytesValue(decodedMnemonic).encode();
    final hash = QuickCrypto.blake2b256Hash(cborData);
    try {
      return SecretBytes.take(hash);
    } finally {
      decodedMnemonic.zero();
      cborData.forceZero();
    }
  }
}

import 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class responsible for generating a seed from Monero mnemonic entropy.
class MoneroSeedGenerator with SecretState {
  final SecretBytes entropyBytes;

  /// Constructs a MoneroSeedGenerator with a Monero mnemonic and an optional language.
  ///
  /// -[mnemonic]: The Monero mnemonic from which to derive the seed.
  /// -[language]: The Monero language used for decoding. Defaults to null, allowing the decoder
  /// to use the default language.
  MoneroSeedGenerator(Mnemonic mnemonic, [MoneroLanguages? language])
    : entropyBytes = MoneroMnemonicDecoder(language).decode(mnemonic);

  /// Generates a seed from the decoded entropy bytes.
  SecretBytes generate() => entropyBytes.cloneBytes();

  @override
  void dispose() {
    entropyBytes.zero();
  }
}

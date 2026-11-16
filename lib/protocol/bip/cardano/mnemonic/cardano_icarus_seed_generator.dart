import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic_decoder.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class responsible for generating Cardano Icarus seeds from mnemonics.
class CardanoIcarusSeedGenerator with SecretState {
  final Mnemonic mnemonic;
  final Bip39Languages? language;

  /// Constructor to create a seed generator for Cardano Icarus wallets.
  ///
  /// It takes a mnemonic string as input, decodes it into entropy bytes.
  ///
  /// Parameters:
  /// - `mnemonic`: The mnemonic string used to generate the seed.
  /// - `language`: An optional parameter to specify the language used in the mnemonic.
  CardanoIcarusSeedGenerator(this.mnemonic, {this.language});
  SecretBytes generate() {
    return Bip39MnemonicDecoder(language).decode(mnemonic);
  }

  @override
  void dispose() {
    mnemonic.dispose();
  }
}

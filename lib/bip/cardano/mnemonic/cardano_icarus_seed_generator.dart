import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_decoder.dart';

/// A class responsible for generating Cardano Icarus seeds from mnemonics.
class CardanoIcarusSeedGenerator {
  final List<int> _entropyBytes;

  /// Constructor to create a seed generator for Cardano Icarus wallets.
  ///
  /// It takes a mnemonic string as input, decodes it into entropy bytes.
  ///
  /// Parameters:
  /// - `mnemonic`: The mnemonic string used to generate the seed.
  /// - `language`: An optional parameter to specify the language used in the mnemonic.
  CardanoIcarusSeedGenerator(
    String mnemonic, {
    Bip39Languages? language,
  }) : _entropyBytes = Bip39MnemonicDecoder(language).decode(mnemonic);

  /// Generates and returns the Cardano Icarus seed as a `List<int>`.
  List<int> generate() {
    return List<int>.from(_entropyBytes);
  }
}

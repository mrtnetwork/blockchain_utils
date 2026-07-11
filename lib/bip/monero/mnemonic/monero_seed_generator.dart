import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// A class responsible for generating a seed from Monero mnemonic entropy.
class MoneroSeedGenerator {
  final List<int> _entropyBytes;

  /// Constructs a MoneroSeedGenerator with a Monero mnemonic and an optional language.
  ///
  /// -[mnemonic]: The Monero mnemonic from which to derive the seed.
  /// -[language]: The Monero language used for decoding. Defaults to null, allowing the decoder
  /// to use the default language.
  MoneroSeedGenerator(Mnemonic mnemonic, [MoneroLanguages? language])
    : _entropyBytes = MoneroMnemonicDecoder(language).decode(mnemonic.toStr());

  /// Generates a seed from the decoded entropy bytes.
  List<int> generate() => _entropyBytes.clone();
}

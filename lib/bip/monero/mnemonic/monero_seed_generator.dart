import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';

/// A class responsible for generating a seed from Monero mnemonic entropy.
///
/// This class takes a Monero mnemonic, decodes it to obtain the associated entropy bytes,
/// and allows you to generate a seed from that entropy. The generated seed can be used
/// as a cryptographic seed in Monero-related operations.
class MoneroSeedGenerator {
  final List<int> _entropyBytes;

  /// Constructs a MoneroSeedGenerator with a Monero mnemonic and an optional language.
  ///
  /// [mnemonic]: The Monero mnemonic from which to derive the seed.
  /// [language]: The Monero language used for decoding. Defaults to null, allowing the decoder
  /// to use the default language.
  MoneroSeedGenerator(Mnemonic mnemonic, [MoneroLanguages? language])
      : _entropyBytes =
            MoneroMnemonicDecoder(language).decode(mnemonic.toStr());

  /// Generates a seed from the decoded entropy bytes.
  ///
  /// This method generates a seed from the decoded entropy bytes obtained from the
  /// Monero mnemonic. The seed can be used for cryptographic purposes.
  ///
  /// Returns a `List<int>` containing the generated seed.
  List<int> generate() => List<int>.from(_entropyBytes);
}

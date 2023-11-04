import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// A class for generating cryptographically secure random entropy.
///
/// The [EntropyGenerator] class is designed to produce random entropy with a specified bit length.
/// It uses a cryptographically secure random number generator to generate the entropy.
class EntropyGenerator {
  final int bitlen;

  /// Creates an [EntropyGenerator] instance with the desired bit length.
  ///
  /// The [bitlen] parameter specifies the length of the entropy in bits.
  EntropyGenerator(this.bitlen);

  /// Generates and returns random entropy as a [List<int>].
  ///
  /// The length of the generated entropy is determined by the [bitlen] parameter, and it is converted
  /// to bytes (rounded up to the nearest byte).
  List<int> generate() {
    return QuickCrypto.generateRandom(bitlen ~/ 8);
  }
}

import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// A class for generating cryptographically secure random entropy.
class EntropyGenerator {
  final int bitlen;

  /// Creates an [EntropyGenerator] instance with the desired bit length.
  EntropyGenerator(this.bitlen);

  /// Generates and returns random entropy.
  List<int> generate() {
    return QuickCrypto.generateRandom(bitlen ~/ 8);
  }
}

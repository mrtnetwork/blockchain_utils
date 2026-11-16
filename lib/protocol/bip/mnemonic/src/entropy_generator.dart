import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class for generating cryptographically secure random entropy.
class EntropyGenerator {
  final int bitlen;

  /// Creates an [EntropyGenerator] instance with the desired bit length.
  EntropyGenerator(this.bitlen);

  /// Generates and returns random entropy.
  BuBytes generate() {
    return QuickCrypto.generateRandom(length: bitlen ~/ 8);
  }
}

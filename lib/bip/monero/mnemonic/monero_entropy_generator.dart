import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// Contains constants representing different bit lengths for generating entropy.
class MoneroEntropyBitLen {
  /// Bit length of 128 for generating entropy.
  static const int bitLen128 = 128;

  /// Bit length of 128 for generating entropy.
  static const int bitLen256 = 256;
}

/// Constants for generating entropy with specific bit lengths for Monero-based cryptocurrencies.
class MoneroEntropyGeneratorConst {
  /// List of supported entropy bit lengths for Monero wallets.
  static final List<int> entropyBitLen = [
    MoneroEntropyBitLen.bitLen128,
    MoneroEntropyBitLen.bitLen256
  ];
}

/// Generates entropy for Monero-based cryptocurrency wallets with the specified bit length.
class MoneroEntropyGenerator extends EntropyGenerator {
  /// Creates a Monero entropy generator with the given bit length.
  MoneroEntropyGenerator(int bitLen) : super(bitLen) {
    if (!isValidEntropyBitLen(bitLen)) {
      throw ArgumentException('Entropy bit length is not valid ($bitLen)');
    }
  }

  /// Checks if the provided bit length is valid for generating entropy.
  static bool isValidEntropyBitLen(int bitLen) {
    return MoneroEntropyGeneratorConst.entropyBitLen.contains(bitLen);
  }

  /// Checks if the provided byte length is valid for generating entropy.
  static bool isValidEntropyByteLen(int byteLen) {
    return isValidEntropyBitLen(byteLen * 8);
  }
}

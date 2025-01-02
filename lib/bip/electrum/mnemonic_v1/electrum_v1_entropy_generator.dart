import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// Constants related to Electrum V1 entropy bit lengths.
class ElectrumV1EntropyBitLen {
  /// Bit length for 128 bits of entropy.
  static const int bitLen128 = 128;
}

/// Constants related to Electrum V1 entropy generation, specifying available bit lengths.
class ElectrumV1EntropyGeneratorConst {
  /// List of entropy bit lengths, including bitLen128.
  static List<int> entropyBitLen = [
    ElectrumV1EntropyBitLen.bitLen128,
  ];
}

/// A class representing an entropy generator for Electrum V1, extending the EntropyGenerator base class.
class ElectrumV1EntropyGenerator extends EntropyGenerator {
  /// List of valid bit lengths for Electrum V1 entropy generation.
  static const List<int> validBitLengths = [ElectrumV1EntropyBitLen.bitLen128];

  /// Constructs an ElectrumV1EntropyGenerator with a specified bit length.
  /// If the bit length is not valid, it raises an error.
  ElectrumV1EntropyGenerator(
      {int bitLength = ElectrumV1EntropyBitLen.bitLen128})
      : super(bitLength) {
    if (!isValidEntropyBitLength(bitLength)) {
      throw ArgumentException('Entropy bit length is not valid ($bitLength)');
    }
  }

  /// Checks if a given bit length is valid for Electrum V1 entropy generation.
  static bool isValidEntropyBitLength(int bitLength) {
    return validBitLengths.contains(bitLength);
  }

  /// Checks if a given byte length is valid for Electrum V1 entropy generation.
  static bool isValidEntropyByteLength(int byteLength) {
    return isValidEntropyBitLength(byteLength * 8);
  }
}

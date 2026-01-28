import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';

class ElectrumV1EntropyBitLen {
  /// Bit length for 128 bits of entropy.
  static const int bitLen128 = 128;
}

/// A class representing an entropy generator for Electrum V1, extending the EntropyGenerator base class.
class ElectrumV1EntropyGenerator extends EntropyGenerator {
  /// Constructs an ElectrumV1EntropyGenerator with a specified bit length.
  /// If the bit length is not valid, it raises an error.
  ElectrumV1EntropyGenerator() : super(ElectrumV1EntropyBitLen.bitLen128);

  /// Checks if a given byte length is valid for Electrum V1 entropy generation.
  static bool isValidEntropyByteLength(int byteLength) {
    return byteLength * 8 == ElectrumV1EntropyBitLen.bitLen128;
  }
}

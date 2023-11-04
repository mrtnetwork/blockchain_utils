import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';

/// Enumerates different bit lengths for Algorand entropy generation.
enum AlgorandEntropyBitLen {
  bitLen256(256);

  final int value;

  /// Creates an instance of AlgorandEntropyBitLen with the specified value.
  const AlgorandEntropyBitLen(this.value);
}

/// Constants related to Algorand entropy generation.
class AlgorandEntropyGeneratorConst {
  /// List of supported bit lengths for Algorand entropy generation.
  static const entropyBitLen = [AlgorandEntropyBitLen.bitLen256];
}

/// Generates entropy for Algorand based on the specified bit length.
class AlgorandEntropyGenerator extends EntropyGenerator {
  /// Creates an instance of AlgorandEntropyGenerator with an optional bit length.
  ///
  /// The [bitLen] parameter determines the length of the generated entropy in bits.
  AlgorandEntropyGenerator(
      [AlgorandEntropyBitLen bitLen = AlgorandEntropyBitLen.bitLen256])
      : super(bitLen.value);

  /// Checks if a given bit length is valid for Algorand entropy generation.
  ///
  /// Returns `true` if the bit length is valid, otherwise `false`.
  static bool isValidEntropyBitLen(int bitLen) {
    try {
      AlgorandEntropyGeneratorConst.entropyBitLen
          .firstWhere((element) => element.value == bitLen);
    } on StateError {
      return false;
    }
    return true;
  }

  /// Checks if a given byte length is valid for Algorand entropy generation.
  ///
  /// Returns `true` if the byte length is valid, otherwise `false`.
  static bool isValidEntropyByteLen(int byteLen) {
    return isValidEntropyBitLen(byteLen * 8);
  }
}

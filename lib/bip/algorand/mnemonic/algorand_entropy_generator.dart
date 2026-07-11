import 'package:blockchain_utils/bip/mnemonic/src/entropy_generator.dart';

/// Enumerates different bit lengths for Algorand entropy generation.
class AlgorandEntropyBitLen {
  /// Bit length 256 for Algorand entropy.
  static const AlgorandEntropyBitLen bitLen256 = AlgorandEntropyBitLen._(256);

  final int bitlen;

  /// Creates an instance of AlgorandEntropyBitLen with the specified value.
  const AlgorandEntropyBitLen._(this.bitlen);
  static const List<AlgorandEntropyBitLen> values = [bitLen256];
}

/// Generates entropy for Algorand based on the specified bit length.
class AlgorandEntropyGenerator extends EntropyGenerator {
  /// Creates an instance of AlgorandEntropyGenerator with an optional bit length.
  ///
  /// The [bitLen] parameter determines the length of the generated entropy in bits.
  AlgorandEntropyGenerator([
    AlgorandEntropyBitLen bitLen = AlgorandEntropyBitLen.bitLen256,
  ]) : super(bitLen.bitlen);

  /// Checks if a given bit length is valid for Algorand entropy generation.
  ///
  /// Returns `true` if the bit length is valid, otherwise `false`.
  static bool isValidEntropyBitLen(int bitLen) {
    return AlgorandEntropyBitLen.values.any((e) => e.bitlen == bitLen);
  }

  /// Checks if a given byte length is valid for Algorand entropy generation.
  ///
  /// Returns `true` if the byte length is valid, otherwise `false`.
  static bool isValidEntropyByteLen(int byteLen) {
    return isValidEntropyBitLen(byteLen * 8);
  }
}

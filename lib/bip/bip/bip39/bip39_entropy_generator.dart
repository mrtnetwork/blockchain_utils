import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';

/// Enum representing the bit lengths for BIP39 entropy values.
///
/// This enum defines the possible bit lengths for BIP39 entropy values. It
/// provides constants for bit lengths of 128, 160, 192, 224, and 256 bits.
enum Bip39EntropyBitLen {
  /// 128 bit
  bitLen128(128),

  /// 160 bit
  bitLen160(160),

  /// 192 bit
  bitLen192(192),

  /// 224 bit
  bitLen224(224),

  /// 256 bit
  bitLen256(256);

  final int value;

  /// Constructor to associate a bit length value with each enum constant.
  const Bip39EntropyBitLen(this.value);
}

/// Constants related to BIP39 entropy generation.
///
/// This class defines constants related to BIP39 entropy generation, including
/// a list of valid BIP39 entropy bit lengths.
class Bip39EntropyGeneratorConst {
  /// list of valid BIP39 entropy bit lengths
  static final List<Bip39EntropyBitLen> entropyBitLen = [
    Bip39EntropyBitLen.bitLen128,
    Bip39EntropyBitLen.bitLen160,
    Bip39EntropyBitLen.bitLen192,
    Bip39EntropyBitLen.bitLen224,
    Bip39EntropyBitLen.bitLen256,
  ];
}

/// BIP39 entropy generator class.
///
/// This class extends the `EntropyGenerator` class and is specific to BIP39
/// entropy generation. It allows for creating an instance with a specific
/// BIP39 entropy bit length.
class Bip39EntropyGenerator extends EntropyGenerator {
  /// Create a BIP39 entropy generator with the specified bit length.
  ///
  /// - [bitLen]: The bit length of the BIP39 entropy to generate.
  Bip39EntropyGenerator(Bip39EntropyBitLen bitLen) : super(bitLen.value);

  /// Check if a given bit length is a valid BIP39 entropy bit length.
  ///
  /// - [bitLen]: The bit length to check for validity.
  /// - Returns: `true` if the bit length is valid, `false` otherwise.
  static bool isValidEntropyBitLen(int bitLen) {
    try {
      Bip39EntropyBitLen.values
          .firstWhere((element) => element.value == bitLen);
      return true;
    } on StateError {
      return false;
    }
  }

  /// Check if a given byte length is a valid BIP39 entropy byte length.
  ///
  /// - [byteLen]: The byte length to check for validity.
  /// - Returns: `true` if the byte length is valid, `false` otherwise.
  static bool isValidEntropyByteLen(int byteLen) {
    return isValidEntropyBitLen(byteLen * 8);
  }
}

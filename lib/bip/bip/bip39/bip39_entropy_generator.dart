import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';

/// Enum representing the bit lengths for BIP39 entropy values.
class Bip39EntropyBitLen {
  // Constants representing each entropy bit length

  /// 128 bit
  static const bitLen128 = Bip39EntropyBitLen._(128);

  /// 160 bit
  static const bitLen160 = Bip39EntropyBitLen._(160);

  /// 192 bit
  static const bitLen192 = Bip39EntropyBitLen._(192);

  /// 224 bit
  static const bitLen224 = Bip39EntropyBitLen._(224);

  /// 256 bit
  static const bitLen256 = Bip39EntropyBitLen._(256);

  // The bit length value associated with each instance
  final int value;

  /// Constructor to associate a bit length value with each instance.
  const Bip39EntropyBitLen._(this.value);

  static const List<Bip39EntropyBitLen> values = [
    bitLen128,
    bitLen160,
    bitLen192,
    bitLen224,
    bitLen256,
  ];
}

/// BIP39 entropy generator class.
class Bip39EntropyGenerator extends EntropyGenerator {
  /// Create a BIP39 entropy generator with the specified bit length.
  ///
  /// - [bitLen]: The bit length of the BIP39 entropy to generate.
  ///
  Bip39EntropyGenerator(Bip39EntropyBitLen bitLen) : super(bitLen.value);

  /// Check if a given bit length is a valid BIP39 entropy bit length.
  ///
  /// - [bitLen]: The bit length to check for validity.
  ///
  static bool isValidEntropyBitLen(int bitLen) {
    try {
      Bip39EntropyBitLen.values.firstWhere(
        (element) => element.value == bitLen,
      );
      return true;
    } on StateError {
      return false;
    }
  }

  /// Check if a given byte length is a valid BIP39 entropy byte length.
  ///
  /// - [byteLen]: The byte length to check for validity.
  ///
  static bool isValidEntropyByteLen(int byteLen) {
    return isValidEntropyBitLen(byteLen * 8);
  }
}

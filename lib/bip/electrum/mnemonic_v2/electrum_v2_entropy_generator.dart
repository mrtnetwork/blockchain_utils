import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// Constants representing bit lengths for Electrum V2 entropy.
class ElectrumV2EntropyBitLen {
  /// Bit length for Electrum V2 entropy of 132 bits
  static const int bitLen132 = 132;

  /// Bit length for Electrum V2 entropy of 264 bits
  static const int bitLen264 = 264;
}

/// Constants related to the generation of Electrum V2 entropy.
class ElectrumV2EntropyGeneratorConst {
  /// List of supported bit lengths for Electrum V2 entropy
  static const List<int> entropyBitLen = [
    ElectrumV2EntropyBitLen.bitLen132,
    ElectrumV2EntropyBitLen.bitLen264,
  ];
}

/// A class for generating Electrum V2 entropy with specified bit lengths, extending the EntropyGenerator class.
class ElectrumV2EntropyGenerator extends EntropyGenerator {
  /// Constructs an Electrum V2 entropy generator with the given bit length.
  ///
  /// The generator ensures that the provided bit length is valid for Electrum V2 entropy.
  ///
  /// [bitLen]: The desired bit length for generating Electrum V2 entropy.
  ElectrumV2EntropyGenerator(int bitLen) : super(bitLen) {
    if (!isValidEntropyBitLen(bitLen)) {
      throw const ArgumentException('Entropy bit length is not valid');
    }
  }

  /// Checks if a given bit length is valid for Electrum V2 entropy generation.
  ///
  /// [bitLen]: The bit length to be checked.
  /// Returns true if the bit length is valid, otherwise false.
  static bool isValidEntropyBitLen(int bitLen) {
    for (int entropyBitLen in ElectrumV2EntropyGeneratorConst.entropyBitLen) {
      if (entropyBitLen - ElectrumV2MnemonicConst.wordBitLen <= bitLen &&
          bitLen <= entropyBitLen) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a given byte length is valid for Electrum V2 entropy generation.
  ///
  /// [byteLen]: The byte length to be checked.
  /// Returns true if the byte length is valid, otherwise false.
  static bool isValidEntropyByteLen(int byteLen) {
    return isValidEntropyBitLen(byteLen * 8);
  }

  /// Checks if the provided entropy bits are sufficient for Electrum V2 entropy generation.
  ///
  /// [entropy]: The entropy to be checked (as a BigInt).
  /// Returns true if the entropy bit length is valid, otherwise false.
  static bool areEntropyBitsEnough(BigInt entropy) {
    return isValidEntropyBitLen(entropy.bitLength);
  }
}

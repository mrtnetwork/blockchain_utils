import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Utility class for Algorand mnemonic related operations.
class AlgorandMnemonicUtils {
  /// Computes the checksum for the given [dataBytes] using SHA-512/256.
  ///
  /// The [dataBytes] parameter should be the data bytes for which the checksum
  /// needs to be computed. The method returns a [`List<int>`] containing the
  /// computed checksum.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final data = `List<int>`.from([1, 2, 3, 4, 5]);
  /// final checksum = AlgorandMnemonicUtils.computeChecksum(data);
  /// ```
  static List<int> computeChecksum(List<int> dataBytes) {
    return QuickCrypto.sha512256Hash(dataBytes)
        .sublist(0, AlgorandMnemonicConst.checksumByteLen);
  }

  /// Computes a checksum word index for the given [dataBytes].
  ///
  /// The [dataBytes] parameter represents the data bytes for which the checksum
  /// word index needs to be calculated. This method calculates the checksum,
  /// converts it from 8-bit to 11-bit representation, and returns the first
  /// element of the resulting list as the checksum word index.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final data = `List<int>`.from([1, 2, 3, 4, 5]);
  /// final checksumWordIndex = AlgorandMnemonicUtils.computeChecksumWordIndex(data);
  /// ```
  ///
  /// Note: The [dataBytes] should be the original data for which the checksum
  /// is being calculated, and the returned index corresponds to a word in the
  /// mnemonic word list.
  static int computeChecksumWordIndex(List<int> dataBytes) {
    final chksum = AlgorandMnemonicUtils.computeChecksum(dataBytes);
    final chksum11Bit = AlgorandMnemonicUtils.convertBits(chksum, 8, 11);

    /// Cannot be null by converting bytes from 8-bit to 11-bit
    assert(chksum11Bit != null);

    return chksum11Bit![0];
  }

  /// Perform bit conversion.
  /// The function takes the input data (list of integers or byte sequence) and converts every value from
  /// the specified number of bits to the specified one.
  /// It returns a list of integers where every number is less than 2^toBits.
  ///
  /// Args:
  ///   data (`List<int>`): Data to be converted
  ///   fromBits (int)  : Number of bits to start from
  ///   toBits (int)    : Number of bits to end with
  ///
  /// Returns:
  ///   `List<int>`: List of converted values, null in case of errors
  static List<int>? convertBits(List<int> data, int fromBits, int toBits) {
    final int maxOutVal = (1 << toBits) - 1;
    int acc = 0;
    int bits = 0;
    final List<int> ret = <int>[];

    for (final value in data) {
      if (value < 0 || (value >> fromBits) > 0) {
        return null;
      }
      acc |= value << bits;
      bits += fromBits;
      while (bits >= toBits) {
        ret.add(acc & maxOutVal);
        acc >>= toBits;
        bits -= toBits;
      }
    }

    if (bits != 0) {
      ret.add(acc & maxOutVal);
    }

    return ret;
  }
}

import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Utility class for Algorand mnemonic related operations.
class AlgorandMnemonicUtils {
  /// Computes the checksum for the given [dataBytes] using SHA-512/256.
  static List<int> computeChecksum(List<int> dataBytes) {
    return QuickCrypto.sha512256Hash(
      dataBytes,
    ).sublist(0, AlgorandMnemonicConst.checksumByteLen);
  }

  /// Computes a checksum word index for the given [dataBytes].
  static int computeChecksumWordIndex(List<int> dataBytes) {
    final chksum = AlgorandMnemonicUtils.computeChecksum(dataBytes);
    final chksum11Bit = AlgorandMnemonicUtils.convertBits(chksum, 8, 11);

    /// Cannot be null by converting bytes from 8-bit to 11-bit
    assert(chksum11Bit != null);

    return chksum11Bit![0];
  }

  /// Perform bit conversion.
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

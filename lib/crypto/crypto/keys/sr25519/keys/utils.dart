import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

/// Schnorrkel (sr25519) length constants.
class SchnorrkelKeyCost {
  static const int vrfProofLength = 64;
  static const int miniSecretLength = 32;
  static const int nonceLength = 32;
  static const int publickeyLength = 32;
  static const int secretKeyLength = 64;
  static const int keypairLength = 96;
  static const int signatureLength = 64;
  static const int vrfPreOutLength = 32;
  static const int signatureNonceLength = 64;
}

/// Schnorrkel (sr25519) scalar-encoding helpers.
class SchnorrKeyUtils {
  /// Divides a little-endian scalar by the cofactor (8), in place.
  static List<int> divideScalarByCofactor(List<int> s) {
    final int l = s.length - 1;
    int low = 0;
    for (int i = 0; i < s.length; i++) {
      final int r = s[l - i] & 0x07;
      s[l - i] >>= 3;
      s[l - i] += low;
      low = r << 5;
    }
    return s;
  }

  /// Whether [scalar] has RFC 8032 ed25519 clamping already applied.
  static bool isRawEd25519Clamped(List<int> scalar) {
    final b0 = scalar[0];
    final b31 = scalar[31];
    return (b0 & 0x07) == 0 && (b31 & 0xC0) == 0x40;
  }

  /// Multiplies a little-endian scalar by the cofactor (8), in place.
  static void multiplyScalarBytesByCofactor(List<int> scalar) {
    int high = 0;
    for (int i = 0; i < scalar.length; i++) {
      final int r = scalar[i] & 0xE0;
      scalar[i] <<= 3;
      scalar[i] += high;
      high = r >> 5;
    }
  }

  /// Returns [bytes] with its high bit cleared if it's already a
  /// canonical (fully-reduced, high-bit-clear) scalar encoding, else null.
  static List<int>? toCanonical(List<int> bytes) {
    final cloneBytes = bytes.clone();
    cloneBytes[31] &= 127;
    final bool highBitUnset = (bytes[31] >> 7) == 0;
    final bool isCanonical = BytesUtils.bytesEqual(
      cloneBytes,
      blockchainUtils.api.ed25519.scReduce(cloneBytes),
    );
    if (highBitUnset && isCanonical) return cloneBytes;
    return null;
  }
}

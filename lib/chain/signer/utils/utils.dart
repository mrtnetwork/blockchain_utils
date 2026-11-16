import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';

/// Signature-format validation helpers.
class CryptoSignatureUtils {
  /// Whether [signature] has a valid Schnorr signature shape (r, s in range).
  ///
  /// Accepts 64-byte (`r || s`) signatures; a trailing 65th byte (e.g. a
  /// recovery id) is ignored.
  static bool isValidSchnorrSignature(List<int> signature) {
    if (signature.length != CryptoSignerConst.schnorrSignatureLength &&
        signature.length != CryptoSignerConst.schnorrSignatureLength + 1) {
      return false;
    }

    try {
      Secp256k1Fp.fromBytes(signature.sublist(0, 32));
      Secp256k1Fr.fromBytes(signature.sublist(32, 64));
    } catch (_) {
      return false;
    }
    return true;
  }

  /// Whether [signature] is a well-formed Bitcoin DER-encoded ECDSA signature.
  ///
  /// Returns `false` for malformed encodings; never throws.
  /// Bounds below are safe: `5 + lenR < length` is checked before any
  /// `lenR`-relative index, and `lenS > 0` is checked before `s` indexes.
  static bool isValidBitcoinDERSignature(List<int> signature) {
    if (signature.length < 9 || signature.length > 73) {
      return false;
    }

    if (signature[0] != 0x30) {
      return false;
    }
    if (signature[1] > signature.length - 2) {
      return false;
    }
    int lenR = signature[3];
    if (5 + lenR >= signature.length) {
      return false;
    }

    int lenS = signature[5 + lenR];
    int total = lenR + lenS + 6;
    if (total != signature.length && total + 1 != signature.length) {
      return false;
    }

    // R and S must be positive (their first byte can't have the sign bit set).
    if (signature[4] & 0x80 != 0) {
      return false;
    }
    if (lenR > 1 && (signature[4] == 0x00) && (signature[5] & 0x80 == 0)) {
      return false;
    }
    if (signature[lenR + 4] != 0x02) return false;
    if (lenS == 0) return false;
    // Negative numbers are not allowed for S.
    if ((signature[lenR + 6] & 0x80) != 0) return false;
    // A leading null byte on S is only allowed when needed to keep S positive.
    if (lenS > 1 &&
        (signature[lenR + 6] == 0x00) &&
        (signature[lenR + 7] & 0x80 == 0)) {
      return false;
    }
    return true;
  }
}

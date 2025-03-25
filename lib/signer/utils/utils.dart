import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';

class CryptoSignatureUtils {
  static bool isValidSchnorrSignature(List<int> signature) {
    if (signature.length != CryptoSignerConst.schnoorSginatureLength &&
        signature.length != CryptoSignerConst.schnoorSginatureLength + 1) {
      return false;
    }

    final r = BigintUtils.fromBytes(signature.sublist(0, 32));

    final s = BigintUtils.fromBytes(signature.sublist(32, 64));
    if (r >= Curves.curveSecp256k1.p || s >= Curves.generatorSecp256k1.order!) {
      return false;
    }
    return true;
  }

  static bool isValidBitcoinDERSignature(List<int> signature) {
    if (signature.length < 9 || signature.length > 73) {
      return false;
    }

    if (signature[0] != 0x30) {
      return false;
    }
    if (signature[1] != signature.length - 3) {
      return false;
    }
    int lenR = signature[3];
    if (5 + lenR >= signature.length) {
      return false;
    }

    int lenS = signature[5 + lenR];
    if ((7 + lenR + lenS) != signature.length) {
      return false;
    }

    // Verify R and S are positive integers (first byte cannot be negative)
    if (signature[4] & 0x80 != 0) {
      return false;
    }
    if (lenR > 1 && (signature[4] == 0x00) && (signature[5] & 0x80 != 0)) {
      return false;
    }
    if (signature[lenR + 4] != 0x02) return false;
    if (lenS == 0) return false;
    // Negative numbers are not allowed for S.
    if ((signature[lenR + 6] & 0x80) != 0) return false;
    // Null bytes at the start of S are not allowed, unless S would otherwise be
    // interpreted as a negative number.
    if (lenS > 1 &&
        (signature[lenR + 6] == 0x00) &&
        (signature[lenR + 7] & 0x80 != 0)) {
      return false;
    }
    return true;
  }
}

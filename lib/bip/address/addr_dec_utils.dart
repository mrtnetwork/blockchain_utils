import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'exception/exception.dart';

/// Class for decode address utility functions.
class AddrDecUtils {
  /// Validate and remove prefix from an address.
  static List<int> validateAndRemovePrefixBytes(
    List<int> addr,
    List<int> prefix,
  ) {
    final prefixGot = addr.sublist(0, prefix.length);

    if (!BytesUtils.bytesEqual(prefix, prefixGot)) {
      throw AddressConverterException(
        'Invalid prefix (expected $prefix, got $prefixGot)',
      );
    }

    return addr.sublist(prefix.length);
  }

  /// Validate and remove prefix from an address.
  static String validateAndRemovePrefix(String addr, String prefix) {
    final prefixGot = addr.substring(0, prefix.length);

    if (prefix != prefixGot) {
      throw AddressConverterException(
          'Invalid prefix (expected $prefix, got $prefixGot)');
    }

    return addr.substring(prefix.length);
  }

  /// Validate address length.
  static void validateBytesLength(List<int> addr, int lenExp,
      {int? minLength}) {
    if ((minLength != null && addr.length < minLength) ||
        (minLength == null && addr.length != lenExp)) {
      throw AddressConverterException(
        'Invalid length (expected ${minLength ?? lenExp}, got ${addr.length})',
      );
    }
  }

  /// Validate address length.
  static void validateLength(
    String addr,
    int lenExp,
  ) {
    if (addr.length != lenExp) {
      throw AddressConverterException(
        'Invalid length (expected $lenExp, got ${addr.length})',
      );
    }
  }

  /// Validate address length.
  static void validatePubKey(
    List<int> pubKeyBytes,
    EllipticCurveTypes curveType,
  ) {
    try {
      IPublicKey.fromBytes(pubKeyBytes, curveType);
    } catch (e) {
      throw AddressConverterException(
          "Invalid $curveType public key (${BytesUtils.toHexString(pubKeyBytes)})");
    }
  }

  /// Validate address checksum.
  static void validateChecksum(
    List<int> payloadBytes,
    List<int> checksumBytesExp,
    List<int> Function(List<int>) checksumFct,
  ) {
    final checksumBytesGot = checksumFct(payloadBytes);

    if (!BytesUtils.bytesEqual(checksumBytesExp, checksumBytesGot)) {
      throw const AddressConverterException('Invalid checksum');
    }
  }

  /// Split address into two parts, considering the checksum at the end of it.
  static Tuple<List<int>, List<int>> splitPartsByChecksum(
    List<int> addrBytes,
    int checksumLen,
  ) {
    final checksumBytes = addrBytes.sublist(addrBytes.length - checksumLen);
    final payloadBytes = addrBytes.sublist(0, addrBytes.length - checksumLen);

    return Tuple(payloadBytes, checksumBytes);
  }
}

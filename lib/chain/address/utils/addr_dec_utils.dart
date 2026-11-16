import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

/// Class for decode address utility functions.
class AddrDecUtils {
  /// Validate and remove prefix from an address.
  static List<int> validateAndRemovePrefixBytes(
    List<int> addr,
    List<int> prefix,
  ) {
    if (addr.length < prefix.length) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address prefix.",
      );
    }

    final prefixGot = addr.sublist(0, prefix.length);

    if (!BytesUtils.bytesEqual(prefix, prefixGot)) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address prefix.",
      );
    }

    return addr.sublist(prefix.length);
  }

  /// Validate and remove prefix from an address.
  static String validateAndRemovePrefix(String addr, String prefix) {
    if (addr.length < prefix.length) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address prefix.",
      );
    }

    final prefixGot = addr.substring(0, prefix.length);

    if (prefix != prefixGot) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address prefix.",
      );
    }

    return addr.substring(prefix.length);
  }

  /// Validate address length.
  static void validateBytesLength(
    List<int> addr,
    int lenExp, {
    int? minLength,
  }) {
    if ((minLength != null && addr.length < minLength) ||
        (minLength == null && addr.length != lenExp)) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address length.",
      );
    }
  }

  /// Validate address key bytes length.
  static void validateAddressKeyBytesLength(
    List<int> addr,
    int lenExp, {
    int? minLength,
  }) {
    if ((minLength != null && addr.length < minLength) ||
        (minLength == null && addr.length != lenExp)) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address bytes length.",
      );
    }
  }

  /// Validate address length.
  static void validateLength(String addr, int lenExp) {
    if (addr.length != lenExp) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address length.",
      );
    }
  }

  /// Validate that bytes form a valid public key for the given curve.
  static void validatePubKey(List<int> pubKeyBytes, CryptoKeyType curveType) {
    try {
      IPublicKey.fromBytes(pubKeyBytes, curveType);
    } catch (_) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid ${curveType.name} public key.",
      );
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
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address checksum.",
      );
    }
  }

  /// Split address into two parts, considering the checksum at the end of it.
  ///
  /// Throws [AddressConverterException] if [addrBytes] is shorter than
  /// [checksumLen].
  static (List<int>, List<int>) splitPartsByChecksum(
    List<int> addrBytes,
    int checksumLen,
  ) {
    if (addrBytes.length < checksumLen) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address length.",
      );
    }
    final checksumBytes = addrBytes.sublist(addrBytes.length - checksumLen);
    final payloadBytes = addrBytes.sublist(0, addrBytes.length - checksumLen);

    return (payloadBytes, checksumBytes);
  }
}

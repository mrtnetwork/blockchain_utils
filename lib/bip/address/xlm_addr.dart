import 'package:blockchain_utils/base32/base32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';

import 'package:blockchain_utils/crypto/crypto/x_modem_crc/x_modem_crc.dart';
import 'exception/exception.dart';

import 'encoder.dart';

/// Enum representing different types of Stellar (XLM) addresses.
///
/// This enum defines two address types: "pubKey" and "privKey" with their respective values.
/// - "pubKey" is used for public account keys.
/// - "privKey" is used for private account keys.
///
/// Each enum value corresponds to an integer value, which is a bit shift left operation to calculate the actual value.
/// These values are used to determine the type of Stellar address.
///
/// Example usage:
/// ```
/// final addressType = XlmAddrTypes.pubKey;
/// final addressValue = addressType.value; // Returns 48 (6 << 3)
/// ```
class XlmAddrTypes {
  /// Public key address type.
  static const XlmAddrTypes pubKey = XlmAddrTypes._(6 << 3);

  /// Private key address type.
  static const XlmAddrTypes privKey = XlmAddrTypes._(18 << 3);

  final int value;

  static const List<XlmAddrTypes> values = [pubKey, privKey];

  /// Constructor for XlmAddrTypes enum values.
  const XlmAddrTypes._(this.value);
}

/// Constants related to Stellar (XLM) addresses.
///
/// This class contains constants used for handling Stellar addresses, including the checksum byte length.
class XlmAddrConst {
  /// The length in bytes of the checksum used in Stellar addresses.
  static const checksumByteLen = 2;
}

class _XlmAddrUtils {
  /// Stellar address utility class.

  static List<int> computeChecksum(List<int> payloadBytes) {
    // Compute checksum in Stellar format.
    return XModemCrc.quickDigest(payloadBytes).reversed.toList();
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Stellar (XLM) blockchain addresses.
class XlmAddrDecoder implements BlockchainAddressDecoder {
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Decode a Stellar (XLM) address and return the public key.
    ///
    /// This method decodes a Stellar address and extracts the public key part, returning it as a List<int>.
    ///
    /// - [addr]: The Stellar address to decode.
    /// - [kwargs]: A map of optional keyword arguments.
    ///   - [addr_type]: The address type, either XlmAddrTypes.pubKey or XlmAddrTypes.privKey.
    ///
    /// Throws an [ArgumentException] if the address type is not valid or if there's a validation error.
    ///
    /// Example usage:
    /// ```dart
    /// final decoder = XlmAddrDecoder();
    /// final addr = 'GC2Z66U3A3I5VGM3S5INUT4FVC3VGCUJ7ALDCTF6WLYBMXNO5KNOHWZL';
    /// final publicKey = decoder.decodeAddr(addr, {'addr_type': XlmAddrTypes.pubKey});
    /// ```
    final addrType = kwargs['addr_type'] ?? XlmAddrTypes.pubKey;
    if (addrType is! XlmAddrTypes) {
      throw const AddressConverterException(
          'Address type is not an enumerative of XlmAddrTypes');
    }

    final addrDecBytes = Base32Decoder.decode(addr);

    AddrDecUtils.validateBytesLength(
        addrDecBytes,
        Ed25519KeysConst.pubKeyByteLen +
            Ed25519KeysConst.pubKeyPrefix.length +
            XlmAddrConst.checksumByteLen);

    final payloadBytes = AddrDecUtils.splitPartsByChecksum(
            addrDecBytes, XlmAddrConst.checksumByteLen)
        .item1;

    final addrTypeGot = payloadBytes[0];
    if (addrType.value != addrTypeGot) {
      throw AddressConverterException(
          'Invalid address type (expected ${addrType.value}, got $addrTypeGot)');
    }

    AddrDecUtils.validateChecksum(
        payloadBytes,
        addrDecBytes
            .sublist(addrDecBytes.length - XlmAddrConst.checksumByteLen),
        _XlmAddrUtils.computeChecksum);
    final pubKeyBytes = payloadBytes.sublist(1);
    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Stellar (XLM) blockchain addresses.
class XlmAddrEncoder implements BlockchainAddressEncoder {
  /// Encode a Stellar (XLM) public key as a Stellar address.
  ///
  /// This method encodes a Stellar public key as a Stellar address, which can be used for transactions.
  ///
  /// - [pubKey]: The Stellar public key to encode.
  /// - [kwargs]: A map of optional keyword arguments.
  ///   - [addr_type]: The address type, either XlmAddrTypes.pubKey or XlmAddrTypes.privKey.
  ///
  /// Throws an [ArgumentException] if the address type is not valid or if there's a validation error.
  ///
  /// Example usage:
  /// ```dart
  /// final encoder = XlmAddrEncoder();
  /// final publicKey = List<int>.from([6, ...bytes]); // Replace 'bytes' with the actual public key bytes.
  /// final addr = encoder.encodeKey(publicKey, {'addr_type': XlmAddrTypes.pubKey});
  /// ```
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final addrType = kwargs['addr_type'] ?? XlmAddrTypes.pubKey;
    if (addrType is! XlmAddrTypes) {
      throw const AddressConverterException(
          'Address type is not an enumerative of XlmAddrTypes');
    }

    IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    List<int> payloadBytes =
        List<int>.from([addrType.value, ...pubKeyObj.compressed.sublist(1)]);

    List<int> checksumBytes = _XlmAddrUtils.computeChecksum(payloadBytes);
    return Base32Encoder.encodeNoPaddingBytes(
        List<int>.from([...payloadBytes, ...checksumBytes]));
  }
}

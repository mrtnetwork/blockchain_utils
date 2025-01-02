import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Implementation of the [BlockchainAddressDecoder] for Near Protocol addresses.
class NearAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a Near Protocol address.
  ///
  /// This method decodes a Near Protocol address from the provided input string, which is expected
  /// to be a hexadecimal representation of the public key bytes. It validates the length of the input,
  /// ensuring it matches the expected compressed Ed25519 public key length. The decoded public key bytes
  /// are returned as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The hexadecimal representation of the public key bytes for the Near Protocol address.
  ///   - kwargs: Optional keyword arguments (not used in this implementation).
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded public key bytes for the Near Protocol address.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Convert the hexadecimal input to bytes.
    final List<int> pubKeyBytes = BytesUtils.fromHexString(addr);

    /// Validate the length of the public key bytes.
    AddrDecUtils.validateBytesLength(
        pubKeyBytes, Ed25519KeysConst.pubKeyByteLen);

    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Near Protocol addresses.
class NearAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Near Protocol address.
  ///
  /// This method encodes a public key as a Near Protocol address. It expects the public key as a `List<int>`
  /// and returns it as a hexadecimal representation, stripping the '0x' prefix from the result.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a Near Protocol address in the form of a `List<int>`.
  ///   - kwargs: Optional keyword arguments (not used in this implementation).
  ///
  /// Returns:
  ///   A String representing the hexadecimal representation of the provided public key for the Near Protocol address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and get the Ed25519 public key.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Encode the public key as a hexadecimal representation and remove the '0x' prefix.
    return StringUtils.strip0x(BytesUtils.toHexString(pubKeyObj.compressed))
        .substring(2);
  }
}

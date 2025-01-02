import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';

/// Implementation of the [BlockchainAddressDecoder] for Solana (SOL) addresses.
class SolAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a Solana SOL address.
  ///
  /// This method decodes a Solana SOL address from the given Base58-encoded input string.
  /// It expects an optional map of keyword arguments. It decodes the address, validates
  /// its byte length, and returns the decoded address as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The Base58-encoded Solana SOL address to be decoded.
  ///   - kwargs: Optional keyword arguments for customization (not used in this implementation).
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded Solana SOL address bytes.
  ///
  /// Throws:
  ///   - FormatException if the decoded address has an incorrect byte length.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Decode the Solana SOL address from Base58.
    final addrDecBytes = Base58Decoder.decode(addr);

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, Ed25519KeysConst.pubKeyByteLen);

    /// Return the decoded address as a `List<int>`.
    return List<int>.from(addrDecBytes);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Solana (SOL) addresses.
class SolAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Solana SOL address.
  ///
  /// This method takes a public key as a `List<int>` and an optional map of keyword
  /// arguments, although they are not used in this implementation. It validates
  /// and processes the public key as an Ed25519 key, then encodes it into a Solana
  /// SOL address using Base58 encoding. The resulting address is returned as a String.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a Solana SOL address.
  ///   - kwargs: Optional keyword arguments (not used in this implementation).
  ///
  /// Returns:
  ///   A String representing the Solana SOL address encoded from the provided public key
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and process the public key as an Ed25519 key.
    final pub = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Encode the processed public key as a Solana SOL address using Base58.
    final encodedKey = Base58Encoder.encode(pub.compressed.sublist(1));

    /// Return the encoded Solana SOL address as a String.
    return encodedKey;
  }
}

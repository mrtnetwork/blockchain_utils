import 'package:blockchain_utils/base32/base32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'encoder.dart';

/// A class that defines constants for Nano (NANO) addresses.
class NanoAddrConst {
  /// The custom Base32 alphabet used for Nano addresses.
  static const String base32Alphabet = "13456789abcdefghijkmnopqrstuwxyz";

  /// The list of padding bytes in decimal format used for Nano address payloads.
  static const List<int> payloadPadDec = [0, 0, 0];

  /// The string representation of padding bytes used for Nano address payloads in Base32 encoding
  static const String payloadPadEnc = "1111";
}

/// A utility class for Nano (NANO) address-related operations.
class _NanoAddrUtils {
  /// Computes the checksum for a Nano address based on the provided public key bytes.
  ///
  /// This method computes the checksum for a Nano address by taking the reversed Blake2b-40 hash
  /// of the provided public key bytes. The result is returned as a `List<int>`.
  ///
  /// Parameters:
  ///   - pubKeyBytes: The public key bytes used to compute the checksum.
  ///
  /// Returns:
  ///   A `List<int>` containing the computed checksum for the Nano address.
  static List<int> computeChecksum(List<int> pubKeyBytes) {
    return QuickCrypto.blake2b40Hash(pubKeyBytes).reversed.toList();
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Nano addresses.
class NanoAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a Nano (NANO) address.
  ///
  /// This method decodes a Nano address from the provided input string. It expects an optional map of
  /// keyword arguments for custom Nano address parameters. The method performs the following steps:
  /// 1. Validates and removes the Nano address prefix.
  /// 2. Decodes the Base32-encoded payload, considering the custom Nano Base32 alphabet and padding.
  /// 3. Validates the length of the decoded address.
  /// 4. Splits the decoded address into its public key and checksum parts.
  /// 5. Validates the address checksum.
  ///
  /// Parameters:
  ///   - addr: The Nano address to be decoded as a string.
  ///   - kwargs: Optional keyword arguments for custom Nano address parameters.
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded public key bytes for the Nano address.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and remove the Nano address prefix.
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
        addr, CoinsConf.nano.params.addrPrefix!);

    /// Decode the Base32-encoded payload using the custom Nano Base32 alphabet and padding.
    final addrDecBytes = Base32Decoder.decode(
      NanoAddrConst.payloadPadEnc + addrNoPrefix,
      NanoAddrConst.base32Alphabet,
    );

    /// Validate the length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      Ed25519KeysConst.pubKeyByteLen +
          QuickCrypto.blake2b40DigestSize +
          NanoAddrConst.payloadPadDec.length,
    );

    /// Split the decoded address into its public key and checksum parts.
    final decode = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes.sublist(NanoAddrConst.payloadPadDec.length),
      QuickCrypto.blake2b40DigestSize,
    );

    /// Retrieve the public key bytes and checksum bytes.
    final pubKeyBytes = decode.item1;
    final checksumBytes = decode.item2;

    /// Validate the address checksum using the computed checksum function.
    AddrDecUtils.validateChecksum(
      pubKeyBytes,
      checksumBytes,
      _NanoAddrUtils.computeChecksum,
    );

    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Nano addresses.
class NanoAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a Nano address.
  ///
  /// This method encodes a public key as a Nano address. It expects the public key as a `List<int>`
  /// and returns the Nano address as a string. The encoding process involves:
  /// 1. Validating and obtaining the Ed25519 Blake2b public key.
  /// 2. Calculating the Nano address payload by appending padding, public key bytes, and checksum.
  /// 3. Encoding the payload using a custom Nano Base32 alphabet.
  /// 4. Prepending the Nano address prefix.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a Nano address in the form of a `List<int>`.
  ///   - kwargs: Optional keyword arguments (not used in this implementation).
  ///
  /// Returns:
  ///   A string representing the Nano address corresponding to the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and obtain the Ed25519 Blake2b public key.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Blake2bKey(pubKey);

    /// Extract public key bytes and calculate the checksum.
    final pubKeyBytes = pubKeyObj.compressed.sublist(1);
    final checksumBytes = _NanoAddrUtils.computeChecksum(pubKeyBytes);

    /// Create the Nano address payload by combining padding, public key, and checksum.
    final payloadBytes = List<int>.from(
      [...NanoAddrConst.payloadPadDec, ...pubKeyBytes, ...checksumBytes],
    );

    /// Encode the payload using a custom Nano Base32 alphabet and prepend the Nano address prefix.
    final b32Enc = Base32Encoder.encodeNoPaddingBytes(
      payloadBytes,
      NanoAddrConst.base32Alphabet,
    );
    return CoinsConf.nano.params.addrPrefix! +
        b32Enc.substring(NanoAddrConst.payloadPadEnc.length);
  }
}
